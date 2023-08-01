# test-tb-workflow
Example of a TB variant calling pipeline for testing nextflow deployments

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

This will use the samples from the `data/uploads/1/1` folder as `params.sample_id` and `params.run_id` will both default to 1

If you want to use different samples then create a structure under `data/uploads` to put your two fastq files into. e.g.

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
