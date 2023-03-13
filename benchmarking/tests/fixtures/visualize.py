"""Fixtures for data visualization."""
from pathlib import Path

import matplotlib
import matplotlib.patches as mpatches
import matplotlib.path as mpath
from matplotlib.ticker import FormatStrFormatter

matplotlib.use("AGG")

import os

import matplotlib.pyplot as plt
import pandas as pd
import pytest
from sklearn import metrics as sk_metrics

from ..fixtures.benchmarking_input import InputABC
from ..utils.cfg import BenchmarkConfig
from .metric import frame_event_metrics

__all__ = ["visualization_file", "visualization_dir"]


import json
import re
import warnings
from collections import OrderedDict

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy
import seaborn as sns
from scipy import ndimage


@pytest.fixture(scope="session", autouse=True)
def visualization_dir() -> Path:
    """Create and return visualization directory.

    Returns:
        Path to visualization directory.
    """
    visualization_dir = Path("artifacts/images")
    visualization_dir.mkdir(parents=True, exist_ok=True)
    return visualization_dir


def pie_conf_plot(parent, app_kicks, ref_kicks, app_name):

    result = frame_event_metrics(app_kicks, ref_kicks)

    if result is None:
        return

    new_confusion_matrix = np.zeros((2, 2))

    new_confusion_matrix[0, 0] = int(result["Conf"]["True"]["TP"])
    new_confusion_matrix[1, 1] = int(result["Conf"]["True"]["TN"])

    fig, ax = plt.subplots()

    ax.matshow(new_confusion_matrix, cmap=plt.cm.Blues, alpha=0.3)
    ax.set_xticklabels(["", "Kick", "No kick"])
    ax.set_yticklabels(["", "Kick", "No kick"], rotation=90)
    ax.xaxis.set_ticks_position("none")
    ax.yaxis.set_ticks_position("none")

    for i in range(new_confusion_matrix.shape[0]):
        for j in range(new_confusion_matrix.shape[1]):

            if i == 0 and j == 1:
                fn_names = list(result["Conf"]["FN"].keys())
                fn_list = list(result["Conf"]["FN"].values())
                fn_text = "\n"
                for k in range(len(fn_names)):
                    if fn_names[k] == "U_alpha":
                        fn_text += r"$ U_\alpha $" + ":" + str(fn_list[k]) + "\n"
                    elif fn_names[k] == "U_omega":
                        fn_text += r"$ U_\omega $" + ":" + str(fn_list[k]) + "\n"
                    else:
                        fn_text += str(fn_names[k]) + ":" + str(fn_list[k]) + "\n"
                ax.text(x=j, y=i, s=fn_text, va="center", ha="center", size="xx-large")

            elif i == 1 and j == 0:
                fp_names = list(result["Conf"]["FP"].keys())
                fp_list = list(result["Conf"]["FP"].values())
                fp_text = "\n"
                for k in range(len(fp_names)):
                    if fp_names[k] == "O_alpha":
                        fp_text += r"$ O_\alpha $" + ":" + str(fp_list[k]) + "\n"

                    elif fp_names[k] == "O_omega":
                        fp_text += r"$ O_\omega $" + ":" + str(fp_list[k]) + "\n"
                    else:
                        fp_text += str(fp_names[k]) + ":" + str(fp_list[k]) + "\n"
                ax.text(x=j, y=i, s=fp_text, va="center", ha="center", size="xx-large")

            else:
                ax.text(
                    x=j,
                    y=i,
                    s=int(new_confusion_matrix[i, j]),
                    va="center",
                    ha="center",
                    size="xx-large",
                )

    plt.xlabel(app_name, fontsize=12)
    plt.ylabel("Ground Truth", fontsize=12)
    plt.tight_layout()
    fig.savefig(parent / "2ModifiedConfusionMatrix.jpg", dpi=200)
    plt.cla()
    plt.close(fig)

    fig = plt.figure(figsize=(13, 13), dpi=200)

    ax1 = plt.subplot2grid((2, 2), (0, 0))
    data_P = [100 * val for val in list(result["frame/segment"]["P"].values())[1:]]

    if np.all(np.isnan(data_P)):
        return

    labels_P = list(result["frame/segment"]["P"].keys())[1:]
    labels_P = list(
        map(
            lambda x: re.sub(
                r"(.*)_(alpha)", " $\\1_{α}$", re.sub(r"(.*)_(omega)", " $\\1_{ω}$", x)
            ),
            labels_P,
        )
    )
    colors_P = sns.color_palette("deep")[0:5]

    patches, texts = plt.pie(
        data_P
    )  # , labels = labels_P, colors = colors_P, autopct='%.0f%%', textprops={'fontsize': 6})
    plt.title("Positives", fontsize=18, fontweight="bold")
    plt.legend(
        patches,
        labels=[f"{x} {round(y)}%" for x, y in zip(labels_P, data_P)],
        loc="upper left",
        bbox_to_anchor=(1, 0, 0.5, 1),
        prop={"size": 12},
    )

    ax1 = plt.subplot2grid((2, 2), (0, 1))
    data_N = [100 * val for val in list(result["frame/segment"]["N"].values())[1:]]
    labels_N = list(result["frame/segment"]["N"].keys())[1:]
    labels_N = list(
        map(
            lambda x: re.sub(
                r"(.*)_(alpha)", " $\\1_{α}$", re.sub(r"(.*)_(omega)", " $\\1_{ω}$", x)
            ),
            labels_N,
        )
    )
    colors_N = sns.color_palette("deep")[0:5]

    patches, texts = plt.pie(
        data_N
    )  # , labels = labels_N, colors = colors_N, autopct='%.0f%%', textprops={'fontsize': 6})
    plt.title("Negatives", fontsize=18, fontweight="bold")
    plt.legend(
        patches,
        labels=[f"{x} {round(y)}%" for x, y in zip(labels_N, data_N)],
        loc="upper right",
        bbox_to_anchor=(1, 0, 0.5, 1),
        prop={"size": 12},
    )

    fig.savefig(parent / "3frame_pie_charts.jpg", dpi=400, bbox_inches="tight")

    table_text = np.array(list(result["event"].keys())[1:6])
    table_text = np.concatenate(
        (table_text, np.array(list(result["event"].keys())[7:]))
    )
    table = np.array(list(result["event"].values())[1:6])
    table = np.concatenate((table, np.array(list(result["event"].values())[7:])))
    table = table.reshape((1, 9))

    fig, ax = plt.subplots(figsize=(7.5, 7.5))

    ax.matshow(table, cmap=plt.cm.Blues, alpha=0.3)

    table = table.reshape((9, 1))
    ax.set_xlabel(48 * "-" + "Actual   " + "Predicted" + 44 * "-" + "\n")
    label = np.array([""])
    label = np.concatenate((label, table_text))
    ax.set_yticklabels("")
    ax.yaxis.set_ticks_position("none")
    ax.set_xticklabels(label, verticalalignment="bottom")

    for i in range(len(table)):
        text = str(table_text[i]) + str(table[i])
        if i <= 4:
            ax.text(
                x=i, y=0, s=str(table[i][0]), va="center", ha="center", size="xx-large"
            )
        else:
            ax.text(
                x=i, y=0, s=str(table[i][0]), va="center", ha="center", size="xx-large"
            )
    fig.tight_layout()
    fig.savefig(parent / "4EAD.jpg", dpi=200, bbox_inches="tight")


