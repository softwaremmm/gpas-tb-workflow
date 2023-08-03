# Lineage Calling Pipeline (mykrobe)

## Installation

To run and test the pipeline, create a conda environment e.g. called `nextflow` likes this:

```
conda create -f -y -n nextflow
```

Activate it:

```
conda activate `nextflow`
```

and install `nextflow` and `nf-test` e.g.

```
conda install nextflow nf-test
```

Other ways of install `nextflow` and `nf-test` are available!

You will also need to have installed [Docker desktop](https://www.docker.com/products/docker-desktop/).

Because the pipeline runs in the context of a docker container, no other dependencies are needed.

## Running the NextFlow

Examples:

```
nextflow run . --input_dir ~/lineagecalling_pipeline/test_data/h37rv_100k
```

or

```
nextflow run . --input_dir ~/lineagecalling_pipeline/test_data/absc_100k
```

The `input_dir` needs to contain a pair of FASTQ files.

## What it does

This pipeline has a workflow which consists of two processes, which are called consecutively:

### `mykrobe` 

This process is a wrapper for the [mykrobe](https://github.com/Mykrobe-tools/mykrobe) software. The 
software has been contained in a [Dockerfile](./Dockerfile) and the image is pushed to a container
registry by CI (or by hand) and then used by the process to run a bash command.

### `mykrobe_json`

This process takes the output from `mykrobe` (which is in JSON format), extracts the information under
the `phylogenetics` key and removes all objects that contain a key called `Unknown`.

## Testing NextFlow

Run `nf-test test`

## Building the Docker container image

It is not normally necessary to build the Docker image locally, as NextFlow has been configured to
pull the container image from OCI.

To build the Docker image locally, having [installed and configured Docker](https://docs.docker.com/get-docker/), use:

```
docker build -t <local-image-name> .
```

Check if it runs OK using:

```
docker run <local-image-name>
```

You should see the help output for `mykrobe`.