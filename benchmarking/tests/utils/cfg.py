"""Utils for config handling."""
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from omegaconf import OmegaConf


@dataclass
class BenchmarkConfig:
    """Provide configuration values for benchmarking."""

    precision_threshold: float

    @classmethod
    def from_config_file(cls, file: Path):
        """Load configuration file.

        Args:
            file: Path to .yaml file.

        Returns:
            BenchmarkingConfig with values from file.
        """
        config = OmegaConf.load(file)
        config = OmegaConf.merge(cls, config)
        return cls(**config)