def ead_plot(parent, app_kicks, ref_kicks):

    result = frame_event_metrics(app_kicks, ref_kicks)

    if result is None:
        return

    table_text = np.array(list(result["event"].keys())[1:6])
    table_text = np.concatenate(
        (table_text, np.array(list(result["event"].keys())[7:]))
    )
    table = np.array(list(result["event"].values())[1:6])
    table = np.concatenate((table, np.array(list(result["event"].values())[7:])))

    total_ground_truth = result["event"]["Total_ground_truth"]
    total_predicted = result["event"]["Total_predicted"]

    fig, ax = plt.subplots(figsize=(20, 4))

    horizontal_size = 100
    horizontal_plot_begin = 4
    horizontal_plot_end = 96

    vertical_size = 80
    vertical_plot_begin = 25
    vertical_plot_end = 60

    font_size = 26

    ax.set_xlim([0, horizontal_size])
    ax.set_ylim([0, vertical_size])

    ax.xaxis.set_visible(False)
    ax.yaxis.set_visible(False)

    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_visible(False)
    ax.spines["bottom"].set_visible(False)

    ax.spines["bottom"].set_linewidth(2)
    ax.spines["left"].set_linewidth(2)
    ax.spines["top"].set_linewidth(2)
    ax.spines["right"].set_linewidth(2)

    ax.axhline(
        y=vertical_plot_begin,
        xmin=horizontal_plot_begin / horizontal_size,
        xmax=horizontal_plot_end / horizontal_size,
        color="black",
        ls="--",
    )

    ax.axhline(
        y=vertical_plot_end,
        xmin=horizontal_plot_begin / horizontal_size,
        xmax=horizontal_plot_end / horizontal_size,
        color="black",
        ls="--",
    )

    ax.axvline(
        x=horizontal_plot_end,
        ymin=vertical_plot_begin / vertical_size,
        ymax=vertical_plot_end / vertical_size,
        color="black",
        ls="--",
    )

    u = np.append(0, np.cumsum(table))

    event_count = total_ground_truth + total_predicted - result["event"]["C"]
    event_count_anjsuted = event_count

    u_adjusted = u.copy()
    table_adjusted = table.copy()

    if (table_adjusted.max() / table_adjusted[table_adjusted != 0].min()) > 20:
        table_adjusted[np.where(table_adjusted == table_adjusted.max())] = (
            table_adjusted[
                np.where(
                    table_adjusted[table_adjusted != table_adjusted.max()].max()
                    == table_adjusted
                )
            ]
            + 1
        )
        event_count_anjsuted = table_adjusted.sum()
        u_adjusted = np.append(0, np.cumsum(table_adjusted))

    colors = [
        "floralwhite",
        "darkkhaki",
        "palegoldenrod",
        "wheat",
        "limegreen",
        "powderblue",
        "lightskyblue",
        "cadetblue",
        "lightcoral",
    ]

    for j in range(u.shape[0] - 1):

        if table[j] == 0:
            continue

        Path = mpath.Path
        left_border = horizontal_plot_begin + (u_adjusted[j] / event_count_anjsuted) * (
            horizontal_plot_end - horizontal_plot_begin
        )
        right_border = horizontal_plot_begin + (
            u_adjusted[j + 1] / event_count_anjsuted
        ) * (horizontal_plot_end - horizontal_plot_begin)

        pp = mpatches.PathPatch(
            Path(
                [
                    (left_border, vertical_plot_begin),
                    (left_border, vertical_plot_end),
                    (right_border, vertical_plot_end),
                    (right_border, vertical_plot_begin),
                    (right_border, vertical_plot_begin),
                ]
            ),
            color=colors[j],
        )
        ax.add_patch(pp)

        ax.axvline(
            x=left_border,
            ymin=vertical_plot_begin / vertical_size,
            ymax=vertical_plot_end / vertical_size,
            color="black",
            ls="--",
        )

        ax.text(
            (left_border + right_border) / 2,
            (vertical_plot_begin + vertical_plot_end) / 2 + vertical_size / 8,
            table_text[j],
            fontsize=font_size,
            horizontalalignment="center",
            verticalalignment="center",
        )

        ax.text(
            (left_border + right_border) / 2,
            (vertical_plot_begin + vertical_plot_end) / 2 - vertical_size / 8,
            f"{table[j]}",
            fontsize=font_size,
            horizontalalignment="center",
            verticalalignment="center",
        )

        if j <= 4:
            ax.text(
                (left_border + right_border) / 2,
                vertical_plot_end + vertical_size / 16,
                f"{100*table[j]/total_ground_truth:.2f}%",
                fontsize=font_size / 2,
                horizontalalignment="center",
                verticalalignment="center",
                weight="bold",
            )

        if j >= 4:
            ax.text(
                (left_border + right_border) / 2,
                vertical_plot_begin - vertical_size / 16,
                f"{100*table[j]/total_predicted:.2f}%",
                fontsize=font_size / 2,
                horizontalalignment="center",
                verticalalignment="center",
                weight="bold",
            )

    ax.axhline(
        y=vertical_plot_end,
        xmin=horizontal_plot_begin / horizontal_size,
        xmax=(
            horizontal_plot_begin
            + (u_adjusted[5] / event_count_anjsuted)
            * (horizontal_plot_end - horizontal_plot_begin)
        )
        / horizontal_size,
        color="black",
        lw=4,
    )

    ax.axhline(
        y=vertical_plot_begin,
        xmin=(
            horizontal_plot_begin
            + (u_adjusted[4] / event_count_anjsuted)
            * (horizontal_plot_end - horizontal_plot_begin)
        )
        / horizontal_size,
        xmax=(horizontal_plot_end / horizontal_size),
        color="black",
        lw=4,
    )

    ax.text(
        0,
        vertical_size - 10,
        f"Ground truth",
        fontsize=20,
        horizontalalignment="left",
        verticalalignment="center",
        weight="bold",
    )

    ax.text(
        horizontal_size,
        10,
        f"Prediction",
        fontsize=20,
        horizontalalignment="right",
        verticalalignment="center",
        weight="bold",
    )
    
    fig.tight_layout()
    fig.savefig(parent / "5EAD.jpg", dpi=200, bbox_inches="tight")

