"""Fixtures to calculate metrics."""
from os import PathLike
from typing import Dict

import matplotlib.pyplot as plt
import numpy as np
import pytest
import scipy
from pytest_harvest.results_bags import ResultsBag
from scipy import ndimage
from sklearn import metrics as sk_metrics

from ..fixtures.benchmarking_input import InputABC

__all__ = ["metrics"]

import warnings
from collections import OrderedDict

from scipy import ndimage


@pytest.fixture(scope="function")
def metrics(
    input_reference: InputABC,
    input_app: InputABC,
    visualization_dir: PathLike,
    results_bag: ResultsBag,
) -> Dict[str, float]:
    """Calculate metrics and save them in results_bag.

    Args:
        input_reference: [pytest.fixture] Reference kicks.
        input_app: [pytest.fixture] App kicks.
        visualization_dir: [pytest.fixture] Stored visualizations.
        results_bag: [pytest_harvest.fixture] Bag to store information across tests.

    Returns:
        Dict containing metrics.
    """

    ref_kicks = input_reference.kicks  # true, label
    app_kicks = input_app.kicks  # predicted

    ref_kicks = ref_kicks.to_numpy()
    app_kicks = app_kicks.to_numpy()

    # this for the case when there are neither ground truth nor predicted kicks
    if (np.sum(ref_kicks) == 0) and (np.sum(app_kicks) == 0):
        results_bag.precision = 1
        results_bag.recall = 1
        results_bag.f1_score = 1
        results_bag.visualization_dir = visualization_dir

        return {"precision": 1, "recall": 1, "f1_score": 1}

    # this for the case when there are ground truth kicks but no predictions
    elif (np.sum(ref_kicks) == 0) and (np.sum(app_kicks) != 0):
        results_bag.precision = 0
        results_bag.recall = 0
        results_bag.f1_score = 0
        results_bag.visualization_dir = visualization_dir
        return {"precision": 0, "recall": 0, "f1_score": 0}

    # this for the case when there are predicted kicks but no ground thruths
    elif (np.sum(ref_kicks) != 0) and (np.sum(app_kicks) == 0):
        results_bag.precision = 0
        results_bag.recall = 0
        results_bag.f1_score = 0
        results_bag.visualization_dir = visualization_dir
        return {"precision": 0, "recall": 0, "f1_score": 0}

    if input_app.name == "Matlab-Algo":
        # The parameter is calculated from three videos, only for matlab algo
        delay_frame_count = 21
        app_kicks = app_kicks[delay_frame_count:]
        ref_kicks = ref_kicks[:-delay_frame_count]

    # adapted iou threshold
    iou_threshold = 0.1
    label_kick_filled_dilated = scipy.ndimage.binary_dilation(
        ref_kicks.reshape(-1), structure=np.ones(8)
    )
    label_kick_filled_erosed = scipy.ndimage.binary_erosion(
        label_kick_filled_dilated, structure=np.ones(8)
    ).astype(int)

    # label kick_start kick_stop indices
    labels, group_index = scipy.ndimage.label(label_kick_filled_erosed)
    labels_i, labels_j, labels_i_count = np.unique(
        labels, return_index=True, return_counts=True
    )
    label_kick_start, label_kick_stop = (
        labels_j[1:],
        labels_j[1:] + labels_i_count[1:] - 1,
    )

    # prediction kick_start kick_stop indices
    labels, group_index = scipy.ndimage.label(app_kicks)
    labels_i, labels_j, labels_i_count = np.unique(
        labels, return_index=True, return_counts=True
    )
    pred_kick_start, pred_kick_stop = (
        labels_j[1:],
        labels_j[1:] + labels_i_count[1:] - 1,
    )

    ground_truth = np.array([label_kick_start, label_kick_stop]).T
    predicted = np.array([pred_kick_start, pred_kick_stop]).T

    # calculate Intersection over Union (IOU)
    area1 = ground_truth[:, 1] - ground_truth[:, 0]
    area2 = predicted[:, 1] - predicted[:, 0]
    lt = np.maximum(ground_truth[:, None, 0], predicted[:, 0])
    rb = np.minimum(ground_truth[:, None, 1], predicted[:, 1])
    inter = (rb - lt).clip(min=0)
    union = area1[:, None] + area2 - inter
    iou = inter / union

    # this for the case when there are ground truth and predicted kicks, both no overlapings.
    if (iou.shape[0] == 0) or (iou.shape[1] == 0):
        results_bag.precision = 0
        results_bag.recall = 0
        results_bag.f1_score = 0
        results_bag.visualization_dir = visualization_dir
        return {"precision": 0, "recall": 0, "f1_score": 0}

    ground_truth_index, pred_index = np.where(iou > iou_threshold)

    # the edge cases are not considered yet (1 label for 2 preds, 2 labels for 1 pred)
    tp = ground_truth_index.shape[0]
    fp = np.sum(iou.max(axis=0) <= iou_threshold)
    fn = np.sum(iou.max(axis=1) <= iou_threshold)

    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else (np.sum(ref_kicks) == 0) if 0 else 0
    f1_score = (
        (2 * precision * recall) / (precision + recall)
        if (precision + recall) > 0
        else 0
    )

    results_bag.precision = precision
    results_bag.recall = recall
    results_bag.f1_score = f1_score

    results_bag.visualization_dir = visualization_dir
    return {"precision": precision, "recall": recall, "f1_score": f1_score}


