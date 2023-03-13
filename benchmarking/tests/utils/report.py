"""PDF report module."""
import getpass
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List

import fpdf.enums
import pandas as pd
from fpdf import FPDF
from ifxdaq.utils.common import read_json

from ..utils.git import get_git_branch, get_git_revision_short_hash

__all__ = [
    "PDF",
    "Report",
    "add_recordings_to_report",
    "add_requirements_checks_to_report",
    "add_mean_metrics_to_report",
    "add_group_mean_metrics_to_report",
]


class PDF(FPDF):
    """PDF document with custom header and footer."""

    def header(self) -> None:
        """Add logo and report string to each page."""
        # Rendering logo:
        self.image("../doc/media/infineon_logo.png", 10, 8, 33)
        self.image("../doc/media/intive_logo.png", 46, 12, 22)

        # Setting font: helvetica bold 15
        self.set_font("helvetica", "B", 15)
        # Moving cursor to the right:
        self.cell(120)
        # Printing title:
        self.cell(60, 10, "Benchmark report", border=1, align="C")
        # Performing a line break:
        self.ln(20)

    def footer(self) -> None:
        """Add page numbers."""
        # Position cursor at 1.5 cm from bottom:
        self.set_y(-15)
        # Setting font: helvetica italic 8
        self.set_font("helvetica", "I", 8)
        # Printing page number:
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")


