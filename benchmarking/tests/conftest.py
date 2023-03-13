import json
import re
import shutil
from pathlib import Path
from typing import Any, Dict, List

import pytest
import yaml
from pytest_harvest import get_session_results_df, is_main_process
from xdist.scheduler import LoadScopeScheduling

from .fixtures.benchmarking_input import *
from .fixtures.cfg import *
from .fixtures.metric import *
from .fixtures.utils import *
from .fixtures.visualize import *
from .utils.git import get_git_branch, get_git_revision_short_hash
from .utils.report import (Report, add_group_mean_metrics_to_report,
                           add_mean_metrics_to_report,
                           add_recordings_to_report,
                           add_requirements_checks_to_report)
from .utils.visualize_metrics import (visualization_box_plot,
                                      visualization_metrics)

#####
# Commandline options
#####


def pytest_addoption(parser):
    """Add custom cmd line options.

    Options:
        --app: Select between C & Matlab application.
        --scope: Select the scope of the test cases. The scope for individual recordings is defined in recs.yaml.
        --matlab-path: Select custom path to matlab app.
        --report-tracks: If flag is set, the report will include track metrics and plots.
    """
    parser.addoption(
        "--scope",
        action="store",
        default="debug",
        type=str,
        choices=["debug", "all"],
        help="Scope of the tests. The scope for individual recordings is defined in recs.yaml.",
    )
    parser.addoption(
        "--matlab-path",
        action="store",
        default=None,
        type=str,
        help="Path to algo-segmentation repo. If none is given, it is assumed to be alongside the smart-tv repo.",
    )
    parser.addoption(
        "--app",
        action="store",
        default="c",
        type=str,
        choices=["c", "matlab", "python"],
        help="Application to use.",
    )


def pytest_configure() -> None:
    """Clean up old artifacts."""
    shutil.rmtree("artifacts", ignore_errors=True)


@pytest.fixture(scope="session")
def scope(request) -> str:
    """Scope of the tests. The scope for individual recordings is defined in recs.yaml."""
    return request.config.getoption("--scope")


#####
# Test generation / distribution
#####


def load_recordings() -> List[Dict[str, Any]]:
    """Generate dynamically tests based on a list of recordings (-> recs.yaml file).

    1. Load the file with the recordings.
    2. Parametrize the root fixture with the resulting mapping of recordings / options.

    This will run all tests inside the package with each recording in the configuration file.
    """
    with open(Path(__file__).parents[1] / "recs.yaml", "r") as file:
        recordings = yaml.safe_load(file)
    return [(name, metadata) for name, metadata in recordings.items()]


def extract_recording(nodeid: str) -> List[str]:
    """Extract the recording (e.g. `20211104/recording_2021_11_04_16_13_42/RadarIfxAvian_01`) from a test node id."""
    params = []
    match = re.search(
        "(\\w+)/recording_(\\d+)_(\\d+)_(\\d+)_(\\d+)_(\\d+)_(\\d+)/RadarIfxAvian_(\\d+)",
        nodeid,
    )
    if match:
        params.append(match.group(0))
    return params


def pytest_collection_modifyitems(items: List[pytest.Item]) -> None:
    """Modify the list of all test cases.

    pytest executes all tests sequentially according to the passed list. We resort the list of test cases in-place
    to ensure that tests, which use time-consuming fixtures, are adjacent in the list.
    """
    items.sort(key=lambda item: extract_recording(item.nodeid))


class RecordingScheduling(LoadScopeScheduling):
    """Distribute tests based on recordings to different workers.

    This distributes the collected tests across all nodes so each node executes the tests for a specific recording,
    e.g.:

        - CPU0: Run all tests with recording_00
        - CPU1: Run all tests with recording_01

    All test cases are grouped along scopes, where one scope contains all tests that are executed based on a specific
    recording. A single scope will be executed completely on one node. By grouping all tests with the same recording on
    a common execution node, we prevent the repetitive execution of time-consuming fixtures (like running the app).
    After finishing all tests within one scope, a new scope will be assigned to the node. The time-consuming fixtures
    are extracted & defined in the function ``extract_params``.

    Warnings:
        This is just a workaround taken from
        https://github.com/pytest-dev/pytest-xdist/issues/18#issuecomment-392558907.
        It is likely that this will break at some point in time!
    """

    def _split_scope(self, nodeid: str) -> str:
        """Set the scope of a test case."""
        return "-".join(extract_recording(nodeid))


