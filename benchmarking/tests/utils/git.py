"""Utility functions for reading out git information."""
import subprocess


def get_git_revision_short_hash() -> str:
    """Get git revision.

    Returns:
        Current git revision as string.
    """
    return (
        subprocess.check_output(["git", "rev-parse", "--short", "HEAD"])
        .decode("ascii")
        .strip()
    )


def get_git_branch() -> str:
    """Get current git branch.

    Returns:
        Current branch.
    """
    return (
        subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"])
        .decode("ascii")
        .strip()
    )
