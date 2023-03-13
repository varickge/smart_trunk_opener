"""
run the code: python raw_to_target_converter.py --folder-name "20230118"
"""
import argparse
import glob
import os
from pathlib import Path

import numpy as np
import torch


def gauss(n):
    """
    A window function that is applied on the raw data before the Fourier Transformation.
    Parameters:
        -`n`: The number of samples for constructing the window.
    """
    n += 1
    x = np.arange(-n // 2 + 1, n // 2)
    x = 2 * x / n
    y = np.exp(-1 / (1 - x**2))

    return y / y.sum()


def fft(inp, window):
    """
        A function that converts the raw data into target data. The function removes the mean from the data, applies a window function, \
        performs Fourier Transformation, takes the strongest 2 FFTs/targets, does the bit shifts and saves the data.
        Parameters:
            -`inp`: Raw data (radar.npy).
            -`window`: The window function. 
    """

    window = window(inp.shape[-1])
    window /= window.sum()

    I = inp[:, :, 0, :]
    Q = inp[:, :, 1, :]

    data = I + 1j * Q
    data -= data.mean(axis=-1, keepdims=True)
    data = data * window

    fft_data = np.fft.fft(data, axis=-1)

    amps = np.abs(fft_data)
    values, bins = torch.topk(torch.from_numpy(amps), k=2, dim=-1)

    values = values.numpy().astype(np.uint16)
    bins = bins.numpy().astype(np.uint16)

    d_bins = bins + ((values & 0x00FF) << 8)
    d_amps = (values & 0x0FF0) >> 4

    # merge bits for allowing matlab to reconstruct them.
    save_data = np.stack(
        (
            d_bins[:, 0, 0],
            d_amps[:, 0, 0],
            d_bins[:, 0, 1],
            d_amps[:, 0, 1],
            d_bins[:, 1, 0],
            d_amps[:, 1, 0],
            d_bins[:, 1, 1],
            d_amps[:, 1, 1],
        ),
        axis=-1,
    )

    return values, bins, save_data


def decode(inp):
    """
    A function, that given the target input data, decodes the amplitudes and bins, to give to the Matlab algorithm.
        -`inp`: Target data (target.npy).
    """

    N = inp.shape[0]

    tmp = inp.reshape(N, -1)
    target_bins = tmp[:, ::2]
    target_amps = tmp[:, 1::2]

    decoded_bins = target_bins & 0x00FF
    decoded_amps = ((target_bins & 0xFF00) >> 8) + ((target_amps & 0x00FF) << 4)

    amps = decoded_amps.reshape(N, 2, 2)
    bins = decoded_bins.reshape(N, 2, 2)

    return amps, bins


def raw_to_target_converter(folder_name):
    """
    A function that converts the radar.npy files into target.npy files and saves in the same directory.
        -`folder_name`: The folder name containing the radar.npy files. (data/folder_name)
    """

    folder_name = Path(folder_name)

    # find paths of the radar.npy files in the folder
    raw_data_path_list = list(folder_name.rglob("**/raw_data.npy"))

    # convert each radar.npy file to target.npy file and save in the same directory
    for path in raw_data_path_list:
        raw_data = np.load(path)
        _, _, target = fft(raw_data, gauss)

        np.save(path.parent / "target", target)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--folder-name",
        type=str,
        help="folder name of a file containing recordings",
        required=True,
    )

    args = parser.parse_args()

    # TODO: add error handlings, such as for the case when there is no folder with the given name

    raw_to_target_converter(folder_name=args.folder_name)
