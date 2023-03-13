import os
import random
import shutil
from glob import glob
from pathlib import Path
from typing import Callable, Optional, Tuple

import matplotlib.pyplot as plt
import numpy as np
import scipy
import tensorflow as tf
import torch
import torch.nn.functional as fun
from sklearn.metrics import confusion_matrix
from sklearn.utils import shuffle
from tensorflow import keras
from tqdm import tqdm

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"  # Truns off tf warnings
np.warnings.filterwarnings(
    "ignore", category=np.VisibleDeprecationWarning
)  # Truns off np warnings


def decode(inp):
    """
    A function, that given the target input data, decodes the amplitudes and bins.
    Decoding via FFT, getting the n_max amplitudes (here 2)
        -`inp`: Nx8 ,  Target data (target.npy).
        -`return`: Nx2x2
    """

    N = inp.shape[0]

    tmp = inp.reshape(N, -1)
    target_bins = tmp[:, ::2]
    target_amps = tmp[:, 1::2]
    # FFT part, bitshifts
    decoded_bins = target_bins & 0x00FF
    decoded_amps = ((target_bins & 0xFF00) >> 8) + ((target_amps & 0x00FF) << 4)

    amps = decoded_amps.reshape(N, 2, 2)
    bins = decoded_bins.reshape(N, 2, 2)

    return amps, bins

def cleaning(inp, correcting_size=8):
    """
    A function for cleaning noise from ref_kicks files
    if a single kick contains zeros function converts they to ones.
        -`inp`: folder_path -- Data folder path,
                correcting_size -- window size for dilation and erosion
        -`return`: numpy array without noise.
    """
    structure = np.ones(correcting_size)
    isDirectory = os.path.isdir(inp)
    if isDirectory:
        for folder in glob(os.path.join(inp, "*")):
            ref_k = np.load(os.path.join(folder, "ref_kicks.npy"))
            label_kick_filled_dilated = scipy.ndimage.binary_dilation(
                ref_k, structure=structure
            )
            # after taking out redundant zeros, at the end and at the beginning of the kick there are extra ones
            # so it is necessary to kick them out
            label_kick_filled_erosed = scipy.ndimage.binary_erosion(
                label_kick_filled_dilated, structure=structure
            ).astype(int)
            np.save(os.path.join(folder, "ref_kicks.npy"), label_kick_filled_erosed)
    else:
        label_kick_filled_dilated = scipy.ndimage.binary_dilation(
            inp, structure=structure
        )
        # after taking out redundant zeros, at the end and at the beginning of the kick there are extra ones
        # so it is necessary to kick them out
        label_kick_filled_erosed = scipy.ndimage.binary_erosion(
            label_kick_filled_dilated, structure=structure
        ).astype(int)

        return label_kick_filled_erosed

