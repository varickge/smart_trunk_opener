"""Tests to check output against metrics."""
from typing import Dict

from ..utils.cfg import BenchmarkConfig


def test_precision(metrics: Dict[str, float], config: BenchmarkConfig) -> None:
    """Test if precision is above the threshold.

    Args:
        metrics: [pytest.fixture] Precalculated metrics.
        config: [pytest.fixture] Benchmarking config values.

    """
    assert metrics["precision"] > config.precision_threshold


def test_recall(metrics: Dict[str, float], config: BenchmarkConfig) -> None:
    """Test if recall is above the threshold.

    Args:
        metrics: [pytest.fixture] Precalculated metrics.
        config: [pytest.fixture] Benchmarking config values.

    """
    assert metrics["recall"] > config.precision_threshold


def test_precision_and_recall(
    metrics: Dict[str, float], config: BenchmarkConfig
) -> None:
    """Test if precision and recall is above the threshold.

    Args:
        metrics: [pytest.fixture] Precalculated metrics.
        config: [pytest.fixture] Benchmarking config values.

    """
    assert metrics["recall"] > config.precision_threshold
    assert metrics["precision"] > config.precision_threshold
