# gpas-tb-workflow

## Introduction

Known as the "myco pipeline" or "mycobacteria pipeline", this is the repository that contains the core logic for processing mycobacterial
sequencing data. The scientific aspects of the pipeline are detailled in Confluence 
[Mycobacteria Pipeline](https://eit-oxford.atlassian.net/wiki/spaces/Science/pages/37552142/Mycobacteria+Pipeline) and
[Multi Pipeline Tasks](https://eit-oxford.atlassian.net/wiki/spaces/Science/pages/37552153/Multi+Pipeline+Tasks).

For reference, here, the workflow consist of multiple steps:

| Step | Main Software | Notes | Repository(ies) |
| --- | --- | --- | --- |
| Gatekeeper | kraken2 | Quality checking and read filtering | [gatekeeper_pipeline](https://github.com/GlobalPathogenAnalysisService/gatekeeper_pipeline) |
| Speciation | minimap2, samtools, mykrobe | Competitive Mapping and Lineage Calling (mykrobe) | [lineagecalling_pipeline](https://github.com/GlobalPathogenAnalysisService/lineagecalling_pipeline) [competitivemapping_pipeline](https://github.com/GlobalPathogenAnalysisService/competitivemapping_pipeline) |
| Assembly | clockwork, minos, rundial | Variant calling | [clockwork_pipeline](https://github.com/GlobalPathogenAnalysisService/clockwork_pipeline) [rundial](https://github.com/GlobalPathogenAnalysisService/rundial) |
| Resistance Prediction | gnomonicus | Variants, mutations and effects of a specified (minos) VCF file | [tb-predict-pipeline](https://github.com/GlobalPathogenAnalysisService/tb-predict-pipeline) |
| Relatedness | Find Neighbour 5 | SNP distance calculation | [fn5_pipeline](https://github.com/GlobalPathogenAnalysisService/fn5_pipeline) |
| Summary | *None* | Summarises outputs into a JSON file | [summary_pipeline](https://github.com/GlobalPathogenAnalysisService/summary_pipeline) |

A machine readable list of the repositories required to run the full pipeline is [included in this repository](./includerepos.txt).

## The Pipeline in GPAS

Pipeline code is downloaded from an S3 compatible bucket just prior to run time, and then executed. The system
that gathers and places all necessary code in the bucket is the [Pipeline Build System](https://github.com/GlobalPathogenAnalysisService/pipeline-builder).
The Build System code is executed automatically by GitHub Actions ([Build Pipeline](.github/workflows/build-pipeline.yaml)) when a pull request to `main` or `develop` is
made, or a new tag is pushed. The [pathogena-releases](https://github.com/GlobalPathogenAnalysisService/pathogena-releases) repository
controls which version of the pipeline is deployed to what environment.

## Tags, Releases, and Committing

Use conventional commits. This is enforced with commitizen validate action and pre-commit hooks:

```bash
pre-commit install
```

This repo uses a standard gitflow approach, so changes should be first merged into develop and then released to main.
- In the develop branch semantic versioning is not used. Instead you can reference the commit hash to use it in a workflow.

To make a release:
- Create a release branch from `develop` named `release/a.b.c`
- In the release branch you can create release candidates with `cz bump a.b.c-rcX`. This also creates a tag, and when that tag is pushed, 
a build is made available for deployment to a GPAS environment.
- When release branch is ready:
    - Update the changelog, replacing the "New" heading with the version number "a.b.c"
    - Run `cz bump a.b.c --files-only` (won't create a tag).
    - Make a PR against `main` - this should be reviewed to confirm that the changelog is correct and the release process has been followed.
    - Merge the PR.
    - Create a release using the GitHub user interface. This ensures that the release tag points to the head of the `main` branch.
    - Rebase `develop` on `main` (or merge).

## Running the pipeline locally

### Prerequisites

- Docker
- [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html)
- Reference data
- Mycobacterial read data

You will also need to login to docker (`docker login lhr.ocir.io` and/or `sudo docker login lhr.ocir.io`) in order to be able to pull the containers.

### Reference data

The pipeline need substantial amounts of reference data in order to run. The most reliable way to ensure that all
reference data required is present is to copy the contents of the `knowledge` bucket from a GPAS development or
test environment into a a dir `data/knowledge` relative to the directory containing `main.nf`. If access to the bucket is problematic,
files could be obtained from a colleague. The provenance of the data is described on Confluence
[Reference Data Provenance](https://eit-oxford.atlassian.net/wiki/spaces/Science/pages/65863752/Reference+Data+Provenance).

You may need to reduce memory requirements for kraken2 if using smaller index e.g.

```
--kraken2_mem 5GB
```

> When running the pipeline, lack of a complete reference data set is often the reason for errors.

### Cloning Subworkflows for Development

In order to run the pipeline, you will need to clone subworkflows: `bash clone_sub_workflows.sh`.
However, **sub_workflows should not be committed due to size and version ambiguity**!
By default this script fetches the `main` branch of all defined subworkflows.
To fetch the latest releases instead, use `bash clone_sub_workflows.sh latest`.
To fetch different branches, change the values from `main` in `includerepos.csv`.

### Running the Pipeline Locally

The pipeline has two Nextflow profiles, associated with running on a laptop or VM (`local`) or on
Kubernetes (`kubernetes`). There are two ways of specifying input data - one is a conventional Nextflow
approach, the other mimics the way in which input data is presented to the pipeline on Kubernetes. **For
development the conventional approach is usually more useful.**

#### Normal Local Running

Input and output directories are specified as shown below, which supports running batches of samples. Note that 
the `--outdir` must be absolute. When running locally `-profile local` should be used.

```bash
sudo nextflow run . -profile local --sample_input_dir <path/to/input_dir> --outdir </abs/path/to/output_dir> --seq_platform <illumina/ont>
```

By default it will look for files in the input directory based on the following params:
- `params.input_paired_suffix = "*_{1,2}.fastq.gz"`
- `params.input_single_suffix = "*.fastq.gz"`
but these can be overriden. Note that file ending must be `.fastq.gz` or `.fq.gz`.

```
nextflow run ... --input_paired_suffix "tb_sample*_{1,2}.fq.gz"
```

You can also use `--publish_dir <directory>` to save all process outputs to provided directory. This is rarely needed.

### Platform-like Input and Output

On Kubernetes, or for running with a Kubernees-like input pattern, sample fastqs need to be 
in `data/input/<sample_id>/<run_id>` and outputs go to `data/outputs/<sample_id>/<run_id>`. Then run:

```bash
sudo nextflow run . -profile local --sample_id <sample_id> --run_id <run_id> --seq_platform illumina
```

This can also be run using makefiles. To download an example illumina and ont sample 
to `data/inputs/1` and `data/inputs/2` run:

```bash
bash setup_local_example.sh
```

and then check pipeline works with the following. `data/outputs` should then be populated.

```bash
make run-illumina
make run-ont
```

### FN5

FN5 is impossible to fully run locally as it relies on server-side components to compare accross all 
samples, and so this is not recommended. By default the `-profile local` disables fn5. Deploy a version of 
the pipeline to a dev environment to work with FN5.

It is possible to run the pipeline locally with the FN5 step, but an API token for an active GPAS environment
needs to be provided.

## Testing

Running the pipeline is computationally expensive, so testing is covered by the automated testing for the subworkflows (see
each repository for details) and by the regression / integration tests that are run prior to releases:
- https://github.com/GlobalPathogenAnalysisService/deployment-tests
- https://github.com/GlobalPathogenAnalysisService/myco_relatedness_test

There is only a single unit test for process logic in this repository. `nf-test` is required to run this.

```
nf-test test tests/gather_knowledge.nf.test
```
