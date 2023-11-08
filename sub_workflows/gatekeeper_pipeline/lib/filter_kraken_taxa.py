"""Script uses kraken outputs to filter fasta/fastq files based on desired taxa.

By default it will simply filter for the specified --taxid.
But if --include-children is set then, a read assigned to any sublevel is also included.
Can also provide taxa to --exclude. The taxa to keep or exclude are applied top down,
so that specific rulings trump the general.

Example: --taxid 1 (root) 83332 (TB H37Rv)  --exclude 1773 (TB).
This will start by including everything from root, but then remove all TB, 
with the exception of TB H37Rv its subspecies.

Note: To inlude unclassified than must include 0 as one of the taxids."""
import argparse
import subprocess
import sys
import tempfile
from typing import Self

import pandas as pd


def flatten(list_of_lists: list[list]) -> list:
    """Flattens list of lists to a single list."""
    return [item for sublist in list_of_lists for item in sublist]


class Tree:
    """Tree data structure for storing taxa data"""

    def __init__(
        self: Self,
        taxid: int,
        depth: int,
        level_code: str,
        name: str,
        parent: Self | None = None,
    ):
        """Create Kraken taxa tree

        Args:
            taxid (int): kraken taxa id
            depth (int): hierachy depth of node
            level_code (str): kraken taxa code
            name (str): taxa level name
            parent (bool, optional): Parent node in tree. Defaults to None.
        """
        self.taxid = taxid
        self.depth = int(depth)
        self.level_code = level_code
        self.name = name
        self.children: list[Self] = []
        self.parent = parent

    def __str__(self):
        s = " " * self.depth + f"{self.taxid} ({self.name})"
        for c in self.children:
            s += "\n" + str(c)
        return s

    def add_child(self: Self, node: Self):
        """Make node a child of this node

        Args:
            node (Tree): Node to add as child
        """
        assert isinstance(node, Tree)
        self.children.append(node)
        node.parent = self

    def create_child(
        self: Self, taxid: int, depth: int, level_code: str, name: str
    ) -> Self:
        """Make a new node and set it as a child of this node

        Args:
            taxid (int): kraken taxa id of child node
            depth (int): hierachy depth of child node
            level_code (str): kraken taxa code
            name (str): taxa level name

        Returns:
            Tree: Child node
        """
        child = Tree(taxid, depth, level_code, name, self)
        self.children.append(child)
        return child

    def to_list(self: Self) -> list[Self]:
        """Return list all nodes in subtree rooted at this node"""
        return [self] + flatten([c.to_list() for c in self.children])


def report_to_tree(report: str) -> Tree:
    """Convert kraken report to a tree object

    Args:
        report (str): File path of kraken report

    Returns:
        Tree: root of kraken report hierachy
    """
    root = Tree(1, 0, "R", "root")
    prev_node = root

    with open(report, "r", encoding="utf8") as file:
        for line in file:
            values = line.strip().split("\t")
            if len(values) != 6:
                raise ValueError(
                    "Check kraken report format. Expect 6 values: "
                    + "percentage, reads (include sublevel), reads, level code, taxid, name"
                )
            _, _, _, level, taxid, spaced_name = values
            taxid = int(taxid)
            name = spaced_name.lstrip(" ")
            depth = int((len(spaced_name) - len(name)) / 2)
            if taxid in [0, 1]:
                continue

            while prev_node is not None and prev_node.depth >= depth:
                prev_node = prev_node.parent
            if prev_node is None:
                raise ValueError("Error prev_node has value None.")
            prev_node = prev_node.create_child(taxid, depth, level, name)

    return root


