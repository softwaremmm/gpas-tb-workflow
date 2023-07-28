from summary import summarise
from pathlib import Path


def test_regression(
    gatekeeper_report: Path,
    competitivemapping_report: Path,
    mykrobe_report: Path,
    gnomonicus: Path,
    expected_output: Path,
):
    summary = summarise.create_summary(
        gatekeeper_report, competitivemapping_report, mykrobe_report, gnomonicus
    )

    expected_summary = summarise.read_json_file(expected_output, False)

    assert summary == expected_summary
