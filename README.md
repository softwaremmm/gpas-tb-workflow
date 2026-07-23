# gpas-myco

## Introduction

This repository that contains the core logic for processing mycobacterial sequencing data. It outputs [JSON files](https://github.com/softwaremmm/summary_pipeline#glossary--definitions) containing data on species, lineage, and AMR.

The workflow consist of multiple steps:

| Step | Main Software | Notes | Repository(ies) |
| --- | --- | --- | --- |
| Gatekeeper | kraken2 | Quality checking and read filtering | [gatekeeper_pipeline](https://github.com/softwaremmm/gatekeeper_pipeline) |
| Speciation | minimap2, samtools, mykrobe | Competitive Mapping and Lineage Calling (mykrobe) | [lineagecalling_pipeline](https://github.com/softwaremmm/lineagecalling_pipeline) [competitivemapping_pipeline](https://github.com/softwaremmm/competitivemapping_pipeline) |
| Assembly | clockwork, minos, rundial | Variant calling | [clockwork_pipeline](https://github.com/softwaremmm/clockwork_pipeline) [rundial](https://github.com/softwaremmm/rundial) |
| Resistance Prediction | gnomonicus | Variants, mutations and effects of a specified (minos) VCF file | [tb-predict-pipeline](https://github.com/softwaremmm/tb-predict-pipeline) |
| Relatedness | Find Neighbour 5 | SNP distance calculation | [fn5_pipeline](https://github.com/softwaremmm/fn5_pipeline) |
| Summary | *None* | Summarises outputs into a JSON file | [summary_pipeline](https://github.com/softwaremmm/summary_pipeline) |

A machine readable list of the repositories required to run the full pipeline is [included in this repository](./pipeline_versions.json). Useful technical details, e.g. thresholds, may be found in the supplementary information to this paper [Characterizing the performance of an antibiotic resistance prediction tool, gnomonicus, using a diverse test set of 2,663 Mycobacterium tuberculosis samples](https://pmc.ncbi.nlm.nih.gov/articles/PMC12705075/).

Pipeline [development and maintenance](./development.md) is conducted by an internal team. We can't accept Pull Requests at the moment.
If you find a bug or have a feature suggestion, or have difficulty running the code please raise an [Issue](https://github.com/softwaremmm/gpas-tb-workflow/issues). Try and provide as much detail as possible, and be nice!

## Prerequisites

- Linux or WSL2 (we use Ubuntu)
- make (usually included with Linux)
- [jq](https://jqlang.org/download/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to make it easier to download reference data
- [Docker](https://www.docker.com/get-started/)
- [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html)
- Reference data
- Mycobacterial read data

## Installation

Doing this is going to require some knowledge of the command line and Nextflow. The code is intended to run on a Kubernetes cluster, and this complicates local running somewhat. We don't recommend trying to run this code on a non-local Executor.
You will first need to clone this repository `https://github.com/softwaremmm/gpas-tb-workflow.git` and `cd gpas-tb-workflow`.
We recommand running `git checkout 2.5.3` to fix the version being run to an [official release](CHANGELOG.md). `2.5.3` is the earliest version that will install neatly.

`make` is used to simplify installation. It will:
- Clone all of the repositories needed for the full pipeline
- Create a directory structure to hold reference data
- Download the necessary reference data. There's over 1GB of this, plus the kraken2 index.

Use `make install-small-kraken` to install with an 8GB kraken2 index or `make install-big-kraken` to install with the full kraken2 index used in production. The computer used to run the software needs RAM in excess of the kraken2 index size.

This pipeline is known to run with Nextflow `24.10.4`, may work with `25` and it known to not work with version `26`. The above install commands will set an "environment variable" to
make Nextflow run in a compatible version. You can run `make set-nextflow-version` to fix the version in subsequent sessions. Alternatively, for a permanant fix,
 you can add a line to your `.bashrc` or `.zshrc` something like:

```{bash}
echo 'export NXF_VER=24.10.4' >> ~/.bashrc
```

or

```{zsh}
echo 'export NXF_VER=24.10.4' >> ~/.zshrc
```

If you don't have the known compatible version, you will see a warning like this:

```
WARN: Nextflow version 26.04.6 does not match version required by pipeline: 24.10.4 -- execution will continue, but things might break!
```

If compatibility with more recent versions of nextflow is important to you, please [raise an issue](https://github.com/softwaremmm/gpas-tb-workflow/issues).

## Running the Pipeline

The pipeline has two Nextflow profiles, associated with running on a laptop or VM (`local`) or on Kubernetes (`kubernetes`).
There are two ways of specifying input data - one is a conventional Nextflow
approach, the other mimics the way in which input data is presented to the pipeline on Kubernetes.
**For development the conventional approach is usually more useful.**

Input and output directories are specified as shown below, which supports running batches of samples. Note that the `--outdir` must be absolute. When running locally `-profile local` should be used.

```bash
nextflow run . -profile local --sample_input_dir <path/to/input_dir> --outdir </abs/path/to/output_dir> --seq_platform <illumina/ont>
```

By default it will look for files in the input directory based on the following params:
- `params.input_paired_suffix = "*_{1,2}.fastq.gz"`
- `params.input_single_suffix = "*.fastq.gz"`
but these can be overriden. Note that file ending must be `.fastq.gz` or `.fq.gz`.

```bash
nextflow run ... --input_paired_suffix "tb_sample*_{1,2}.fq.gz"
```

You can also use `--publish_dir <directory>` to save all process outputs to provided directory. This is rarely needed.

You may need to reduce memory requirements for kraken2 if using smaller index e.g.

```bash
--kraken2_mem 9GB
```

If you're looking for data to try it out with, you could use `make get-example-inputs` to download some files from the ENA.

A concrete example of a command to run the pipeline with this data would then be:

```bash
nextflow run . -profile local --sample_input_dir data/inputs/illumina --outdir `pwd`/output --seq_platform illumina --kraken2_mem 9GB
```

(The `` `pwd`/output `` is a trick to get round the need for an absolute path)

### Specifying clair3 Model (ONT Only)

To specify a clair3 model for ONT variant calling, set the param `basecalling_model` to a value from this list https://github.com/softwaremmm/rundial/blob/develop/src/dorado_to_clair3_model.rs (left side).
If this parameter is not specified, `bcftools`, the default, is used for variant calling.
