"""Fixtures to process data with the applications."""
from datetime import datetime
from pathlib import Path

import pandas as pd
import pytest

__all__ = ["load_timestamps", "radar_timestamps", "stdout_dir"]


def load_timestamps(timestamps_file: Path) -> pd.DatetimeIndex:
    """Load the timestamps from a file.

    Args:
        timestamps_file: Path to the file.

    Returns:
        Timestamps as DatetimeIndex.
    """
    with open(timestamps_file, "r", encoding="utf-8") as f_handle:
        timestamps = [
            datetime.utcfromtimestamp(float(line)) for line in f_handle.readlines()
        ]
    timestamps = pd.to_datetime(timestamps)

    return timestamps


@pytest.fixture(scope="package")
def radar_timestamps(radar_recording: Path) -> pd.DatetimeIndex:
    """Load the timestamps for the radar recording.

    Args:
        radar_recording: [pytest.fixture] Directory of the radar recording.

    Returns:
        Datetime index with the absolute radar timestamps.
    """
    timestamps_file = radar_recording / "radar_timestamp.csv"
    if not timestamps_file.exists():
        timestamps_file = radar_recording / "target_timestamp.csv"

    return load_timestamps(timestamps_file)


@pytest.fixture(scope="session", autouse=True)
def stdout_dir() -> Path:
    stdout_dir = Path("artifacts/stdout")
    stdout_dir.mkdir(parents=True, exist_ok=True)
    return stdout_dir