class DataLoader:
    def __init__(
        self,
        root_path="Data",
        is_aug=False,
        split_len=50,
        max_kicks=7,
        mid_buffer=50,
        start_end_buffer=100,
        smoothing_size=3,
        min_duration=12,
        uniform_low=-25,
        uniform_high=25,
        miu=1,
        sigma=4,
        kicks_perc=0.2,
        no_kicks_perc=0.1,
        noise_type="gauss",
        kernel=np.ones(3) / 3,
        eps=1e-8,
        sample_count=10,
    ):
        self.eps = eps
        self.is_aug = is_aug
        self.kernel = kernel
        self.split_len = split_len
        self.max_kicks = max_kicks
        self.kicks_perc = kicks_perc
        self.noise_type = noise_type
        self.mid_buffer = mid_buffer
        self.sample_count = sample_count
        self.min_duration = min_duration
        self.root_path = Path(root_path)
        # attrs for normal dirstribution
        self.miu, self.sigma = miu, sigma
        self.no_kicks_perc = no_kicks_perc
        self.smoothing_size = smoothing_size
        self.start_end_buffer = start_end_buffer
        self.test_data_path = self.root_path / "test"
        self.train_data_folder = self.root_path / "train"
        self.train_data_path = self.train_data_folder / "original"
        # attrs for uniform distribution
        self.uniform_low, self.uniform_high = uniform_low, uniform_high

    def __call__(self):
        up_down_sampled_kicks_raw = np.zeros([0, 50, 2, 2, 32])
        up_down_sampled_kicks_target = np.zeros([0, 50, 8])

        if self.is_aug:
            current_data_path = self.train_data_folder / "current_train_data"

            if not os.path.exists(current_data_path):
                shutil.copytree(self.train_data_path, current_data_path)
                self.train_data_path = current_data_path
                self.MakeDataPaths(self.train_data_path)

                self.AddNoise()
                self.MakeSynthethicData()

                # ------------- Up Sampling and Dpown Sampling the train data -------------
                for kick_rawi, kick_labeli in tqdm(
                    zip(self.paths["kick_raw"], self.paths["kick_labels"])
                ):
                    raw_kick = np.load(kick_rawi)
                    ref_kick = np.load(kick_labeli)

                    up_sampled_kicks = self.UpDownSample(raw_kick, ref_kick, kind="up")

                    down_sampled_kicks = self.UpDownSample(
                        raw_kick, ref_kick, kind="down"
                    )

                    up_down_sampled_kicks_raw = np.concatenate(
                        [up_down_sampled_kicks_raw, up_sampled_kicks[0]]
                    )
                    up_down_sampled_kicks_raw = np.concatenate(
                        [up_down_sampled_kicks_raw, down_sampled_kicks[0]]
                    )

                    up_down_sampled_kicks_target = np.concatenate(
                        [up_down_sampled_kicks_target, up_sampled_kicks[1]]
                    )
                    up_down_sampled_kicks_target = np.concatenate(
                        [up_down_sampled_kicks_target, down_sampled_kicks[1]]
                    )
                # ------------- Up Sampling and Dpown Sampling the train data -------------

            # not the best solution, zut apahovutyan hamar
            self.train_data_path = current_data_path
            self.MakeDataPaths(self.train_data_path)

        train_data = self.DataLoad(
            raw_up_down_sampled_kikcs=up_down_sampled_kicks_raw,
            target_up_down_sampled_kikcs=up_down_sampled_kicks_target,
            decode_target=False,
        )

        try:
            test_data = self.TestDataLoad()
        except Exception as e:
            print("There are no test data")
            raise e

        return train_data, test_data

    def MakeDataPaths(self, rootp):
        kick_paths = rootp / "kick"
        kick_raw_paths = sorted(list(kick_paths.rglob("*/radar.npy")))
        kick_target_paths = sorted(list(kick_paths.rglob("*/target.npy")))
        kick_labels_paths = sorted(list(kick_paths.rglob("*/ref_kicks.npy")))

        no_kick_paths = rootp / "no_kick"
        no_kick_raw_paths = sorted(list(no_kick_paths.rglob("*/radar.npy")))
        no_kick_target_paths = sorted(list(no_kick_paths.rglob("*/target.npy")))
        no_kick_labels_paths = sorted(list(no_kick_paths.rglob("*/ref_kicks.npy")))

        background_paths = rootp / "background"
        background_raw_paths = sorted(list(background_paths.rglob("*/radar.npy")))
        background_target_paths = sorted(list(background_paths.rglob("*/target.npy")))
        background_labels_paths = sorted(
            list(background_paths.rglob("*/ref_kicks.npy"))
        )

        self.paths = {
            "kick_raw": kick_raw_paths,
            "kick_target": kick_target_paths,
            "kick_labels": kick_labels_paths,
            "no_kick_raw": no_kick_raw_paths,
            "no_kick_target": no_kick_target_paths,
            "no_kick_labels": no_kick_labels_paths,
            "background_raw": background_raw_paths,
            "background_target": background_target_paths,
            "background_labels": background_labels_paths,
        }

    def MakeSynthethicData(self):
        """
        A function that takes kick segments, sets them to a given background, convolves the edges and saves as a `original_name_synthetic`.
        """

        kick_raw_paths = self.paths["kick_raw"]
        take_kicks_num = int(
            len(kick_raw_paths) * self.kicks_perc
        )  # If Need change perc
        rand_kick_paths = np.random.choice(kick_raw_paths, take_kicks_num)

        for kick_path in rand_kick_paths:
            raw_data = np.load(kick_path).astype(float)
            ref_kicks = np.load(kick_path.parents[1] / "ref_kicks.npy")

            labels, group_index = scipy.ndimage.label(ref_kicks)
            labels_i, labels_j, labels_i_count = np.unique(
                labels, return_index=True, return_counts=True
            )
            label_kick_start, label_kick_stop = (
                labels_j[1:],
                labels_j[1:] + labels_i_count[1:] - 1,
            )

            kicks = []
            for i in range(len(label_kick_start)):
                kicks.append(raw_data[label_kick_start[i] : label_kick_stop[i]])

        synthetic_data_path = self.train_data_path / "kick_synthetic"
        synthetic_data_path.mkdir()

        while len(kicks):
            # chooses a random background folder and a random number of kicks to put on data
            num_kicks = random.choice(range(1, self.max_kicks))
            rand_background_folder = random.choice(self.paths["background_raw"])

            # if number of segments to insert is greater then the number of the remaining segments, insert the remaining
            if num_kicks > len(kicks):
                kick_set = kicks
                kicks = []
            else:
                kick_set = kicks[:num_kicks]
                kicks = kicks[num_kicks:]

            # loads empty labels and background data
            background, labels = np.load(rand_background_folder), np.load(
                rand_background_folder.parents[1] / "ref_kicks.npy"
            )
            # puts the augmented data over the loaded background (without intersections)
            synth_data, synth_labels = self.AddAugmentedDataToBackground(
                background, labels, augmented_data=kick_set
            )
            # conv on new data
            label, group_index = scipy.ndimage.label(synth_labels)
            labels_i, labels_j, labels_i_count = np.unique(
                label, return_index=True, return_counts=True
            )
            label_kick_start, label_kick_stop = (
                labels_j[1:],
                labels_j[1:] + labels_i_count[1:] - 1,
            )
            kick_segment = np.stack([label_kick_start, label_kick_stop]).T

            # indices which represent segmets where background and kick were merged
            length = self.smoothing_size // 2 + 1
            shift = np.concatenate([np.ones(length) * (length // 2), np.zeros(length)])
            shift = np.concatenate(
                [np.ones(length) * (length // 2), np.ones(length) * (-length // 2)]
            )
            conv_segment = np.stack([np.arange(length), np.arange(-length + 1, 1)])
            indices = (
                (kick_segment[:, :, None] + conv_segment).reshape(-1, 2 * length)
                - shift
            ).astype(int)

            # creating mask for raw data which will be convolved
            conv_mask = np.clip(
                np.arange(synth_data.shape[0])[:, None]
                + np.arange(self.smoothing_size),
                a_min=0,
                a_max=synth_data.shape[0] - 1,
            )

            # convolution kernel: merged segmets are being convolved with [1/3,1/3,1/3] and the remainder with [1,0,0] kernel
            conv_kernel = np.zeros_like(conv_mask, dtype=np.float32)
            conv_kernel[:, 0] = 1
            conv_kernel[indices] = np.ones(self.smoothing_size) / self.smoothing_size

            # convolve on merged data
            synth_data = (
                synth_data[conv_mask] * conv_kernel[..., None, None, None]
            ).sum(axis=1)
            # clip as all raw_data's maximum number is 4094
            synth_data = np.clip(synth_data, 0, 4094)

            # FFT here, and saving
            target = np.ones((len(synth_data), 8))  # change later

            # save the synthetic kick data with the same record name in synthetic_kick folder
            record_name = Path(rand_background_folder.parents[1].name.split("/")[-1])
            save_path = synthetic_data_path / record_name
            os.makedirs(save_path, exist_ok=True)

            np.save(save_path / "radar.npy", synth_data.astype(np.uint16))
            np.save(save_path / "ref_kicks.npy", synth_labels.astype(np.uint16))
            np.save(save_path / "target.npy", target.astype(np.uint16))

    def AddNoise(self):
        """
        A function for adding noise given raw data.
            -`inp`: raw data path
            -`return`:
        """
        kick_raw_paths = self.paths["kick_raw"]
        no_kick_raw_paths = self.paths["no_kick_raw"] + self.paths["background_raw"]

        # randomly taking data paths from kick and no_kicks
        take_kicks_num = int(len(kick_raw_paths) * self.kicks_perc)
        take_no_kicks_num = int(len(kick_raw_paths) * self.no_kicks_perc)

        rand_kick_paths = np.random.choice(kick_raw_paths, take_kicks_num)
        rand_no_kick_paths = np.random.choice(no_kick_raw_paths, take_no_kicks_num)

        all_data_paths = np.append(rand_kick_paths, rand_no_kick_paths)

        # load data and apply noise
        for path in all_data_paths:
            # load the data
            raw_data = np.load(path).astype(float)

            # create folder to save the noisy data if doesn't exist
            noise_data_fodler_path = path.parents[3] / Path(
                path.parents[2].name + "_noise"
            )
            os.makedirs(noise_data_fodler_path, exist_ok=True)

            record_name = Path(path.parents[1].name.split("/")[-1])
            save_path = noise_data_fodler_path / record_name
            os.makedirs(save_path, exist_ok=True)

            # add noise
            if self.noise_type == "gauss":
                raw_data_noise = raw_data + np.random.normal(
                    self.miu, self.sigma, size=raw_data.shape
                )
            elif self.noise_type == "uniform":
                raw_data_noise = raw_data + np.random.uniform(
                    self.uniform_low, self.uniform_high, size=raw_data.shape
                )

            # clip as all raw_data's maximum number is 4094
            raw_data_noise = np.clip(raw_data_noise, 0, 4094)

            # FFT here, and saving
            target = raw_to_target(raw_data_noise)  # change later
            ref_kicks = np.load(path.parents[1] / "ref_kicks.npy")

            np.save(save_path / "radar.npy", raw_data_noise.astype(np.uint16))
            np.save(save_path / "ref_kicks.npy", ref_kicks.astype(np.uint16))
            np.save(save_path / "target.npy", target.astype(np.uint16))

    def get_start_stop(self, ref_kicks):
        """
        A function that returns the kick starts, kick stops, and the number of kicks, given labels as input.
        """

        labels, group_num = scipy.ndimage.label(ref_kicks)
        labels_i, labels_j, labels_i_count = np.unique(
            labels, return_index=True, return_counts=True
        )
        kick_starts, kick_stops = labels_j[1:], labels_j[1:] + labels_i_count[1:] - 1

        return kick_starts, kick_stops, group_num

    def UpDownSample(self, raw_data, ref_kicks, kind):
        """
        A function that upsamples or downsamples a given kick segment.
            -`raw_data`: radar.npy
            -`ref_kicks`: Labels
            -`kind`: The sampling kind. Possible parameters are "up" or "down".
            -`count`: The number of samples to generate
        """

        if not isinstance(raw_data, np.ndarray):
            raise TypeError(
                f"Expected raw_data to be of type np.ndarray, but got {type(raw_data)}"
            )

        if not isinstance(ref_kicks, np.ndarray):
            raise TypeError(
                f"Expected ref_kicks to be of type np.ndarray, but got {type(ref_kicks)}"
            )

        if (
            (raw_data.ndim != 4)
            or (raw_data.shape[1] != 2)
            or (raw_data.shape[2] != 2)
            or (raw_data.shape[-1] != 32)
        ):
            raise ValueError("Expected 4D input with shape Nx2x2x32")

        if raw_data.shape[0] != ref_kicks.shape[0]:
            raise ValueError(
                "The size of the first dim of the raw_data and ref_kicks must be the same"
            )

        if kind != "up" and kind != "down":
            raise ValueError(f"Expected sampling kind 'up' or 'down', but got {kind}")

        # get kick starts and kick ends
        kick_starts, kick_stops, num_kicks = self.get_start_stop(ref_kicks)

        # define acceptable kick durations
        kick_min_duration, kick_max_duration = 12, 50
        downsampling_min_size = 35
        upsampling_max_size = 35

        # the resulting array, on which all the sampled kicks will be appended
        all_raw_kicks = np.zeros((0, 50, 2, 2, 32))
        for index in np.arange(num_kicks):
            # get kick crop from raw data
            kick_cropped = raw_data[kick_starts[index] : kick_stops[index]]
            kick_len = kick_stops[index] - kick_starts[index] + 1

            if kick_len > 50:
                warnings.warn("Skipping longer kicks", RuntimeWarning)
                continue

            # if it is the first kick, its left border begins from the recording's first frame
            if index != 0:
                left_border = kick_starts[index] - kick_stops[index - 1]
            else:
                left_border = kick_starts[index]

            # if it is the last kick, its right border begins from the recording's last frame
            if index < num_kicks - 1:
                right_border = kick_starts[index + 1] - kick_stops[index]
            else:
                right_border = raw_data.shape[0] - 1 - kick_stops[index]

            # iterating over all kick
            for _ in range(self.sample_count):
                if kind == "up":
                    # if the kick length is not in range (12, 35), skip the kick
                    if not (kick_min_duration <= kick_len <= upsampling_max_size):
                        continue

                    upsample_size = np.random.randint(kick_len, kick_max_duration + 1)

                    # if the upsampled kick length plus its borders length is smaller than 50, skip the kick
                    if upsample_size + left_border + right_border < kick_max_duration:
                        continue

                if kind == "down":
                    downsample_size = np.random.randint(kick_min_duration, kick_len)

                    # if the downsampled kick length plus its borders length is smaller than 50, skip the kick
                    if downsample_size + left_border + right_border < kick_max_duration:
                        continue

                n_samples = 32

                antenna_1_I = kick_cropped[:, 0, 0, :].flatten()
                antenna_1_Q = kick_cropped[:, 0, 1, :].flatten()
                antenna_2_I = kick_cropped[:, 1, 0, :].flatten()
                antenna_2_Q = kick_cropped[:, 1, 1, :].flatten()

                # interoplate each antenna and each component separately (I/Q), then stack them together in the right order
                if kind == "up":
                    antenna_1_I = torch.nn.functional.interpolate(
                        torch.tensor(antenna_1_I.astype(float))[None, None],
                        upsample_size * n_samples,
                    )[0, 0].numpy()
                    antenna_1_Q = torch.nn.functional.interpolate(
                        torch.tensor(antenna_1_Q.astype(float))[None, None],
                        upsample_size * n_samples,
                    )[0, 0].numpy()
                    antenna_2_I = torch.nn.functional.interpolate(
                        torch.tensor(antenna_2_I.astype(float))[None, None],
                        upsample_size * n_samples,
                    )[0, 0].numpy()
                    antenna_2_Q = torch.nn.functional.interpolate(
                        torch.tensor(antenna_2_Q.astype(float))[None, None],
                        upsample_size * n_samples,
                    )[0, 0].numpy()

                if kind == "down":
                    antenna_1_I = torch.nn.functional.interpolate(
                        torch.tensor(antenna_1_I.astype(float))[None, None],
                        downsample_size * n_samples,
                    )[0, 0].numpy()
                    antenna_1_Q = torch.nn.functional.interpolate(
                        torch.tensor(antenna_1_Q.astype(float))[None, None],
                        downsample_size * n_samples,
                    )[0, 0].numpy()
                    antenna_2_I = torch.nn.functional.interpolate(
                        torch.tensor(antenna_2_I.astype(float))[None, None],
                        downsample_size * n_samples,
                    )[0, 0].numpy()
                    antenna_2_Q = torch.nn.functional.interpolate(
                        torch.tensor(antenna_2_Q.astype(float))[None, None],
                        downsample_size * n_samples,
                    )[0, 0].numpy()

                antenna_1_I = antenna_1_I.reshape(-1, n_samples)
                antenna_1_Q = antenna_1_Q.reshape(-1, n_samples)
                antenna_2_I = antenna_2_I.reshape(-1, n_samples)
                antenna_2_Q = antenna_2_Q.reshape(-1, n_samples)

                if kind == "up":
                    kick_upsampled = np.stack(
                        (
                            np.stack((antenna_1_I, antenna_1_Q), axis=-2),
                            np.stack((antenna_2_I, antenna_2_Q), axis=-2),
                        ),
                        axis=-3,
                    )

                    if upsample_size == kick_max_duration:
                        all_raw_kicks = np.concatenate(
                            (all_raw_kicks, kick_upsampled[None]), axis=0
                        )
                        continue

                    border_size = kick_max_duration - upsample_size

                if kind == "down":
                    kick_downsampled = np.stack(
                        (
                            np.stack((antenna_1_I, antenna_1_Q), axis=-2),
                            np.stack((antenna_2_I, antenna_2_Q), axis=-2),
                        ),
                        axis=-3,
                    )

                    border_size = kick_max_duration - downsample_size

                # get the extra frames
                nudge = left_border + right_border - border_size

                # if the nudge is zero, just concatenate the left and right borders and continue
                if nudge == 0:
                    left_border_slice = raw_data[
                        kick_starts[index] - left_border : kick_starts[index]
                    ]
                    right_border_slice = raw_data[
                        kick_stops[index] : kick_stops[index] + right_border
                    ]
                    modified_kick = np.concatenate(
                        (left_border_slice, kick_downsampled, right_border_slice)
                    )
                    all_raw_kicks = np.concatenate(
                        (all_raw_kicks, modified_kick[None]), axis=0
                    )
                    continue
                # When the nudge is much bigger that needed
                elif nudge > border_size:
                    if left_border < right_border:
                        from_left = np.random.randint(0, min(border_size, left_border))
                        from_right = border_size - from_left

                    elif left_border >= right_border:
                        from_right = np.random.randint(
                            0, min(border_size, right_border)
                        )
                        from_left = border_size - from_right
                # When the nudge is bigger from the minimum of the borders
                elif nudge > min(left_border, right_border):
                    if left_border < right_border:
                        from_left = np.random.randint(left_border)
                        from_right = border_size - from_left
                    elif left_border >= right_border:
                        from_right = np.random.randint(right_border)
                        from_left = border_size - from_right
                else:
                    p = np.random.randint(0, nudge)
                    from_left = left_border - p
                    from_right = right_border - (nudge - p)

                left_border_slice = raw_data[
                    kick_starts[index] - from_left : kick_starts[index]
                ]
                right_border_slice = raw_data[
                    kick_stops[index] : kick_stops[index] + from_right
                ]

                if kind == "up":
                    modified_kick = np.concatenate(
                        (left_border_slice, kick_upsampled, right_border_slice)
                    )

                if kind == "down":
                    modified_kick = np.concatenate(
                        (left_border_slice, kick_downsampled, right_border_slice)
                    )

                all_raw_kicks = np.concatenate(
                    (all_raw_kicks, modified_kick[None]), axis=0
                )

        # get targets for all sampled kicks
        all_target_kikcs = np.zeros([0, 50, 8])
        for k in range(len(all_raw_kicks)):
            all_target_kikcs = np.concatenate(
                [all_target_kikcs, (raw_to_target(all_raw_kicks[k]))[None]], axis=0
            )

        return all_raw_kicks, all_target_kikcs

    def GetRandomTimeSegments(self, segment_len, len_whole_seq):
        """
        A function for generating random time segments for a given kick.
            -`inp`: length of segment,
                    length of the whole sequense on which to generate
                    the number of time steps to keep empty (0) in the sequence
            -`return`: a tuple (segment_start, segment_end)
        """

        # Make sure segment doesn't run past the background
        segment_start = np.random.randint(
            low=self.start_end_buffer,
            high=len_whole_seq - segment_len - self.start_end_buffer,
        )
        segment_end = segment_start + segment_len - 1

        return segment_start, segment_end

    def IsOverlapping(self, segment_len, previous_segments):
        """
        A function for checking if the time segment being inserted is overlapping, or near to any of the previous time segments.
            -`inp`: length of segment
                    list containing tuples of all previously inserted segments[(segment_start, segment_end), ...]
                    the distance to keep as a margin between the segments
            -`return`: a boolean value: if overlaps or not
        """

        segment_start, segment_end = segment_len

        overlap = False

        for previous_start, previous_end in previous_segments:
            if (
                segment_start <= previous_end + self.mid_buffer
                and segment_end >= previous_start - self.mid_buffer
            ):
                overlap = True
                return overlap

        return overlap

    def InsertSegmentToBackground(self, background, segment, previous_segments):
        """
        A function for inserting segments upon background.
            -`inp`: the array of background
                    the array of segment
                    the list of tuples representing segments inserted previously
            -`return`: new background with inserted segment and the time tuple for the segment
        """

        segment_len = len(segment)
        len_whole_seq = len(background)

        segment_time = self.GetRandomTimeSegments(segment_len, len_whole_seq)

        while self.IsOverlapping(segment_time, previous_segments):
            segment_time = self.GetRandomTimeSegments(segment_len, len_whole_seq)

        previous_segments.append(segment_time)

        new_background = background
        new_background[segment_time[0] : segment_time[1] + 1] = segment

        return new_background, segment_time, previous_segments

    def AddAugmentedDataToBackground(self, background, labels, augmented_data):
        """
        A function for adding augmented data to background array and updating labels.
            -`inp`: the array of background
                    the array of labels
                    the new augmented data (segment) to insert

            -`return`: the new data with inserted augmented segment and updated labels
        """
        previous_segments = []
        out_data = background.copy()
        out_labels = labels.copy()

        for segment in augmented_data:
            out_data, segment_time, previous_segments = self.InsertSegmentToBackground(
                out_data, segment, previous_segments
            )
            out_labels[segment_time[0] : segment_time[1] + 1] = 1

        return out_data, out_labels

    def DataLoad(
        self,
        data_path=None,
        raw_up_down_sampled_kikcs=np.empty(0),
        target_up_down_sampled_kikcs=np.empty(0),
        decode_target=False,
    ):
        """
        A function for loading training data (X_train, Y_train)
            -`inp`: Data folder path, split_len (<= len(data)).
            -`return`: X_train, Y_train.
        """

        if data_path:
            path = Path(data_path)
        else:
            path = self.train_data_path

        interval_target_data = np.zeros(
            [0, self.split_len - self.kernel.shape[0] + 1, 8]
        )
        interval_raw_data = np.zeros([0, self.split_len, 2, 2, 32])
        interval_labels = np.zeros([0])

        all_raw_datas = sorted(list(path.rglob("*/radar.npy")))
        all_target_datas = sorted(list(path.rglob("*/target.npy")))
        all_labels = sorted(list(path.rglob("*/ref_kicks.npy")))

        for folder_i in range(len(all_target_datas)):
            raw_data = np.load(all_raw_datas[folder_i]).astype(float)
            target_data = np.load(all_target_datas[folder_i])
            labels = np.load(all_labels[folder_i]).astype(float)

            if decode_target:
                amps, bins = decode(target_data)  # self.
                len_points = amps.shape[0]
                amps, bins = amps.reshape(len_points, 4), bins.reshape(len_points, 4)
                target_data = np.hstack((amps, bins))

            target_data = target_data.astype(float)
            target_data[:, [4, 5, 6, 7]] = target_data[:, [4, 5, 6, 7]] / 31

            interval_labels_curr = np.zeros(target_data.shape[0] - self.split_len + 1)
            interval_target_data_curr = []
            interval_raw_data_curr = []
            del_idx = []

            for i in range(target_data.shape[0] - self.split_len + 1):
                data_i = target_data[i : i + self.split_len]
                label_i = labels[i : i + self.split_len]

                label, group_index = scipy.ndimage.label(label_i)
                labels_i, labels_j, labels_i_count = np.unique(
                    label, return_index=True, return_counts=True
                )
                label_kick_start, label_kick_stop = (
                    labels_j[1:],
                    labels_j[1:] + labels_i_count[1:] - 1,
                )
                _len = len(label_kick_start)
                if _len and i != 0 and i != target_data.shape[0] - self.split_len:
                    if (
                        _len > 1
                        or (labels[i - 1] or labels[i + self.split_len])
                        or (label_kick_stop - label_kick_start) < self.min_duration
                    ):
                        del_idx.append(i)
                        continue
                    else:
                        interval_labels_curr[i] = 1

                convolved_data = np.zeros(shape=(self.split_len - 2, 8))
                mask = np.arange(self.split_len - self.kernel.shape[0] + 1)[
                    :, None
                ] + np.arange(self.kernel.shape[0])
                data_avg = (
                    data_i[..., [0, 1, 2, 3]][mask] * self.kernel[..., None]
                ).sum(axis=1)
                data_avg = data_avg / np.maximum(np.max(data_avg, axis=0), self.eps)
                convolved_data[:, [0, 1, 2, 3]] = data_avg
                convolved_data[:, [4, 5, 6, 7]] = data_i[2:, [4, 5, 6, 7]]

                interval_target_data_curr.append(convolved_data)
                interval_raw_data_curr.append(raw_data[i : i + self.split_len])

            if len(del_idx):
                # filtering out non-kicks that contain part from kick
                interval_labels_curr = np.delete(interval_labels_curr, del_idx)

            interval_target_data = np.concatenate(
                (interval_target_data, interval_target_data_curr), axis=0
            )  # shape (N,8)
            interval_raw_data = np.concatenate(
                (interval_raw_data, interval_raw_data_curr), axis=0
            )  # shape (N,8)
            interval_labels = np.concatenate(
                (interval_labels, interval_labels_curr), axis=0
            )  # shape (N,)
        if len(raw_up_down_sampled_kikcs):
            #             print("Entered up/down sampling cat", interval_raw_data.shape, interval_target_data.shape, interval_labels.shape)
            interval_raw_data = np.concatenate(
                [interval_raw_data, raw_up_down_sampled_kikcs], axis=0
            )
            mask = np.arange(self.split_len - self.kernel.shape[0] + 1)[
                :, None
            ] + np.arange(self.kernel.shape[0])
            data_avg = (
                target_up_down_sampled_kikcs[..., [0, 1, 2, 3]][:, mask]
                * self.kernel[:, None]
            ).sum(axis=-2)
            data_avg = (
                data_avg / np.maximum(np.max(data_avg, axis=1), self.eps)[:, None]
            )
            concatenated_data = np.concatenate(
                [data_avg, target_up_down_sampled_kikcs[:, 2:, [4, 5, 6, 7]]], axis=-1
            )
            interval_target_data = np.concatenate(
                [interval_target_data, concatenated_data], axis=0
            )
            interval_labels = np.concatenate(
                [interval_labels, np.ones(len(raw_up_down_sampled_kikcs))], axis=0
            )

        return (
            interval_raw_data,
            interval_target_data[..., [0, 4, 1, 5, 2, 6, 3, 7]],
            interval_labels,
        )

    def TestDataLoad(self):
        test_data_kicks = list(self.test_data_path.rglob("kick.npy"))
        test_data_kicks_labels = list(self.test_data_path.rglob("kick_labels.npy"))
        test_data_no_kikcs = list(self.test_data_path.rglob("no_kick.npy"))
        test_data_no_kicks_labels = list(
            self.test_data_path.rglob("no_kick_labels.npy")
        )

        test_data = np.zeros([0, 48, 8])
        test_labels = np.zeros([0])

        test_all_data_paths = test_data_kicks + test_data_no_kikcs
        test_all_lbl_paths = test_data_kicks_labels + test_data_no_kicks_labels

        for i in range(len(test_all_data_paths)):
            datas = np.load(test_all_data_paths[i])
            labels = np.load(test_all_lbl_paths[i])
            mask = np.arange(self.split_len - self.kernel.shape[0] + 1)[
                :, None
            ] + np.arange(self.kernel.shape[0])
            data_avg = (datas[..., [0, 1, 2, 3]][:, mask] * self.kernel[:, None]).sum(
                axis=-2
            )
            data_avg = (
                data_avg / np.maximum(np.max(data_avg, axis=1), self.eps)[:, None]
            )
            concatenated_data = np.concatenate(
                [data_avg, datas[:, 2:, [4, 5, 6, 7]]], axis=-1
            )
            test_data = np.concatenate([test_data, concatenated_data], axis=0)
            test_labels = np.concatenate([test_labels, labels])

        return test_data[..., [0, 4, 1, 5, 2, 6, 3, 7]], test_labels


def PlotPrediction(predictions, labels, size=1000):
    """
    A function that visualises the prediction.
    """
    pred = np.array(tf.math.argmax(predictions, axis=1))
    plt.plot(np.arange(len(labels))[:size], labels[:size], label="True labels")
    plt.plot(np.arange(len(pred))[:size], pred[:size], label="Predictions")
    plt.yticks([0, 1], ["No kick", "Kick"])
    plt.legend(loc="upper left")
    plt.show()


def CalcACC(predictions, labels):
    pred = np.array(tf.math.argmax(predictions, axis=1))
    acc = round(100 * (pred == labels).mean(), 2)

    return acc


def _gauss(n: int) -> np.ndarray:  # pylint: disable=invalid-name
    """
    A window function that is applied on the raw data before the Fourier Transformation.

    Args:
        n: The number of samples for constructing the window.

    Returns:
        Window as numpy array.
    """
    # pylint: disable=invalid-name
    n += 1
    x = np.arange(-n // 2 + 1, n // 2)
    x = 2 * x / n  # type: ignore
    y = np.exp(-1 / (1 - x**2))

    return y / y.sum()


def fft(
    raw_data: np.ndarray, window_fn: Optional[Callable[[int], np.ndarray]] = None
) -> np.ndarray:
    """Compute fast fourier transformation on radar data.

    Args:
        raw_data: [frames, antennas, IQ, samples].
        window_fn: Window function for FFT. If None, no window is applied. Otherwise, the given window
            function is applied. (Default: None)

    Returns:
        FFT data [frames, antennas, samples].
    """
    data = np.vectorize(complex)(raw_data[..., 0, :], raw_data[..., 1, :])
    data -= data.mean(axis=-1, keepdims=True)

    if window_fn is not None:
        window = window_fn(raw_data.shape[-1])
        window /= window.sum()
        data = data * window

    fft_data: np.ndarray = np.fft.fft(data, axis=-1)

    return fft_data


def target_extraction_from_raw(fft_data, num_targets=2):
    """Extract n targets from fft data.

    Args:
        fft_data: Fourier transformed data [frames, antennas, samples].
        num_targets: Number of targets.

    Returns:
        Tuple of Target data values and corresponding bins.
    """
    # Obtaining amplitudes of the frequencies
    amp = np.abs(fft_data)

    # Get top k values
    bins = np.argpartition(amp, -num_targets, axis=-1)[..., -num_targets:][..., ::-1]
    values = np.take_along_axis(amp, indices=bins, axis=-1)

    values = values.astype(np.uint16).reshape(-1, 4)
    bins = bins.astype(np.uint16).reshape(-1, 4)

    return values, bins


def raw_to_target(raw_data, num_targets=2):
    """Converts raw data to target data using FFT"""
    fft_data = fft(raw_data, window_fn=_gauss)
    target_data = target_extraction_from_raw(fft_data=fft_data, num_targets=num_targets)
    result = np.concatenate(target_data, axis=1)

    return result