def get_read_ids(
    kraken_file: str,
    kraken_report: str,
    input_taxids: list,
    include_children: bool,
    input_exclude: list,
) -> pd.Series:
    """Returns read ids from kraken file based on requested taxa.

    Args:
        kraken_file (str): path to main kraken output
        kraken_report (str): path to kraken report
        input_taxids (list): list of kraken taxa ids
        include_children (bool): include reads with subtaxa of input_taxids
        input_exclude (list): list of kraken taxa ids to exclude

    Returns:
        pd.Series: all read ids matching criteria
    """
    taxids = {int(id) for id in input_taxids}
    exclude = {int(id) for id in input_exclude}

    if include_children:
        # Only in this case do we need to apply complex logic
        k_tree = report_to_tree(kraken_report)
        key_nodes = []

        for node in k_tree.to_list():
            if node.taxid in taxids:
                key_nodes.append((node, True, node.depth))
            elif node.taxid in exclude:
                key_nodes.append((node, False, node.depth))

        key_nodes.sort(key=lambda x: x[2])

        all_included_taxa = set()
        for node, include, _ in key_nodes:
            node_set = {c.taxid for c in node.to_list()}
            if include:
                all_included_taxa = all_included_taxa | node_set
            else:
                all_included_taxa = all_included_taxa - node_set

        # taxid 0 (unclassified) is added by this step if desired
        taxids = all_included_taxa | taxids

    colnames = ["classified", "seq_id", "taxid", "length", "match_data"]
    classifications = pd.read_csv(kraken_file, sep="\t", names=colnames)
    filtered = classifications.query("taxid in @taxids")
    # seq_ids are kept as strings as nothing in fasta/q format inforces ints
    read_ids = filtered["seq_id"].astype(str)
    return read_ids


def filter_by_taxa(
    reads1: str,
    reads2: str,
    kraken_file: str,
    kraken_report: str,
    taxids: list,
    include_children: bool,
    exclude: list,
    output1: str,
    output2: str,
):
    """_summary_

    Args:
        reads1 (str): path to fasta/q input file
        reads2 (str): path to second fasta/fastq if using paired reads
        kraken_file (str): path to main kraken output
        kraken_report (str): path to kraken report
        input_taxids (list): list of kraken taxa ids
        include_children (bool): include reads with subtaxa of input_taxids
        input_exclude (list): list of kraken taxa ids to exclude
        output1 (str): path for fasta/q output
        output2 (str): path for second fasta/q output if using paired reads
    """
    read_ids = get_read_ids(kraken_file, kraken_report, taxids, include_children, exclude)

    # read ids are just the id, but paired fastq files may append /1 or /2
    # This causes problems for seqtk as it no longer matches!

    paired_read_ids = pd.concat([read_ids, read_ids + "/1", read_ids + "/2"])

    # Use seqtk (MIT license) to filter the fasta/fastq files

    with tempfile.NamedTemporaryFile(mode="w") as temp_file:
        paired_read_ids.to_csv(temp_file.name, index=False, header=False)

        seqtk_command1 = f"seqtk subseq {reads1} {temp_file.name} > {output1}"
        subprocess.run(seqtk_command1, shell=True, check=False)
        if reads2 != "":
            seqtk_command2 = f"seqtk subseq {reads2} {temp_file.name} > {output2}"
            subprocess.run(seqtk_command2, shell=True, check=False)


def get_arguments():
    """Get program arguments with argparse"""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-k", dest="kraken_file", required=True, help="Main output file from kraken."
    )
    parser.add_argument(
        "-r",
        dest="kraken_report",
        required=True,
        help="Report file from kraken with hierachy info.",
    )
    parser.add_argument(
        "-s1",
        dest="reads1",
        required=True,
        help="Reads to be filtered by taxid. Can be fasta/fastq.",
    )
    parser.add_argument(
        "-s2", dest="reads2", default="", help="Used when reads are paired."
    )
    parser.add_argument(
        "-o1",
        dest="output1",
        required=True,
        help="Output fasta/fastq with desired taxid.",
    )
    parser.add_argument(
        "-o2", dest="output2", default="", help="Used when reads are paired"
    )
    parser.add_argument(
        "-t",
        "--taxids",
        dest="taxids",
        required=True,
        nargs="+",
        help="List of taxid of interest. Space separated.",
    )
    parser.add_argument(
        "-c",
        "--include-children",
        dest="children",
        action="store_true",
        default=False,
        help="Include reads specified to a sublevel of desired taxid.",
    )
    parser.add_argument(
        "-x",
        "--exclude",
        dest="exclude",
        nargs="+",
        default="",
        help="List of taxid to exclude. Space separated. Only relevant if including children.",
    )
    args = parser.parse_args()

    if args.reads2 != "" and args.output2 == "":
        print(
            f"Error. If reads2 provided ({args.reads2}), then output2 should also be given."
        )
        sys.exit(1)

    return args


def main():
    """Main entry to script"""
    args = get_arguments()

    filter_by_taxa(
        args.reads1,
        args.reads2,
        args.kraken_file,
        args.kraken_report,
        args.taxids,
        args.children,
        args.exclude,
        args.output1,
        args.output2,
    )


if __name__ == "__main__":
    main()
