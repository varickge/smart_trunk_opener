"""Fixtures and classes for different types of benchmarking inputs."""
import copy
import json
import os
import shlex
import subprocess
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd
import pytest
from _pytest.fixtures import FixtureRequest
from ifxdaq.utils.common import read_json

from ..utils.cfg import BenchmarkConfig
from .utils import load_timestamps

__all__ = ["input_reference", "input_app"]


class InputABC(ABC):
    """Abstract base class for possible benchmarking inputs."""

    _TIMESTAMP_FILENAME: str

    def __init__(self, recording_path: Path, config: BenchmarkConfig) -> None:
        self._recording_path = recording_path
        self._config = config
        self._timestamps: pd.DatetimeIndex = self._load_timestamps()
        self._kicks: pd.DataFrame = self._calculate_kicks()

    @property
    @abstractmethod
    def name(self) -> str:
        """Display name/prefix in plots.

        Returns:
            Prefix/name.
        """
        pass

    @property
    def timestamps(self) -> pd.DatetimeIndex:
        """Return timestamps.

        Returns:
            Copy of timestamps.
        """
        return copy.deepcopy(self._timestamps)

    @property
    def kicks(self) -> pd.DataFrame:
        """Return kicking information."

        Returns:
            Copy of kick data frame.
        """ ""
        return copy.deepcopy(self._kicks)

    def _load_timestamps(self) -> pd.DatetimeIndex:
        """Load the timestamps for the radar recording.

        Returns:
            Datetime index with the absolute timestamps.
        """
        timestamps_file = self._recording_path / self._TIMESTAMP_FILENAME
        if not timestamps_file.exists():  # Fallback for legacy ifxdaq format
            timestamps_file = self._recording_path / "time.csv"
        return load_timestamps(timestamps_file)

    @abstractmethod
    def _calculate_kicks(self) -> pd.DataFrame:
        raise NotImplementedError


