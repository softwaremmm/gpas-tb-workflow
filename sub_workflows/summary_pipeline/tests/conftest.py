import pytest
from pathlib import Path


@pytest.fixture
def gatekeeper_report() -> Path:
    return Path(
        "test_data/example_input/WTCHG_885333_73225298_1/2/gatekeeper_report.json"
    )


@pytest.fixture
def competitivemapping_report() -> Path:
    return Path(
        "test_data/example_input/WTCHG_885333_73225298_1/2/competitivemapping_report.json"
    )


@pytest.fixture
def mykrobe_report() -> Path:
    return Path("test_data/example_input/WTCHG_885333_73225298_1/2/mykrobe_report.json")


@pytest.fixture
def gnomonicus() -> Path:
    return "test_data/example_input/WTCHG_885333_73225298_1/2/tb/gnomonicus.json"


@pytest.fixture
def expected_output() -> Path:
    return "test_data/example_output/WTCHG_885333_73225298_1/2/Mega_2.json"
