# gpas-tb-workflow
TB pipeline

The workflow consist of multiple steps (sometimes referred to as "Work Packages"):

| Work Package | Main Software | Notes | Repository(ies) | Docker Image(s) |
| --- | --- | --- | --- | --- |
| **2** Decontamination / Human Read Removal | [hostile](https://github.com/bede/hostile) | Double check on removal of human reads from input data | [human-read-removal_pipeline](https://github.com/GlobalPathogenAnalysisService/human-read-removal_pipeline) | quay.io/biocontainers/hostile:0.1.0--pyhdfd78af_0 |
| **3** Gatekeeper | kraken2 | Quality checking and read filtering | [gatekeeper_pipeline](https://github.com/GlobalPathogenAnalysisService/gatekeeper_pipeline) | lhr.ocir.io/lrbvkel2wjot/gpas/gatekeeper_pipeline:latest |
| **4** Speciation | minimap2, samtools, mykrobe | Competitive Mapping and Lineage Calling (mykrobe) | [lineagecalling_pipeline](https://github.com/GlobalPathogenAnalysisService/lineagecalling_pipeline) [competitivemapping_pipeline](https://github.com/GlobalPathogenAnalysisService/competitivemapping_pipeline) | lhr.ocir.io/lrbvkel2wjot/gpas/lineagecalling_pipeline:latest lhr.ocir.io/lrbvkel2wjot/gpas/competitivemapping_pipeline:latest |
| **5** Assembly | clockwork, minos, sundial | Variant calling | [clockwork_pipeline](https://github.com/GlobalPathogenAnalysisService/clockwork_pipeline) [sundial](https://github.com/GlobalPathogenAnalysisService/sundial) | lhr.ocir.io/lrbvkel2wjot/oxfordmmm/clockwork:latest lhr.ocir.io/lrbvkel2wjot/oxfordmmm/sundial:latest |
| **6** Resistance Prediction | gnomonicus | Variants, mutations and effects of a specified (minos) VCF file | [tb-predict-pipeline](https://github.com/GlobalPathogenAnalysisService/tb-predict-pipeline) | oxfordmmm/gnomonicus:latest |
| **7** Relatedness | Find Neighbour 5 | SNP distance calculation | [fn5_pipeline](https://github.com/GlobalPathogenAnalysisService/fn5_pipeline) | lhr.ocir.io/lrbvkel2wjot/oxfordmmm/fn5:latest |
| **8** (or maybe 9) Summary | *None* | Summarises outputs into a JSON file | [summary_pipeline](https://github.com/GlobalPathogenAnalysisService/summary_pipeline) | lhr.ocir.io/lrbvkel2wjot/oxfordmmm/summary_pipeline:latest |

A machine readable list of the repositories required to run the full pipeline (not including Work Package 2 Decontamination / Human Read Removal) is [included in this repository](./includerepos.txt).

Work package **1** is about upload, and **8** is about integration, so they're not in this table.

## Prerequisites

Install NextFlow. This requires Java 11 or later (OpenJDK, `apt install default-jre`, on Ubuntu works).

From https://www.nextflow.io/docs/latest/getstarted.html:
```
wget -qO- https://get.nextflow.io | bash
```

Install Docker Desktop.

## Installation
Download the artefact from the [latest release](https://github.com/GlobalPathogenAnalysisService/gpas-tb-workflow/releases/latest).

The `main` branch (and other branches) are unlikely to ever have a complete set of populated sub-workflows, and if they do, they are most likely outdated.

## Development
Use of the latest release's artefact does not include things such as the `.git` directory, so for development please clone and create a branch to work on:
```
git clone git@github.com:GlobalPathogenAnalysisService/gpas-tb-workflow.git
cd gpas-tb-workflow
git checkout -b <branch name>
```

If required, clone subworkflows: `bash clone_sub_workflows.sh`. However, sub_workflows should not be committed due to size and version ambiguity!
By default this script fetches the `main` branch of all defined subworkflows.
To fetch the latest releases instead, use `bash clone_sub_workflows.sh latest`.
To fetch different branches, change the values from `main` in `includerepos.csv`.

## Tags, Releases, and Committing
Use conventional commits. This is enforced with commitizen validate action and pre-commit hooks:
```bash
pre-commit install
```

This repo uses a standard gitflow approach, so changes should be first merged into develop and then released to main.
- In the develop branch semantic versioning is not used. Instead you can reference the commit hash to use it in a workflow.
- In a release branch you can create a release candidate with `cz bump a.b.c-rcX`. This also creates a tag.
- When release branch is ready for main run `cz bump a.b.c --files-only`. Manually write a human descriptive changelog. Then push these changes to main and make a release/tag there.


## Running the Pipeline Locally

If you want to use different samples then create a structure under `data/inputs` to put your two FASTQ files into.
FASTQ files must adopt the pipeline standard file naming convention i.e. `*_{1,2}.fastq.gz`

e.g. if you use sample_id 5 and run_id 1 then you would have the folder structure (for nanopore would require one file)

```
inputs
    └── 5
        ├── bob_1.fastq.gz
        └── bob_2.fastq.gz
```

You should also create `data/outputs` directories, as well as a `data/knowledge` directory. This must be populated with the reference data needed
to run the sub-workflows. Check the OCI bucket in the `dev` environment for this.

You will need to clone the subworkflows using `clone_sub_workflows.sh`.

Assuming you have cloned the sub-workflows, execute `./sub_workflows/fn5_pipeline/local_setup.sh` to create the directory structure needed for the "Find Neighbor 5" sub-workflow.

You will also need to login to docker (`docker login lhr.ocir.io` and/or `sudo docker login lhr.ocir.io`) in order to be able to pull the containers.

And would use the following command to run the NextFlow:

```bash
sudo ./run_with_test_species.sh -profile local --sample_id 5 --run_id 1 --api_token $(cat ../NEXTFLOW_API_KEY) --seq_platform illumina
```

`NEXTFLOW_API_KEY` is a file containing the API needed for FN5 to communicate with the database it needs in order to function.

`sudo` is recommended.

Supported seq platforms are 'illumina' and 'ont'.

## testing
For testing you need nf-test installed.
You'll need the reference data and subworkflows set up as described for running locally.

Currently there is only a single unit test.
```
nf-test test tests/gather_knowledge.nf.test
```

`pipeline.nf.test` is outdated

### full pipeline test
For a full pipeline test you'll need some input data. An ONT and Illumina example can be found in the dev knowledge bucket under `example_sample`.
The `run_local.sh` will run the pipeline except for FN5 which requires more set up.
The script assumes you have the following files in inputs directory:
```
inputs/1/1/<illumina>_1.fastq.gz
inputs/1/1/<illumina>_2.fastq.gz
inputs/2/1/<ont>.fastq.gz
```

After the nextflow completes the `outputs` directory should be populated.