class Report(PDF):
    """Class for creating pdf reports."""

    def __init__(self, title: str, project_name: str, **kwargs):
        super().__init__(**kwargs)
        self.set_title(title=title)
        self.set_author(getpass.getuser())
        self.add_title_page(title=title, project=project_name)
        self.add_explanations()

    def add_title_page(self, title: str, project: str) -> None:
        """Add a page with general information.

        Args:
            title: Title of the report.
            project: Project name.
        """
        self.add_page()
        self.set_font("Times", size=16)
        self.set_xy(10, 220)
        self.multi_cell(
            200,
            8,
            f"{title}\n"
            f"Project: {project}\n"
            f"Author: {getpass.getuser()}\n"
            f"GIT-Branch: {get_git_branch()}\n"
            f"GIT-Revision: {get_git_revision_short_hash()}\n"
            f"Created: {datetime.now()}",
            align="J",
        )

    def add_explanations(self) -> None:
        """Add guide for reading the metrics."""
        self.add_content_page(
            "Metric guide",
            table_col_widths=[],
            table_contents={},
            visualizations=["../doc/media/confusion_matrix.png"],
        )

    def add_new_metrics(self, visualizations: List) -> None:
        segmentations_txt_path = "./tests/utils/segmentations.txt"
        events_txt_path = "./tests/utils/events.txt"
        pie_chart_txt_path = "./tests/utils/pie_chart.txt"

        if len(visualizations):

            for visualization in visualizations:
                self.ln(4)

                if (isinstance(visualization, Path) is True) and (
                    "1matrix_conf.jpg" in visualization.name
                ):
                    self.add_page()
                    self.start_section("Confusion Matrix", level=1)
                    self.set_font("Times", size=14, style="B")
                    self.cell(0, 0, "Confusion Matrix")
                    self.image(visualization, x=0, y=35, w=self.w * 0.9)

                if (isinstance(visualization, Path) is True) and (
                    "2ModifiedConfusionMatrix.jpg" in visualization.name
                ):

                    with open(segmentations_txt_path, encoding="unicode_escape") as f:
                        segmentation_contents = f.read()

                    self.add_page()
                    self.start_section("Modified Confusion Matrix", level=1)
                    self.set_font("Times", size=14, style="B")
                    self.cell(0, 0, "Modified Confusion Matrix")
                    self.image(visualization, x=0, y=35, w=self.w * 0.9)
                    self.ln(142)
                    self.set_font("Times", size=12, style="B")
                    annot_text = segmentation_contents
                    self.set_font("Times", size=12, style="B")
                    self.multi_cell(0, 5, annot_text)

                if (isinstance(visualization, Path) is True) and (
                    "3frame_pie_charts.jpg" in visualization.name
                ):

                    with open(pie_chart_txt_path, encoding="unicode_escape") as f:
                        pie_chart_contents = f.read()

                    self.add_page()
                    self.start_section("Frame based Results", level=1)
                    self.set_font("Times", size=14, style="B")
                    self.cell(0, 0, "Frame based Results")
                    self.image(visualization, x=10, y=40, w=self.w * 0.9)
                    self.ln(82)
                    self.set_font("Times", size=12, style="B")
                    annot_text = pie_chart_contents
                    self.set_font("Times", size=12, style="B")
                    self.multi_cell(0, 5, annot_text)

                if (isinstance(visualization, Path) is True) and (
                    "5EAD.jpg" in visualization.name
                ):

                    with open(events_txt_path, encoding="unicode_escape") as f:
                        event_contents = f.read()

                    self.add_page()
                    self.start_section(
                        "Event based Results using Event Analysis Diagram (EAD)",
                        level=1,
                    )
                    self.set_font("Times", size=14, style="B")
                    self.cell(
                        0, 0, "Event based Results using Event Analysis Diagram (EAD)"
                    )
                    self.image(visualization, x=10, y=35, w=self.w * 0.9)
                    self.ln(40)
                    self.set_font("Times", size=12, style="B")
                    annot_text = event_contents
                    self.set_font("Times", size=12, style="B")
                    self.multi_cell(0, 5, annot_text)

    def add_content_page(
        self,
        section_name: str,
        table_col_widths: List,
        table_contents: Dict,
        visualizations: List,
    ) -> None:
        """Add on section with tables and visualizations.

        Args:
            section_name: Name of the section.
            table_col_widths: Column widths.
            table_contents: Dictionary with contents that will be displayed in a table.
            visualizations: List of visualizations (paths) that should be added to the section.
        """
        self.add_page()
        self.ln(8)
        self.start_section(section_name)
        self.set_font("Times", size=12, style="B")
        self.cell(0, 0, section_name)
        
        for table_name, table_content in table_contents.items():
            self.ln(8)
            if self.will_page_break(height=25):
                self.add_page()
            self.start_section(table_name, level=1)
            self.set_font("Times", size=9, style="B")
            self._add_table(
                headings=[table_name, "Value"],
                rows=table_content,
                col_widths=table_col_widths,
            )

        if len(visualizations):
            if table_contents:
                self.add_page()
                self.start_section("Visualizations", level=1)
                self.set_font("Times", size=14, style="B")
                self.cell(0, 0, "Visualizations")

            for visualization in visualizations:
                annot_text = ""
                self.ln(4)
                self.image(visualization, w=self.w * 0.9)

                if isinstance(visualization, Path):
                    if "Matlab-Algo_kicks_1.jpg" in visualization.name:
                        annot_text = f"The above plot represents labeled kicks (blue) and algorithm prediction (orange).\nThe algorithm output is shifted left by 21 frames."
                    elif "Matlab-Algo_kicks_0.jpg" in visualization.name:
                        annot_text = f"The above plot represents labeled kicks (blue) and algorithm prediction (orange), where one can see that there is a delay in algorithm prediction."

                    self.ln(8)
                    self.set_font("Times", size=12, style="B")
                    self.multi_cell(0, 4, annot_text)

    def _add_table(
        self, headings: List[str], rows: Dict, col_widths: List[int]
    ) -> None:
        """Create and fill table with information."""
        # self.set_fill_color(0, 122, 201)
        self.set_fill_color(171, 55, 122)

        self.set_text_color(255)
        # self.set_draw_color(239, 239, 239)
        self.set_draw_color(129, 33, 97)

        self.set_line_width(0.3)
        self.set_font(style="B")
        for col_width, heading in zip(col_widths, headings):
            self.cell(col_width, 7, heading, border=1, align="C", fill=True)
        self.ln()
        # Color and font restoration:
        # self.set_fill_color(236, 248, 255)
        self.set_fill_color(224, 235, 255)

        self.set_text_color(0)
        self.set_font()

        fill = False
        for i, (key, item) in enumerate(rows.items()):
            border = "LR" if i < len(rows.keys()) - 1 else "LRB"
            self.cell(
                col_widths[0],
                6 * (str(item).count("\n") + 1),
                key,
                border=border,
                align="L",
                fill=fill,
            )
            if isinstance(item, float):
                item = f"{item:.3f}"
            if len(str(item)) > 60:
                self.multi_cell(
                    col_widths[1],
                    6,
                    str(item),
                    border=border,
                    align="C",
                    fill=fill,
                    new_y=fpdf.enums.YPos.LAST,
                )
            else:
                self.cell(
                    col_widths[1], 6, str(item), border=border, align="C", fill=fill
                )
            self.ln()
            fill = not fill


