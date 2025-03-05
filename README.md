# gpas-tb-workflow
TB pipeline

The workflow consist of multiple steps:

| Step | Main Software | Notes | Repository(ies) |
| --- | --- | --- | --- |
| Gatekeeper | kraken2 | Quality checking and read filtering | [gatekeeper_pipeline](https://github.com/GlobalPathogenAnalysisService/gatekeeper_pipeline) |
| Speciation | minimap2, samtools, mykrobe | Competitive Mapping and Lineage Calling (mykrobe) | [lineagecalling_pipeline](https://github.com/GlobalPathogenAnalysisService/lineagecalling_pipeline) [competitivemapping_pipeline](https://github.com/GlobalPathogenAnalysisService/competitivemapping_pipeline) |
| Assembly | clockwork, minos, sundial | Variant calling | [clockwork_pipeline](https://github.com/GlobalPathogenAnalysisService/clockwork_pipeline) [sundial](https://github.com/GlobalPathogenAnalysisService/sundial) |
| Resistance Prediction | gnomonicus | Variants, mutations and effects of a specified (minos) VCF file | [tb-predict-pipeline](https://github.com/GlobalPathogenAnalysisService/tb-predict-pipeline) |
| Relatedness | Find Neighbour 5 | SNP distance calculation | [fn5_pipeline](https://github.com/GlobalPathogenAnalysisService/fn5_pipeline) |
| Summary | *None* | Summarises outputs into a JSON file | [summary_pipeline](https://github.com/GlobalPathogenAnalysisService/summary_pipeline) |

A machine readable list of the repositories required to run the full pipeline is [included in this repository](./includerepos.txt).

## Prerequisites
- Docker
- [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html)

You will also need to login to docker (`docker login lhr.ocir.io` and/or `sudo docker login lhr.ocir.io`) in order to be able to pull the containers.

### Cloning Subworkflows for Development
Will need to clone subworkflows: `bash clone_sub_workflows.sh`.
However, sub_workflows should not be committed due to size and version ambiguity!
By default this script fetches the `main` branch of all defined subworkflows.
To fetch the latest releases instead, use `bash clone_sub_workflows.sh latest`.
To fetch different branches, change the values from `main` in `includerepos.csv`.

## Running the Pipeline Locally
To download an example illumina and ont sample to `data/inputs/1` and `data/inputs/2` run
```bash
bash setup_local_example.sh
```
and then can test pipeline works with the following. `data/outputs` should then be populated.
```bash
make run-illumina
make run-ont
```

### Reference data
To run the pipeline requires reference data to be put in `data/knowledge`.
This should mirror the knowledge bucket on OCI.

### FN5
In general FN5 is difficult to run locally, and so is not recommended.
By default the `-profile local` disables fn5.
Check with Jeremy Westhead if needed.

### Running nextflow
There are two modes for running this pipeline. On the cloud sample fastqs are expected to be in `data/input/<sample_id>/<run_id>` and outputs go to `data/outputs/<sample_id>/<run_id>`. Some test examples are included in this repo.
```bash
sudo nextflow run . -profile local --sample_id 1 --run_id 1 --seq_platform illumina
```

But input and output directories can be used instead like below, which supports running batches of samples. Note that the `--outdir` must be absolute.
```bash
sudo nextflow run . -profile local --sample_input_dir path/to/input_dir --outdir /abs/path/to/output_dir --seq_platform illumina
```
When running locally `-profile local` should be used.

By default it will look for files in the input directory based on the following params:
- `params.input_paired_suffix = "*_{1,2}.fastq.gz"`
- `params.input_single_suffix = "*.fastq.gz"`

but these can be overriden. Note that file ending must be `.fastq.gz` or `.fq.gz`.
```
nextflow run ... --input_paired_suffix "tb_sample*_{1,2}.fq.gz"
```

You can also use `--publish_dir <directory>` to save all process outputs to provided directory. This is rarely needed.

---

You need to have a kraken2 index downloaded, and either placed in `data/knowledge/kraken2_db` or set:
```
--kraken2_db_path <path/to/your/index>
```

You may need to reduce memory requirements for kraken2 if using smaller index:
```
--kraken2_mem 5GB
```

## testing
For testing you need nf-test installed.

Currently there is only a single unit test.
```
nf-test test tests/gather_knowledge.nf.test
```

## Tags, Releases, and Committing
Use conventional commits. This is enforced with commitizen validate action and pre-commit hooks:
```bash
pre-commit install
```

This repo uses a standard gitflow approach, so changes should be first merged into develop and then released to main.
- In the develop branch semantic versioning is not used. Instead you can reference the commit hash to use it in a workflow.
- In a release branch you can create a release candidate with `cz bump a.b.c-rcX`. This also creates a tag.
- When release branch is ready for main run `cz bump a.b.c --files-only`. Manually write a human descriptive changelog. Then push these changes to main and make a release/tag there.
