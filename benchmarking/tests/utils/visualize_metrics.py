"""Module for metric visualizations."""
from pathlib import Path
from typing import List, Optional

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

__all__ = ["visualization_metrics", "visualization_box_plot"]


def _split_given_size(a: pd.DataFrame, chunk_size: int) -> List:
    """Split data frame into chunks and keep the reminder."""
    return np.split(a, np.arange(chunk_size, len(a), chunk_size))


def visualization_metrics(
    visualization_dir: Path,
    data: pd.DataFrame,
    suffix: Optional[str] = None,
    chunk_size: int = 50,
) -> List[Path]:
    """Plot metrics overview for multiple recordings.

    Args:
        visualization_dir: Path to save images.
        data: Data to plot.
        suffix: Additional image suffix.
        chunk_size: Maximum number of recordings in each plot.

    Returns:
        List of path to files.
    """
    metrics = ["precision", "recall", "f1_score"]
    output_files = []
    for i, data_split in enumerate(_split_given_size(data, chunk_size)):
        fig = plt.figure(figsize=(12, 12), constrained_layout=True)
        subplots = [411, 412, 413]
        for subplot, metric in zip(subplots, metrics):
            plt.subplot(subplot)
            avg = np.round(np.mean(data[metric]), decimals=3)
            median = np.round(np.median(data[metric]), decimals=3)
            plt.bar(range(len(data_split.index)), data_split[metric])
            plt.title(f"{metric}, average: {avg}, median: {median}")
            plt.axhline(avg, color="r", alpha=0.4, label="Average")
            plt.axhline(median, color="orange", alpha=0.4, label="Median")
            plt.xticks(
                range(chunk_size),
                list(data_split.index) + [""] * (chunk_size - len(data_split.index)),
                rotation="vertical",
            )
            plt.tick_params(labelbottom=False)
            plt.legend(bbox_to_anchor=(1.02, 1), loc="upper left", borderaxespad=0.0)
        plt.tick_params(labelbottom=True)

        file_name = f"overview_metrics_{suffix}" if suffix else "overview_metrics"
        output_file = visualization_dir / f"{file_name}_part{i}.jpg"
        fig.savefig(output_file)
        plt.close(fig)
        output_files.append(output_file)
    return output_files


def visualization_box_plot(
    visualization_dir: Path, data: pd.DataFrame, suffix: Optional[str] = None
) -> Path:
    """Visualize results as boxplot diagram.

    Args:
        visualization_dir: Path to save images.
        data: Data to plot.
        suffix: Additional image suffix.

    Returns:
        Path to file.
    """
    fig = plt.figure(figsize=(12, 8))

    plt.boxplot(
        [data["precision"], data["recall"], data["f1_score"]],
        labels=["precision", "recall", "f1_score"],
        showmeans=True,
    )
    title_string = (
        f"Overview of {suffix} recordings" if suffix else "Overview of all recordings"
    )
    plt.title(title_string)
    file_name = f"overview_boxplot_{suffix}" if suffix else "overview_boxplot"
    output_file = visualization_dir / f"{file_name}.jpg"
    fig.savefig(output_file)
    plt.close(fig)
    return output_file
