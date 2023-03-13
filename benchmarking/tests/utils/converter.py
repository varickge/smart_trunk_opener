"""NumPy to .txt converter for data files."""
from pathlib import Path

import numpy as np
import pytest

__all__ = ["npy_to_txt"]


def npy_to_txt(src: Path, dst: Path):
    """Convert a .npy data file into a .txt data file."""
    data_npy = np.load(src)
    data_npy = data_npy / 4095
    data_txt = array_to_str(data_npy)
    with open(dst, "wt", encoding="utf-8") as file:
        file.write(data_txt)


def array_to_str(data_npy: np.ndarray) -> str:
    """Convert a numpy array into a string following the RDK .txt format."""
    n_samples = data_npy.shape[-1]
    # Build strings for the chirps (Samples separated by newline; fixed to 6 digits after comma)
    chirps_txt = [
        "\n".join([f" {sample:.6f}" for sample in chirp])
        for chirp in data_npy.reshape(-1, n_samples)
    ]
    # Build complete representation (Chirps separated by newline)
    data_txt = "\n\n".join(chirps_txt)
    # EOF newline
    data_txt += "\n"
    return data_txt


@pytest.mark.parametrize(
    ["array", "expected_str"],
    [
        (
            np.arange(4).reshape((1, 1, 1, 4)) / 4095,
            " 0.000000\n 0.000244\n 0.000488\n 0.000733\n",
        ),
        (
            np.arange(4).reshape((1, 1, 2, 2)) / 4095,
            " 0.000000\n 0.000244\n\n 0.000488\n 0.000733\n",
        ),
        (
            np.arange(4).reshape((1, 2, 1, 2)) / 4095,
            " 0.000000\n 0.000244\n\n 0.000488\n 0.000733\n",
        ),
        (
            np.arange(4).reshape((2, 1, 1, 2)) / 4095,
            " 0.000000\n 0.000244\n\n 0.000488\n 0.000733\n",
        ),
        (
            np.array(
                [
                    [[[1960, 1888], [1952, 1885]], [[1901, 1856], [1894, 1858]]],
                    [[[1950, 1889], [1950, 1888]], [[1918, 1862], [1900, 1855]]],
                ],
            )
            / 4095,
            " 0.478632\n 0.461050\n\n 0.476679\n 0.460317\n\n 0.464225\n 0.453236\n\n 0.462515\n 0.453724\n\n"
            " 0.476190\n 0.461294\n\n 0.476190\n 0.461050\n\n 0.468376\n 0.454701\n\n 0.463980\n 0.452991\n",
        ),
    ],
)
def test_array_to_str(array: np.ndarray, expected_str: str) -> None:
    assert expected_str == array_to_str(array)