class Algorithm(InputABC):
    """Base class for algorithm based inputs.

    Args:
        recording_path: Path to the recording.
        config: Benchmarking configuration.
        stdout_dir: Path where results are stored.
    """

    _TIMESTAMP_FILENAME = "target_timestamp.csv"

    def __init__(
        self,
        recording_path: Path,
        config: BenchmarkConfig,
        stdout_dir: Optional[Path] = None,
    ) -> None:
        self._stdout_dir = stdout_dir
        super().__init__(recording_path=recording_path, config=config)

    @property
    @abstractmethod
    def _command(self) -> str:
        pass

    def _get_app_results(self, shell=False) -> str:
        """Run command and return stdout."""
        # Insert the recording into the command.
        # TODO: Probably we need make the final file individual for each algorithm (e.g. radar.npy/target.npy).
        app_cmd_with_args = self._command.format(
            (self._recording_path / "target.npy").as_posix(),
        )
        # Run the command.
        if shell is False:
            app_cmd_with_args = shlex.split(app_cmd_with_args)

        result = subprocess.run(
            app_cmd_with_args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            shell=shell,
        )
        if result.returncode:
            pytest.fail(
                msg=f"\nreturncode:{result.returncode}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )
        return result.stdout

    def get_output_file_name(self) -> Path:
        """Construct output file name.

        Returns:
            Path where copy of stdout is stored.
        """
        return self._stdout_dir / f"{self._recording_path.parent.stem}_{self.name}.txt"

    def _save_app_output(self, stdout: str) -> Path:
        """Save original app output in some file withing the artifact's folder."""
        stdout_file = self.get_output_file_name()
        with open(stdout_file, "wt", encoding="utf-8") as file:
            file.write(stdout)
        return stdout_file

    def _parse_kicks(self, app_stdout: str) -> pd.DataFrame:
        """Parse the raw application output (stdout) into tracks from app."""
        raise NotImplementedError

    def _calculate_kicks(
        self,
    ) -> pd.DataFrame:
        app_out = self._get_app_results()
        self._save_app_output(stdout=app_out)
        return self._parse_kicks(app_stdout=app_out)


class CAlgorithm(Algorithm):
    """C/DLL based input."""

    @property
    def name(self) -> str:
        """Display name/prefix in plots.

        Returns:
            Prefix/name.
        """
        return "C-Algo"

    @property
    def _command(self) -> str:
        # TODO: Integrate application
        raise NotImplementedError


class MatlabAlgorithm(Algorithm):
    """Matlab based input.

    Args:
        recording_path: Path to the recording.
        stdout_dir: Path where results are stored.
    """

    def __init__(
        self,
        recording_path: Path,
        config: BenchmarkConfig,
        stdout_dir: Optional[Path] = None,
    ) -> None:
        super().__init__(
            recording_path=recording_path, config=config, stdout_dir=stdout_dir
        )

    @property
    def name(self) -> str:
        """Display name/prefix in plots.

        Returns:
            Prefix/name.
        """
        return "Matlab-Algo"

    @property
    def _command(self) -> str:
        command = "C:/Programme/kick_detection_recording/application/kick_detection_recording.exe {}"
        return command

    def _parse_kicks(self, app_stdout: str) -> pd.DataFrame:
        """Parse the raw application output (stdout) into tracks from app."""
        parsed_output = [
            json.loads(s) for s in app_stdout.split("\n") if s.startswith("{")
        ]

        df_kick = pd.DataFrame(
            data={"kick": [0 for _ in range(len(self.timestamps))]},
            index=self.timestamps,
        )

        for frame_output in parsed_output:
            if frame_output["yagi_kick"] and frame_output["patch_kick"]:
                kick_start = frame_output["kick_start"]
                kick_stop = frame_output["frame"]
                kick_duration = kick_stop - kick_start + 1
                df_kick.iloc[kick_start - 1 : kick_stop] = np.ones((kick_duration, 1))
        return df_kick


class PythonMLAlgo(Algorithm):
    def __init__(
        self,
        recording_path: Path,
        config: BenchmarkConfig,
        stdout_dir: Optional[Path] = None,
    ) -> None:
        super().__init__(
            recording_path=recording_path, config=config, stdout_dir=stdout_dir
        )

    @property
    def name(self) -> str:
        """Display name/prefix in plots.

        Returns:
            Prefix/name.
        """
        return "ML-Algo"

    @property
    def _command(self) -> str:

        script_path = Path(os.path.realpath(__file__))
        script_path = script_path.parents[3] / "tf_net" / "tf_inference.py"
        script_path = script_path.as_posix()

        command = "python " + script_path + " {}"

        return command

    def _parse_kicks(self, app_stdout: str) -> pd.DataFrame:
        """Parse the raw application output (stdout) into tracks from app."""
        try:
            parsed_output = [
                json.loads(s) for s in app_stdout.split("\n") if s.startswith("{")
            ]

            df_kick = pd.DataFrame(
                data={"kick": [0 for _ in range(len(self.timestamps))]},
                index=self.timestamps,
            )

            for frame_output in parsed_output:
                kick_start = frame_output["kick_start"]
                kick_stop = frame_output["frame"]
                kick_duration = kick_stop - kick_start + 1
                df_kick.iloc[kick_start - 1 : kick_stop] = np.ones((kick_duration, 1))
            return df_kick
        except Exception as e:
            print(e)

    def _calculate_kicks(
        self,
    ) -> pd.DataFrame:
        # shell=True it is needed to run python from virtual-env, otherwise standard python is run.
        app_out = self._get_app_results(shell=True)
        self._save_app_output(stdout=app_out)
        return self._parse_kicks(app_stdout=app_out)


class Label(InputABC):
    """Camera/Label based input.

    Args;
        recording_path: Path to the recording.
        radar_timestamps: Original radar timestamps (used for synchronization)
        config: Benchmarking configuration.
    """

    _TIMESTAMP_FILENAME = "label_timestamp.csv"  # reference timestamps

    def __init__(
        self,
        recording_path: Path,
        config: BenchmarkConfig,
        radar_timestamps: pd.DatetimeIndex,
    ) -> None:
        self._radar_timestamps: pd.DatetimeIndex = radar_timestamps
        super().__init__(recording_path=recording_path, config=config)

    @property
    def name(self) -> str:
        """Display name/prefix in plots.

        Returns:
            Prefix/name.
        """
        return "Ground Truth"

    def _load_timestamps(self) -> pd.DatetimeIndex:
        """Load the timestamps for the radar recording.

        Returns:
            Datetime index with the absolute timestamps.
        """
        timestamps_file = self._recording_path / self._TIMESTAMP_FILENAME
        if not timestamps_file.exists():  # Fallback for legacy ifxdaq format
            return pd.DatetimeIndex([])
        return load_timestamps(timestamps_file)

    def _calculate_kicks(
        self,
    ) -> pd.DataFrame:
        label_file = self._recording_path / "kick.json"
        if (
            not label_file.exists()
        ):  # If no label file exists, we assume that the recording does not contain any kick.
            df_kick = pd.DataFrame(
                {"kick": [0 for _ in range(len(self._radar_timestamps))]}
            )
            df_kick.set_index(self._radar_timestamps, inplace=True)

            return df_kick

        df_kick = pd.DataFrame(
            data=read_json(label_file), index=self._load_timestamps()
        )

        # Synchronize with radar timestamps, so that we have a label for each radar frame
        df_kick = df_kick.reindex(self._radar_timestamps, method="nearest")

        return df_kick[["kick"]]


@pytest.fixture(scope="package")
def input_reference(
    radar_recording: Path,
    config: BenchmarkConfig,
    radar_timestamps: pd.DatetimeIndex,
    stdout_dir,
) -> InputABC:
    """Fixture for the reference input.

    Args:
        radar_recording: [pytest.fixture] Path to the radar recording.
        config: [pytest.fixture] Benchmarking configuration.
        radar_timestamps: [pytest.fixture] Radar timestamps.
        stdout_dir: [pytest.fixture] Base directory where results are saved.

    Returns:
        Instance of benchmarking input object (algorithm or label).
    """
    return _get_input(
        input_type="gt",
        radar_recording=radar_recording,
        config=config,
        stdout_dir=stdout_dir,
        radar_timestamps=radar_timestamps,
    )


@pytest.fixture(scope="package")
def input_app(
    request: FixtureRequest,
    radar_recording: Path,
    radar_timestamps: pd.DatetimeIndex,
    config: BenchmarkConfig,
    stdout_dir: Path,
) -> InputABC:
    """Fixture for the application input.

    Args:
        request: Special fixture providing information of the requesting test function.
        radar_recording: [pytest.fixture] Path to the radar recording.
        radar_timestamps: [pytest.fixture] Radar timestamps.
        config: [pytest.fixture] Benchmarking configuration.
        stdout_dir: [pytest.fixture] Base directory where results are saved.

    Returns:
        Instance of benchmarking input object (algorithm or label).
    """
    app = request.config.getoption("--app")
    return _get_input(
        input_type=app,
        radar_recording=radar_recording,
        radar_timestamps=radar_timestamps,
        config=config,
        stdout_dir=stdout_dir,
    )


def _get_input(
    input_type: str,
    radar_recording: Path,
    config: BenchmarkConfig,
    stdout_dir: Path,
    radar_timestamps: Optional[pd.DatetimeIndex] = None,
) -> InputABC:
    if input_type.lower() == "matlab":
        inp = MatlabAlgorithm(
            recording_path=radar_recording, config=config, stdout_dir=stdout_dir
        )
    elif input_type.lower() == "c":
        inp = CAlgorithm(
            recording_path=radar_recording, config=config, stdout_dir=stdout_dir
        )
    elif input_type.lower() == "python":
        inp = PythonMLAlgo(
            recording_path=radar_recording, config=config, stdout_dir=stdout_dir
        )
    else:
        label_dir = next(radar_recording.parent.glob("Labels_*"))
        inp = Label(
            recording_path=label_dir, radar_timestamps=radar_timestamps, config=config
        )
    return inp
