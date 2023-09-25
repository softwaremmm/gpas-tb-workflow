import copy
import json
import os


def report(report_filepath, output_filepath, kraken2_keys):
    """
    Check report file, output directory, and Kraken2 taxids.

    Args:
        report_filepath (str): Path to the report file.
        output_filepath (str): Path to the output file.
        kraken2_keys (list): List of Kraken2 names.

    Raises:
        FileNotFoundError: If the report file or output directory does not exist.
        TypeError: If the kraken2_keys argument is not a valid list of strings.

    """

    if not (os.path.exists(report_filepath)):
        raise FileNotFoundError("ERROR: " + report_filepath + "does not exist")

    folder_path = os.path.dirname(output_filepath)

    if os.sep in output_filepath and not os.path.isdir(folder_path):
        raise FileNotFoundError("ERROR: " + output_filepath + "does not exist")

    if not isinstance(kraken2_keys, list) or not all(isinstance(x, str) for x in kraken2_keys):
        raise TypeError("ERROR: the kraken2_keys is not a valid list of Kraken2 names")

    # Column 5 is Kraken2 species names
    kraken_name_column = 5
    kraken_reads_count_column = 1

    output_dict = dict.fromkeys(kraken2_keys, 0)

    with open(report_filepath, 'r') as file:
        lines = file.readlines()
        for line in lines:
            row = line.strip().split('\t')
            if len(row) < 6:
                raise ValueError("Invalid Kraken2 report: file does not have minimum number of columns")

            index_key = row[kraken_name_column].strip()
            for key in kraken2_keys:
                if index_key == str(key):
                    output_dict[key] = int(row[kraken_reads_count_column])
                    break

    # Root is the name for all classified reads, it has been requested to renamed to 'classified'
    if "root" in kraken2_keys:
        output_dict['classified'] = copy.deepcopy(output_dict["root"])
        del output_dict["root"]

    with open(output_filepath, "w") as fp:
        json.dump(output_dict, fp, indent=4, default=str)
