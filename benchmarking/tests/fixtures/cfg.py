"""Fixtures to configure the test suite."""
import copy
from pathlib import Path
from typing import Dict

import pytest

from ..utils.cfg import BenchmarkConfig

__all__ = ["config"]


@pytest.fixture(scope="session")
def config() -> BenchmarkConfig:
    """Load configuration yaml and parse to dataclass."""
    path = Path(__file__).parents[2] / "cfg.yaml"
    return BenchmarkConfig.from_config_file(path)
