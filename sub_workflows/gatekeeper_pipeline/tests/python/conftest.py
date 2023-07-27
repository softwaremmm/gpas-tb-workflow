import pytest

@pytest.fixture
def kraken_report():
    return "tests/python/aux/kraken_report.txt"

@pytest.fixture
def output_filepath(tmp_path):
    return str(tmp_path / "kraken2_filter_report.json")

@pytest.fixture
def local_report(tmp_path):
    return str(tmp_path / "results.txt")

@pytest.fixture
def nonexistent_file():
    return "nonexistent_file.txt"

@pytest.fixture
def nonexistent_dir():
    return "nonexistent/dir"

@pytest.fixture
def kraken_report_no_cols():
    return "tests/python/aux/kraken_report_no_number_columns.txt"