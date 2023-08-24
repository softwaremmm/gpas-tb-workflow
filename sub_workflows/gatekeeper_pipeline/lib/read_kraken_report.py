import argparse

from generate_report import report

parser = argparse.ArgumentParser()
parser.add_argument('-filepath', help='path to kraken report')
parser.add_argument('-output_filepath', help='path to gatekeeper report')
parser.add_argument('-kraken2_names',  type=str, nargs='+', help='relevant kraken2_names to include on the report')

args = parser.parse_args()

"""
Created a json with the values for relevant Kraken2 keys
    -file: path to Kraken2 .txt report
    -output_filepath: filename for the json output
    -kraken2_names: list of relevant kraken2_keys to include on the report

"""
if __name__ == '__main__':
    report_filepath = args.filepath
    output_filepath = args.output_filepath
    kraken2_names = args.kraken2_names

    report(report_filepath, output_filepath, kraken2_names)

