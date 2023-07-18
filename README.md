# test-tb-workflow
Example of a TB variant calling pipeline for testing nextflow deployments

## Installation

Install nextflow. This requires Java 11 or later (OpenJDK, `apt install default-jre`, on Ubuntu works).

From https://www.nextflow.io/docs/latest/getstarted.html:
```
wget -qO- https://get.nextflow.io | bash
```

## Running

To run this workflow, clone it:

```
git clone https://github.com/GlobalPathogenAnalysisService/gpas-tb-workflow.git
```

## Running the Pipeline Locally

Running the nextflow pipeline you can run as:

```bash
nextflow run . -profile local
```

This will use the samples from the `data/inputs/1/1` folder as `params.sample_id` and `params.run_id` will both default to 1

If you want to use different samples then create a structure under `data/inputs` to put your two fastq files into. e.g.

If you use sample_id 5 and run_id 1 then you would have the folder structure
```
inputs
    └── 5
        └── 1
```
And would use the following command to run the nextflow
```bash
nextflow run . -profile local --sample_id 5 --run_id 1
```

Please note that WP7 does not have a dummy as it outputs nothing to the output bucket