class Visualization:
    """Wrapper class for visualizing results."""

    def __init__(
        self,
        radar_recording: Path,
        input_reference: InputABC,
        input_app: InputABC,
        config: BenchmarkConfig,
        radar_timestamps: pd.DatetimeIndex,
    ):
        self._radar_recording = radar_recording
        self._input_reference = input_reference
        self._input_app = input_app
        self._config = config
        self._radar_timestamps = radar_timestamps
        self._start_time = self._radar_timestamps[0].value / 10**9
        self._end_time = self._radar_timestamps[-1].value / 10**9 - self._start_time

    def create_visualization(self, visualization_dir: Path) -> Path:
        """Create track (optional) and peeking plots.

        Args:
            visualization_dir: Base folder for visualizations

        Returns:
            Path to the generated image file.
        """
        app_name = self._input_app.name
        ref_name = self._input_reference.name
        
        # plot original
        fig, ax = plt.subplots()
        ax.plot(
            self._input_reference.kicks.index.to_series().apply(
                lambda x: x.value / 10**9 - self._start_time
            ),
            self._input_reference.kicks,
            label=ref_name,
        )
        ax.plot(
            self._input_app.kicks.index.to_series().apply(
                lambda x: x.value / 10**9 - self._start_time
            ),
            self._input_app.kicks,
            label=app_name,
        )

        ax.set_xlabel("Time (s)")
        ax.set_yticks([0, 1], ["No-kick", "Kick"])
        ax.legend()

        destination_folder = visualization_dir / self._radar_recording.relative_to(
            (Path(os.getcwd()).parent / "data").absolute()
        )

        output_file = destination_folder / f"{app_name}_kicks_0.jpg"
        if not destination_folder.exists():
            destination_folder.mkdir(parents=True)
        fig.savefig(output_file, dpi=200)
        plt.cla()
        plt.close(fig)

        destination_folder = visualization_dir / self._radar_recording.relative_to(
            (Path(os.getcwd()).parent / "data").absolute()
        )

        # second plot for the delay, only for matlab algo
        if app_name == "Matlab-Algo":
            delay_frame_count = 21
            fig2, ax2 = plt.subplots()

            x1 = (
                self._input_reference.kicks.iloc[:-delay_frame_count]
                .index.to_series()
                .apply(lambda x: x.value / 10**9 - self._start_time)
            )
            y1 = self._input_reference.kicks.to_numpy()[:-delay_frame_count]
            y2 = self._input_app.kicks.to_numpy()[delay_frame_count:]

            ax2.plot(x1, y1, label=ref_name)
            ax2.plot(x1, y2, label=app_name)

            ax2.set_xlabel("Time (s)")
            ax2.set_yticks([0, 1], ["No-kick", "Kick"])
            ax2.legend()

            output_file2 = destination_folder / f"{app_name}_kicks_1.jpg"
            if not destination_folder.exists():
                destination_folder.mkdir(parents=True)

            fig2.tight_layout()
            fig2.savefig(output_file2, dpi=200)
            plt.cla()
            plt.close(fig2)
        # end of second plot for the delay 

        # calculate the confusion matrix
        new_visualization_dst = destination_folder / "new_metrics"
        if not new_visualization_dst.exists():
            new_visualization_dst.mkdir(parents=True)

        conf_matr_path = new_visualization_dst / "1matrix_conf.jpg"
        ref_kicks = self._input_reference.kicks.to_numpy()
        app_kicks = self._input_app.kicks.to_numpy()

        conf_matrix = sk_metrics.confusion_matrix(
            y_true=ref_kicks, y_pred=app_kicks, labels=[1, 0]
        )
        # print the confusion matrix using Matplotlib
        fig, ax = plt.subplots()

        ax.matshow(conf_matrix, cmap=plt.cm.Blues, alpha=0.3)
        for i in range(conf_matrix.shape[0]):
            for j in range(conf_matrix.shape[1]):
                ax.text(
                    x=j,
                    y=i,
                    s=conf_matrix[i, j],
                    va="center",
                    ha="center",
                    size="xx-large",
                )
                ax.set_xticklabels(["", "Kick", "No kick"])
                ax.set_yticklabels(["", "Kick", "No kick"], rotation=90)
                ax.xaxis.set_ticks_position("none")
                ax.yaxis.set_ticks_position("none")

        plt.xlabel(app_name, fontsize=12)
        plt.ylabel(ref_name, fontsize=12)
        plt.tight_layout()
        fig.savefig(conf_matr_path, dpi=200)
        plt.cla()
        plt.close(fig)

        pie_conf_plot(
            new_visualization_dst,
            app_kicks.reshape(-1),
            ref_kicks.reshape(-1),
            app_name,
        )
        ead_plot(new_visualization_dst, app_kicks.reshape(-1), ref_kicks.reshape(-1))

        return output_file


@pytest.fixture(scope="package", autouse=True)
def visualization_file(
    radar_recording: Path,
    input_reference: InputABC,
    input_app: InputABC,
    config: BenchmarkConfig,
    visualization_dir: Path,
    radar_timestamps: pd.DatetimeIndex,
) -> Path:
    """Fixture for visualizing algorithm and label outputs.

    Args:
        radar_recording: [pytest.fixture] Radar recording path.
        input_reference: [pytest.fixture] Reference input.
        input_app: [pytest.fixture] Application input.
        config: [pytest.fixture] Benchmark configuration.
        visualization_dir: [pytest.fixture] Base visualization directory.
        radar_timestamps: [pytest.fixture] Radar timestamps.

    Returns:
        Path to the generated image.
    """
    vis = Visualization(
        radar_recording=radar_recording,
        input_reference=input_reference,
        input_app=input_app,
        config=config,
        radar_timestamps=radar_timestamps,
    )
    return vis.create_visualization(visualization_dir=visualization_dir)