def frame_event_metrics(app_kicks, ref_kicks):
    """
    app_kicks: algorithm preditions
    ref_kicks: ground truth labels
    """

    if not isinstance(app_kicks, np.ndarray):
        raise TypeError(f"expected app_kicks to be np array, but got {type(app_kicks)}")

    if not isinstance(app_kicks, np.ndarray):
        raise TypeError(f"expected ref_kicks to be np array, but got {type(ref_kicks)}")

    if app_kicks.ndim != 1:
        raise ValueError(
            f"expected app_kicks to be one dimensional vector, but got shape {app_kicks.shape}"
        )

    if ref_kicks.ndim != 1:
        raise ValueError(
            f"expected ref_kicks to be one dimensional vector, but got shape {ref_kicks.shape}"
        )

    result = {"frame/segment": None, "event": None}

    if app_kicks.shape != ref_kicks.shape:
        raise ValueError(
            f"expected both array to have the same shape, but got {app_kicks.shape} and {ref_kicks.shape}"
        )

    app_kicks = app_kicks.astype(int)
    ref_kicks = ref_kicks.astype(int)

    # take out 0s in the middle of the kick labels
    correcting_size = 8
    structure = np.ones(correcting_size)
    label_kick_filled_dilated = scipy.ndimage.binary_dilation(
        ref_kicks, structure=structure
    )

    # after taking out redundant zeros, at the end and at the beginning of the kick there are extra ones
    # so it is necessary to kick them out
    label_kick_filled_erosed = scipy.ndimage.binary_erosion(
        label_kick_filled_dilated, structure=structure
    ).astype(int)
    # classify each frame
    ref_kicks = label_kick_filled_erosed

    tp = (ref_kicks == 1) & (app_kicks == 1)
    tn = (ref_kicks == 0) & (app_kicks == 0)
    fp = (ref_kicks == 0) & (app_kicks == 1)
    fn = (ref_kicks == 1) & (app_kicks == 0)

    accuracy = (tp.sum() + tn.sum()) / (tp.sum() + tn.sum() + fp.sum() + fn.sum())
    tpr = tp.sum() / (tp.sum() + fn.sum())
    fpr = fp.sum() / (fp.sum() + tn.sum())

    # Segments

    # get TP segment starts and stops
    labels, group_num = scipy.ndimage.label(tp)
    labels_i, labels_j, labels_i_count = np.unique(
        labels, return_index=True, return_counts=True
    )
    tp_segment_start, tp_segment_stop = (
        labels_j[1:],
        labels_j[1:] + labels_i_count[1:] - 1,
    )

    # get TN segment starts and stops
    labels, group_num = scipy.ndimage.label(tn)
    labels_i, labels_j, labels_i_count = np.unique(
        labels, return_index=True, return_counts=True
    )
    tn_segment_start, tn_segment_stop = (
        labels_j[1:],
        labels_j[1:] + labels_i_count[1:] - 1,
    )

    # get FP segment starts and stops
    labels, group_num = scipy.ndimage.label(fp)
    labels_i, labels_j, labels_i_count = np.unique(
        labels, return_index=True, return_counts=True
    )
    fp_segment_start, fp_segment_stop = (
        labels_j[1:],
        labels_j[1:] + labels_i_count[1:] - 1,
    )

    # get FN segment starts and stops
    labels, group_num = scipy.ndimage.label(fn)
    labels_i, labels_j, labels_i_count = np.unique(
        labels, return_index=True, return_counts=True
    )
    fn_segment_start, fn_segment_stop = (
        labels_j[1:],
        labels_j[1:] + labels_i_count[1:] - 1,
    )

    # sort and merge all starts and all stops together
    segment_starts = np.sort(
        np.concatenate(
            (tp_segment_start, tn_segment_start, fp_segment_start, fn_segment_start)
        )
    )

    segment_stops = np.sort(
        np.concatenate(
            (tp_segment_stop, tn_segment_stop, fp_segment_stop, fn_segment_stop)
        )
    )

    # get index mask for all four classes
    tp_segment_index = (app_kicks[segment_starts] == 1) & (
        ref_kicks[segment_starts] == 1
    )
    tn_segment_index = (app_kicks[segment_starts] == 0) & (
        ref_kicks[segment_starts] == 0
    )
    fp_segment_index = (app_kicks[segment_starts] == 1) & (
        ref_kicks[segment_starts] == 0
    )
    fn_segment_index = (app_kicks[segment_starts] == 0) & (
        ref_kicks[segment_starts] == 1
    )

    # check for empty ground truth and prediction case
    if not np.any(
        tp_segment_index | tn_segment_index | fp_segment_index | fn_segment_index
    ):
        warnings.warn("Warning:for empty app_kicks and ref_kicks are undefined")
        return None

    # FP subcases
    # calculate insertions
    insertion_index = fp_segment_index[1:-1] & (
        (tn_segment_index[:-2] | fn_segment_index[:-2])
        & (tn_segment_index[2:] | fn_segment_index[2:])
    )
    insertion_index = np.append(
        (fp_segment_index[0] & (tn_segment_index[1] | fn_segment_index[1])),
        insertion_index,
    )
    insertion_index = np.append(
        insertion_index,
        (fp_segment_index[-1] & (tn_segment_index[-2] | fn_segment_index[-2])),
    )

    # calculate merges
    merge_index = fp_segment_index[1:-1] & tp_segment_index[:-2] & tp_segment_index[2:]
    merge_index = np.append(False, merge_index)
    merge_index = np.append(merge_index, False)

    # calculate overfill alpha
    overfill_begin_index = (
        fp_segment_index[1:-1]
        & (tn_segment_index[:-2] | fn_segment_index[:-2])
        & tp_segment_index[2:]
    )
    overfill_begin_index = np.append(
        (fp_segment_index[0] & tp_segment_index[1]), overfill_begin_index
    )
    overfill_begin_index = np.append(overfill_begin_index, False)

    # calculate overfill omega
    overfill_end_index = (
        fp_segment_index[1:-1]
        & tp_segment_index[:-2]
        & (tn_segment_index[2:] | fn_segment_index[2:])
    )
    overfill_end_index = np.append(False, overfill_end_index)
    overfill_end_index = np.append(
        overfill_end_index, (fp_segment_index[-1] & tp_segment_index[-2])
    )

    # FN subcases
    # calculate deletions
    deletion_index = fn_segment_index[1:-1] & (
        (tn_segment_index[:-2] | fp_segment_index[:-2])
        & (tn_segment_index[2:] | fp_segment_index[2:])
    )
    deletion_index = np.append(
        (fn_segment_index[0] & (tn_segment_index[1] | fp_segment_index[1])),
        deletion_index,
    )
    deletion_index = np.append(
        deletion_index,
        (fn_segment_index[-1] & (tn_segment_index[-2] | fp_segment_index[-2])),
    )

    # calculate fragmentings
    fragmenting_index = (
        fn_segment_index[1:-1] & tp_segment_index[:-2] & tp_segment_index[2:]
    )
    fragmenting_index = np.append(False, fragmenting_index)
    fragmenting_index = np.append(fragmenting_index, False)

    # calculate underfill alpha
    underfill_begin_index = (
        fn_segment_index[1:-1]
        & (tn_segment_index[:-2] | fp_segment_index[:-2])
        & tp_segment_index[2:]
    )
    underfill_begin_index = np.append(
        (fn_segment_index[0] & tp_segment_index[1]), underfill_begin_index
    )
    underfill_begin_index = np.append(underfill_begin_index, False)

    # calculate underfill omega
    underfill_end_index = (
        fn_segment_index[1:-1]
        & tp_segment_index[:-2]
        & (tn_segment_index[2:] | fp_segment_index[2:])
    )
    underfill_end_index = np.append(False, underfill_end_index)
    underfill_end_index = np.append(
        underfill_end_index, (fn_segment_index[-1] & tp_segment_index[-2])
    )

    # get frame counts for each class an subclass
    tp_frame_count = tp.sum()
    tn_frame_count = tn.sum()

    # FP
    insertion_frame_count = (
        segment_stops[insertion_index] - segment_starts[insertion_index] + 1
    ).sum()
    merge_frame_count = (
        segment_stops[merge_index] - segment_starts[merge_index] + 1
    ).sum()
    overfill_begin_frame_count = (
        segment_stops[overfill_begin_index] - segment_starts[overfill_begin_index] + 1
    ).sum()
    overfill_end_frame_count = (
        segment_stops[overfill_end_index] - segment_starts[overfill_end_index] + 1
    ).sum()

    # FN
    deletion_frame_count = (
        segment_stops[deletion_index] - segment_starts[deletion_index] + 1
    ).sum()
    fragmenting_frame_count = (
        segment_stops[fragmenting_index] - segment_starts[fragmenting_index] + 1
    ).sum()
    underfill_begin_frame_count = (
        segment_stops[underfill_begin_index] - segment_starts[underfill_begin_index] + 1
    ).sum()
    underfill_end_frame_count = (
        segment_stops[underfill_end_index] - segment_starts[underfill_end_index] + 1
    ).sum()

    # sum up negatives and positives serparately
    negatives_count = (
        insertion_frame_count
        + merge_frame_count
        + overfill_begin_frame_count
        + overfill_end_frame_count
        + tn_frame_count
    )

    positives_count = (
        deletion_frame_count
        + fragmenting_frame_count
        + underfill_begin_frame_count
        + underfill_end_frame_count
        + tp_frame_count
    )

    # calculate dr fr u_alpha u_omega
    dr = deletion_frame_count / positives_count
    fr = fragmenting_frame_count / positives_count
    u_alpha = underfill_begin_frame_count / positives_count
    u_omega = underfill_end_frame_count / positives_count

    # calculate ir mr o_alpha o_omega
    ir = insertion_frame_count / negatives_count
    mr = merge_frame_count / negatives_count
    o_alpha = overfill_begin_frame_count / negatives_count
    o_omega = overfill_end_frame_count / negatives_count

    # calculate fpr
    fpr = ir + mr + o_alpha + o_omega
    tpr = 1 - (dr + fr + u_alpha + u_omega)

    positive_dict = OrderedDict(
        {
            "P": positives_count,
            "TPR": tpr,
            "D": dr,
            "F": fr,
            "U_alpha": u_alpha,
            "U_omega": u_omega,
        }
    )
    negative_dict = OrderedDict(
        {
            "N": negatives_count,
            "TNR": (1 - fpr),
            "I": ir,
            "M": mr,
            "O_alpha": o_alpha,
            "O_omega": o_omega,
        }
    )

    result["frame/segment"] = {"P": positive_dict, "N": negative_dict}

    result["Conf"] = {
        "FN": {
            "D": deletion_frame_count,
            "F": fragmenting_frame_count,
            "U_alpha": underfill_begin_frame_count,
            "U_omega": underfill_end_frame_count,
        },
        "FP": {
            "I": insertion_frame_count,
            "M": merge_frame_count,
            "O_alpha": overfill_begin_frame_count,
            "O_omega": overfill_end_frame_count,
        },
        "True": {"TP": tp_frame_count, "TN": tn_frame_count},
    }

    # Events

    # get ground truth event starts and stops
    labels, group_num_ground_truth = scipy.ndimage.label(ref_kicks)
    labels_i, labels_j, labels_i_count_ground_truth = np.unique(
        labels, return_index=True, return_counts=True
    )
    ground_truth_event_starts, ground_truth_event_stops = (
        labels_j[1:],
        labels_j[1:] + labels_i_count_ground_truth[1:] - 1,
    )

    # get prediction event starts and stops
    labels, group_num_pred = scipy.ndimage.label(app_kicks)
    labels_i, labels_j, labels_i_count_pred = np.unique(
        labels, return_index=True, return_counts=True
    )
    pred_event_starts, pred_event_stops = (
        labels_j[1:],
        labels_j[1:] + labels_i_count_pred[1:] - 1,
    )

    # initialize empty arrays where will be kepts class values for ground truth and prediction
    ground_truth_event_class = np.zeros_like(ground_truth_event_starts, dtype=np.int16)
    pred_event_class = np.zeros_like(pred_event_starts, dtype=np.int16)

    # define variables for assignin classes (in binary format for convenience)
    correct = 0b00000000
    # D
    deletion = 0b00000001
    # I'
    insertion_ = 0b00000010
    # F
    fragmenting = 0b00000100
    # F'
    fragmenting_ = 0b00001000
    # M'
    merge_ = 0b00100000
    # M
    merge = 0b01000000

    tmp1 = (segment_starts[..., None] >= ground_truth_event_starts) & (
        segment_stops[..., None] <= ground_truth_event_stops
    )
    tmp2 = (segment_starts[..., None] >= pred_event_starts) & (
        segment_stops[..., None] <= pred_event_stops
    )

    # for each event in ground truth and prediction get those segments from which it consist of
    ground_truth_segment_index, ground_truth_event_index = np.where(tmp1)
    pred_segment_index, pred_event_index = np.where(tmp2)

    # assign deletions
    ground_truth_event_class[
        ground_truth_event_index[deletion_index[ground_truth_segment_index]]
    ] += deletion

    # assign fragmenting
    ground_truth_event_class[
        ground_truth_event_index[fragmenting_index[ground_truth_segment_index]]
    ] += fragmenting

    # assign insertions
    pred_event_class[
        pred_event_index[insertion_index[pred_segment_index]]
    ] += insertion_

    # assign merges_
    pred_event_class[pred_event_index[merge_index[pred_segment_index]]] += merge_

    # from merge_ get merge
    _, idx = np.where(
        ((np.where(merge_index)[0] + 1)[..., None] == ground_truth_segment_index)
    )
    ground_truth_event_class[ground_truth_event_index[idx]] += merge
    _, idx = np.where(
        ((np.where(merge_index)[0] - 1)[..., None] == ground_truth_segment_index)
    )
    ground_truth_event_class[ground_truth_event_index[idx]] += merge
    # correct those events which are assigned as merge twise (frome left and right neighbouring segments)
    ground_truth_event_class[ground_truth_event_class == 2 * merge] = merge
    ground_truth_event_class[ground_truth_event_class == 2 * merge + fragmenting] = fragmenting + merge

    # from fragmenting to fragmenting_
    _, idx = np.where(
        ((np.where(fragmenting_index)[0] + 1)[..., None] == pred_segment_index)
    )
    pred_event_class[pred_event_index[idx]] += fragmenting_
    _, idx = np.where(
        ((np.where(fragmenting_index)[0] - 1)[..., None] == pred_segment_index)
    )
    pred_event_class[pred_event_index[idx]] += fragmenting_
    # correct those events which are assigned as fragmenting_ twise (frome left and right neighbouring segments)
    pred_event_class[pred_event_class == 2 * fragmenting_] = fragmenting_
    pred_event_class[pred_event_class == 2 * fragmenting_ + merge_] = fragmenting_ + merge_

    # get counts of all types of events

    # actually C_g == C_p
    c_g = (ground_truth_event_class == correct).sum()
    c_p = (pred_event_class == correct).sum()
    d = (ground_truth_event_class == deletion).sum()
    i = (pred_event_class == insertion_).sum()
    f = (ground_truth_event_class == fragmenting).sum()
    f_ = (pred_event_class == fragmenting_).sum()
    m_ = (pred_event_class == merge_).sum()
    m = (ground_truth_event_class == merge).sum()

    fm = (ground_truth_event_class == merge + fragmenting).sum()
    fm_ = (pred_event_class == merge_ + fragmenting_).sum()

    e = group_num_ground_truth
    r = group_num_pred

    result["event"] = {
        "Total_ground_truth": e,
        "D": d,
        "F": f,
        "FM": fm,
        "M": m,
        "C": c_g,
        "Total_predicted": r,
        "M'": m_,
        "FM'": fm_,
        "F'": f_,
        "I'": i,
    }

    return result
