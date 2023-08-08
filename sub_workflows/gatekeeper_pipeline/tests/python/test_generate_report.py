import json
import os
import pytest

from lib.generate_report import report


def test_generate_json_report(kraken_report, output_filepath):
    """ "Should generate a json report"""
    kraken_keys = ["unclassified", "Mycobacteriaceae"]

    report(kraken_report, output_filepath, kraken_keys)
    assert os.path.exists(output_filepath)


def test_json_report_has_kraken2_name_keys(kraken_report, output_filepath):
    """Json should have the input kraken2 list as keys"""
    kraken_keys = ["unclassified", "classified", "Bacteria", "Mycobacteriaceae", "Homo sapiens"]

    report(kraken_report, output_filepath, ["unclassified", "root", "Bacteria", "Mycobacteriaceae", "Homo sapiens"])
    with open(output_filepath) as output_json:
        report_json = json.load(output_json)

    kraken2_string_keys = set(map(str, kraken_keys))
    report_string_keys = set(list(report_json.keys()))

    assert kraken2_string_keys == report_string_keys


def test_json_keys_0_if_key_not_found_in_kraken2_report(local_report, output_filepath):
    """Json value should be 0 if key not found in the kraken2 report"""
    kraken_report = local_report
    with open(kraken_report, "w") as report_file:
        report_file.write(
            """0.00	38	38	U	0	unclassified
100.00	1062630	0	R	1	root
100.00	1062630	3	R1	131567	  cellular organisms
100.00	1062625	10	D	2	    Bacteria
 99.99	1062604	0	D1	1783272	      Terrabacteria group
 99.99	1062604	0	P	201174	        Actinomycetota
 99.99	1062604	13	C	1760	          Actinomycetes
 99.99	1062575	40	O	85007	            Mycobacteriales
 99.99	1062524	1163	F	1762	              Mycobacteriaceae
 99.87	1061307	467	G	1866885	                Mycolicibacterium
 99.82	1060770	1060770	S	39695	                  Mycolicibacterium tokaiense
  0.00	23	23	S	319707	                  Mycolicibacterium aubagnense
  0.00	2	0	D	2759	    Eukaryota"""
        )

    kraken_keys = ["unclassified", "root", "Bacteria", "Mycobacteriaceae", "Homo sapiens"]

    report(kraken_report, output_filepath, kraken_keys)

    with open(output_filepath) as output_json:
        report_json = json.load(
            output_json,
            object_hook=lambda obj: {
                k: int(v) if isinstance(v, str) and v.isdigit() else v
                for k, v in obj.items()
            },
        )
    print(report_json)
    assert report_json.get("unclassified") == 38
    assert report_json.get("classified") == 1062630
    assert report_json.get("Bacteria") == 1062625
    assert report_json.get("Mycobacteriaceae") == 1062524
    assert report_json.get("Homo sapiens") == 0


def test_error_if_report_file_does_not_exist(nonexistent_file):
    """ "Should rase FileNotFoundError if kraken report does not exist"""
    kraken_report = nonexistent_file
    kraken_keys = []
    output_filepath = "results/kraken2_filter_report.json"
    with pytest.raises(FileNotFoundError):
        report(kraken_report, output_filepath, kraken_keys)


def test_error_if_out_dir_does_not_exist(kraken_report, nonexistent_dir):
    """ "Should rase FileNotFoundError if path to output report does not exist"""
    kraken_keys = []
    output_filepath = nonexistent_dir
    with pytest.raises(FileNotFoundError):
        report(kraken_report, output_filepath, kraken_keys)


def test_error_if_kraken_keys_is_not_list_type(kraken_report, output_filepath):
    """ "Should rase TypeError if Kraken2 keys is not a list"""
    kraken_keys = "Mycobacteriaceae"
    with pytest.raises(TypeError):
        report(kraken_report, output_filepath, kraken_keys)


def test_error_if_kraken_key_item_is_not_string_type(kraken_report, output_filepath):
    """ "Should rase TypeError if there is at least a  Kraken2 list value that is not a string"""
    kraken_keys = ["root", 9606]
    with pytest.raises(TypeError):
        report(kraken_report, output_filepath, kraken_keys)


def test_error_if_kraken_file_has_wrong_number_columns(
    kraken_report_no_cols, output_filepath
):
    """ "Should rase FileNotFoundError if kraken report file has wrong number of columns"""
    kraken_report = kraken_report_no_cols
    kraken_keys = ["unclassified", "Mycobacteriaceae"]
    with pytest.raises(ValueError):
        report(kraken_report, output_filepath, kraken_keys)