def add_requirements_checks_to_report(results: pd.DataFrame, report: Report) -> None:
    """Average over requirement check and plot the results."""
    results = results[results["test_id"].str.contains("requirements")]
    results["status"] = results["status"].map({"failed": 0, "passed": 1})

    requirements_checks = results.groupby(["test_id"])

    results = requirements_checks.mean()
    results["n_recordings"] = requirements_checks.size()

    report.add_content_page(
        section_name="Requirements-Checks",
        table_col_widths=[120, 40],
        table_contents={"Requirements": results["status"]},
        visualizations=[],
    )


def add_mean_metrics_to_report(
    results: pd.DataFrame, visualizations, report: Report
) -> None:
    """Calculate the mean metrics over all recordings."""
    mean_metrics = results.mean(numeric_only=True)

    report.add_content_page(
        section_name="(Overall) metrics",
        table_col_widths=[120, 40],
        table_contents={"Metrics": mean_metrics.to_dict()},
        visualizations=visualizations,
    )


def add_group_mean_metrics_to_report(results: pd.DataFrame, report: Report) -> None:
    """Group recordings by scenario and add mean metrics."""
    results["group"] = results.index.to_series().str.split("/").str[1]
    grouped_df = results.groupby(by=["group"]).mean()

    report.add_content_page(
        section_name="Grouped metrics (environment)",
        table_col_widths=[120, 40],
        table_contents={
            name: metrics.to_dict() for name, metrics in grouped_df.iterrows()
        },
        visualizations=[],
    )

    results["group"] = results.index.to_series().str.split("\\\\").str[-3]
    grouped_df = results.groupby(by=["group"]).mean()
    report.add_content_page(
        section_name="Grouped metrics (scenario)",
        table_col_widths=[120, 40],
        table_contents={
            name: metrics.to_dict() for name, metrics in grouped_df.iterrows()
        },
        visualizations=[],
    )


def add_recordings_to_report(results: pd.DataFrame, report: Report) -> None:
    """Add individual section for each recording."""
    results.reset_index(inplace=True)
    results.drop_duplicates(subset=["recording"], inplace=True)
    results.set_index(["recording"], inplace=True)
    results.sort_index(inplace=True)

    for recording, row in results.iterrows():
        recording_root = (Path(os.getcwd()).parent / "data") / Path(
            str(recording)
        ).parent
        meta_file = recording_root / "meta.json"
        meta_data = read_json(meta_file)
        for key_, value in meta_data.items():
            if isinstance(value, str):
                new_value = ""
                counter = 0
                for word in value.split(" "):
                    if counter + len(word) < 60:
                        new_value += word + " "
                        counter += len(word)
                    else:
                        new_value += "\n"
                        new_value += word + " "
                        counter = len(word)
                meta_data[key_] = new_value

        report.add_content_page(
            section_name=str(recording),
            table_contents={"Meta-Information": meta_data, "Metrics": row.to_dict()},
            table_col_widths=[60, 100],
            visualizations=list(
                (Path("artifacts/images") / str(recording)).glob("*.jpg")
            ),
        )

        images = list(
            (Path("artifacts/images") / str(recording) / "new_metrics").glob("*.jpg")
        )
        report.add_new_metrics(images)
