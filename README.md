# test-tb-workflow
Example of a TB variant calling pipeline for testing nextflow deployments

## Installation

Install nextflow. This requires Java 11 or later (OpenJDK, `apt install default-jre`, on Ubuntu works).

From https://www.nextflow.io/docs/latest/getstarted.html:
```
wget -qO- https://get.nextflow.io | bash
```

This workflow makes use of submodules, use the following command to clone
```
git clone --recurse-submodules git@github.com:GlobalPathogenAnalysisService/test-tb-workflow.git
```

To update the submodules if changes have been made use the following command
```
git submodule update --remote
```

See https://git-scm.com/book/en/v2/Git-Tools-Submodules for more information about 
submodules

## Running

This repo includes a set of mock-up bioinformatics tools that mimic the command line behaviour of the real ones. These are in `bin/`.

To run this workflow, clone it:

```
git clone https://github.com/GlobalPathogenAnalysisService/test-tb-workflow.git
```

and create an `in_bucket` in the directory it is run from:

```
cd test-tb-workflow
mkdir in_bucket
```

Create a pair of fastqs to simulate uploading a sample:

```
touch in_bucket/asdf_R1.fastq.gz
touch in_bucket/asdf_R2.fastq.gz
```

To run the pipeline, the mock-up `bin` directory needs to be in the path:

```
PATH=./bin/:$PATH ../nextflow run .
```