def pytest_xdist_make_scheduler(log, config):
    """Set the custom scheduler as distributor for the tests."""
    return RecordingScheduling(config, log)


#####
# Common fixtures
#####


@pytest.fixture(scope="package")
def tmp_path(tmp_path_factory) -> Path:
    """Overwrite default tmp_path with a package scoped fixture (+ clean-up functionality).

    Args:
        tmp_path_factory: [pytest.fixture] pytest factory.

    Yields:
        A temporary path that will be deleted on test teardown.
    """
    tmp_path = tmp_path_factory.mktemp("data")
    yield tmp_path
    shutil.rmtree(tmp_path)


@pytest.fixture(
    scope="package", params=load_recordings(), ids=[rec[0] for rec in load_recordings()]
)
def radar_recording(request, scope: str) -> Path:
    """[Root fixture] - Check if a recording should be tested in the current setup.

    Checks if:
        - the recording is in the current scope.
        - the recording exists.

    Otherwise, skip the recording.

    Args:
        request: [pytest.fixture] Built-in fixture.
        scope: [pytest.fixture] Scope of the current recording.

    Returns:
        Path to the recording under test.
    """
    rec_name, metadata = request.param
    if scope not in metadata["scope"]:
        pytest.skip(f"Recording not in scope.")

    recording_root = Path(__file__).parents[2] / "data"
    recording = recording_root / rec_name
    if not recording.exists():
        pytest.skip(f"No access to recording {recording}.")

    return recording


@pytest.fixture(scope="package")
def metadata(radar_recording: Path) -> Dict[str, str]:
    """Meta-data of the recording.

    Args:
        radar_recording: [pytest.fixture] Path to the radar recording.

    Returns:
        Meta data.
    """
    recording_root = radar_recording.parent
    meta_file = recording_root / "meta.json"
    with open(meta_file, "r", encoding="utf-8") as file:
        metadata = json.load(file)
    return metadata


@pytest.fixture(scope="package")
def scenario_id(metadata: Dict[str, str]) -> str:
    """Scenario ID of the recording.

    Args:
        metadata: [pytest.fixture]: Meta data of the recording.

    Returns:
        Scenario ID.
    """
    return metadata["scenario"]


def pytest_sessionfinish(session):
    """Gather all results.

    Gather results, process them and save as csv and images.
    """
    if is_main_process(session):
        git_info = (
            get_git_branch().replace("/", "_") + "_" + get_git_revision_short_hash()
        )
        report = Report(title="Benchmark report", project_name="SmartTrunk Opener")

        results = get_session_results_df(session)
        results.drop(["pytest_obj", "duration_ms"], axis=1, inplace=True)

        results.reset_index(level=0, inplace=True)

        results["recording"], _ = zip(*results["radar_recording_param"])
        results["test_id"] = results.apply(
            lambda x: re.sub(f"({x['recording']})(-?)", "", x["test_id"]), axis=1
        )

        metrics_only = results.drop(
            ["radar_recording_param", "status", "test_id", "visualization_dir"], axis=1
        )
        metrics_only.drop_duplicates(inplace=True)

        results.set_index("recording", inplace=True)
        results.to_csv(f"artifacts/results_all_{git_info}.csv")

        metrics_only.set_index("recording", inplace=True)
        metrics_only.to_csv(f"artifacts/results_metrics_{git_info}.csv")

        vis = [
            *visualization_metrics(Path("artifacts/images"), metrics_only),
            visualization_box_plot(Path("artifacts/images"), metrics_only),
        ]

        add_mean_metrics_to_report(
            results=metrics_only.copy(), visualizations=vis, report=report
        )
        add_requirements_checks_to_report(results=results.copy(), report=report)
        add_group_mean_metrics_to_report(results=metrics_only.copy(), report=report)
        add_recordings_to_report(results=metrics_only.copy(), report=report)

        report.output(f"artifacts/report_{git_info}.pdf")
