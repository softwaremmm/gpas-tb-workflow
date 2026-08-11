# Developer Notes

## Running on Kubernetes

This pipeline was designed primarily to run on a Kubernetes cluster.
Kubernetes is supported as an [Nextflow Executor](https://docs.seqera.io/nextflow/executor), but is not as straightforward to use as some of the others.
Our initial requirements included a need to have privately hosted Docker containers available to the pipeline.
This codebase is therefore complicated over a "normal" Nextflow project but elements like:
* The need to mount S3 compatible buckets to access data during pipeline runs.
* The need to feed Kubernetes variables and secrets via Nextflow.
* The need to feed node pool config and and pod affinity information via Nextflow.
These settings won't interfere with "normal" offline running.

## Build System

Pipeline code is downloaded from an S3 compatible bucket just prior to run time, and then executed.
The system that gathers and places all necessary code in the bucket is the [Pipeline Build System](https://github.com/GlobalPathogenAnalysisService/pipeline-builder).
The Build System code is executed automatically by GitHub Actions ([Build Pipeline](.github/workflows/build-pipeline.yaml)) when a pull request to `main` or `develop` is made, or a new tag is pushed.

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

## Platform-like Input and Output

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

## FN6

FN6 is impossible to fully run locally as it relies on server-side components to compare accross all samples, and so this is not recommended.
By default the `-profile local` disables fn6.
Deploy a version of the pipeline to a dev environment to work with FN6.

It is possible to run the pipeline locally with the FN6 step, but an API token for an active GPAS environment needs to be provided.

## Testing

Running the pipeline is computationally expensive, so testing is covered by the automated testing for the subworkflows (see
each repository for details) and by the regression / integration tests that are run prior to releases:
- https://github.com/GlobalPathogenAnalysisService/deployment-tests
- https://github.com/GlobalPathogenAnalysisService/myco_relatedness_test

There is only a single unit test for process logic in this repository. `nf-test` is required to run this.

```
nf-test test tests/gather_knowledge.nf.test
```
