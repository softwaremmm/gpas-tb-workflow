# gpas-tb-workflow
TB pipeline

The workflow consist of multiple steps (sometimes referred to as "Work Packages"):

| Work Package | Main Software | Notes | Repository(ies) | Docker Image(s) |
| --- | --- | --- | --- | --- |
| **2** Decontamination / Human Read Removal | [hostile](https://github.com/bede/hostile) | Double check on removal of human reads from input data | [human-read-removal_pipeline](https://github.com/GlobalPathogenAnalysisService/human-read-removal_pipeline) | quay.io/biocontainers/hostile:0.1.0--pyhdfd78af_0 | 
| **3** Gatekeeper | kraken2 | Quality checking and read filtering | [gatekeeper_pipeline](https://github.com/GlobalPathogenAnalysisService/gatekeeper_pipeline) | lhr.ocir.io/lrbvkel2wjot/gpas/gatekeeper_pipeline:latest |
| **4** Speciation | minimap2, samtools, mykrobe | Competitive Mapping and Lineage Calling (mykrobe) | [lineagecalling_pipeline](https://github.com/GlobalPathogenAnalysisService/lineagecalling_pipeline) [competitivemapping_pipeline](https://github.com/GlobalPathogenAnalysisService/competitivemapping_pipeline) | lhr.ocir.io/lrbvkel2wjot/gpas/lineagecalling_pipeline:latest lhr.ocir.io/lrbvkel2wjot/gpas/competitivemapping_pipeline:latest |
| **5** Assembly | clockwork, minos | Variant calling | [clockwork_pipeline](https://github.com/GlobalPathogenAnalysisService/clockwork_pipeline) | lhr.ocir.io/lrbvkel2wjot/oxfordmmm/clockwork:latest |
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
By default this script fetches the `main` branch of all defined subworkflows. To fetch the latest releases instead, use `bash clone_sub_workflows.sh latest` 

## Conventional Commits
Use conventional commits when developing for this repo. 
You should install the pre-commit hooks to check your commit messages. A tool `pre-commit` can be used for this.
You can also install `commitizen` to help with writing conventional commits.
You can install both through pip/conda. Or see [wiki for other options](https://github.com/GlobalPathogenAnalysisService/Wiki/blob/main/Commitizen.md#installing-commitizenpre-commit)

To install hooks run
```bash
pre-commit install --hook-type commit-msg
```

To make commit with commitizen run
```bash
cz c
```

## Tags and Releases

[Commitizen](https://commitizen-tools.github.io/commitizen/) is used to manage versioning of releases. This tool
can be used to make commits to this repository. Regardless, [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) 
are required to ensure correct version numbering and changelog population.

**Do not add tags by hand.**

On merging a Pull Request a [GitHub action will run](.github/workflows/bump.yaml), causing Commitizen to:
* Determine the new [semver](https://semver.org/) based on conventional commits.
* Replace the previous semver in [.cz.toml](.cz.toml) and other files as specified therein.
* Update the [CHANGELOG](CHANGELOG.md) based on commit messages.
* Commit these changes to the `main` branch.
* Create a tag for this commit with the tag name of the newly determined semver.
* Create a new release from this tag.

## Running the Pipeline Locally

If you want to use different samples then create a structure under `data/uploads` to put your two FASTQ files into. FASTQ files must adopt the pipeline standard file naming convention i.e. `*_{1,2}.fastq.gz`

e.g. if you use sample_id 5 and run_id 1 then you would have the folder structure

```
uploads
    └── 5
        ├── bob_1.fastq.gz
        └── bob_2.fastq.gz
```

And would use the following command to run the NextFlow:

```bash
sudo ./run_with_test_species.sh -profile local --sample_id 5 --run_id 1 --api_token $(cat ../NEXTFLOW_API_KEY)
```

`NEXTFLOW_API_KEY` is a file containing the API needed for FN5 to communicate with the database it needs in order to function.

`sudo` is recommended.
