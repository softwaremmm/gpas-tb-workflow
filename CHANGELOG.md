## New

### ONT Variant Calling and Assembly

- ONT Only: Swap from sundial to rundial. clair3 model can be specified for variant calling.

### TB Predict

- Update VCF merging to resolve issues with minor alleles
- Update gnomonicus to fix bugs encountered when analysing NTM data (no effect on TB)

## 2.4.1

- Amend 2.4.0 changelog for CFZ

## 2.4.0

- fix: ensure CFZ is properly passed into the resistance prediction summary
- Add new competitive mapping param as a consequence of making comeptitive mapping work for influenza virus
- Refactoring to split minimap2 and analysis step into seperate Python tasks
- chore: Parameterise container prefix

### Gatekeeper
- Silent changes to gatekeeper that don't affect this pipeline

### Competitive mapping
- Remove duplicate mappings (only affects "intermediary file" output, not used in UI)
- Change to support influenza (do not affect this pipeline)

## 2.3.0

- Add new competitive mapping param as a consequence of making comeptitive mapping work for influenza virus
- Refactoring to split minimap2 and analysis step into seperate Python tasks

## 2.2.4
- Fixes for complex VCF rows + various other AMR prediction edge cases. See tb-predict-pipeline for breakdown of all edge cases

## 2.2.3

### Fixes

- If not enough reads for assembly, then do not produce "reads_for_assembly.fastq.gz" as output

## 2.2.2

### Fixes

- Retry fastp without adapter trimming when out of memory (ONT)

## 2.2.1

Used the wrong version of gatekeeper so fix not introduced until 2.2.2

## 2.2.0

### Chores

- This, and all sub workflows adopt Nextflow language server for consistency in coding style.
- Variable naming is more consistent and comprehensible.
- This, and all sub workflows modified so they can be run locally using:
  - A directory of input files
  - Without pseudonymisation of sample names
  - Without FN5 being run (and thus without the need for an API token)

Refer to individual sub workflow change logs for more details.

- **Competitive Mapping** has been refactored from bash into Python

### Features

- **Competitive Mapping**:
  - `species_comparison_report.json` is produced in `csv` format as well as `json` - this is easier to work with in a spreadsheet.
  - Every read mapped to is included in the report, even if no reads were mapped - this makes comparisons between samples easier.

### Fixes

- **Gatekeeper** retry _fastp_ process if it fails. Increase RAM request for each retry.
- **Sundial** use a consistent number of "chunks" in bcftools step, rather than matching this to number of available CPUs, to remain deterministic.
- **Summary** consistently correctly report depth and coverage in mykrobe section of the main JSON report for all known mykrobe output structures.
- **Competitive Mapping**:
  - Correctly report species names for M. basiliense and M. saopaulense
  - Remove unused species

## 2.1.0 (2025-02-07)

### Chore

[MMM-1059] Build pipelines individually

Pipelines are built using https://github.com/GlobalPathogenAnalysisService/pipeline-builder (details in readme).
In summary, this means that pipelines are built using this action when commits or tags are created and copied to
buckets. Pipeline versions specified in https://github.com/GlobalPathogenAnalysisService/pathogena-releases are
pulled from those buckets at run time. This confers several benefits listed in the Jira ticket.

Scientifically unchanged from the version in poller `2.0.3`.

### Fix

- fix bug when reading ont fastq files with fullstops in file name.

## 1.3.58 (2024-11-05)

### Fix

- use competitive_mapping_mykrobe_names_20241105

## 1.3.57 (2024-11-01)

### Fix

- use mapping csv 20241101

## 1.3.56 (2024-10-17)

### Fix

- remove minor alleles from config too
- remove minor alleles from tb-predict input

## 1.3.55 (2024-10-07)

### Fix

- revert pipeline changes for grumpy

## 1.3.54 (2024-09-27)

### Fix

- **myco**: Update name lookup to 20240927

## 1.3.53 (2024-09-26)

### Fix

- enable k8s debug yaml
- update trace settings

## 1.3.52 (2024-09-16)

### Fix

- always use error retry

## 1.3.51 (2024-08-29)

### Fix

- clean up minor alleles

## 1.3.50 (2024-08-29)

### Fix

- clean up minor alleles from config
- remove minor alleles input to gnomonicus

## 1.3.49 (2024-08-22)

### Fix

- use right syntax
- node affinity to keep nf pods in autoscaler pool

## 1.3.48 (2024-07-16)

### Fix

- **myco**: Correct mapping file name

## 1.3.47 (2024-07-15)

### Fix

- **myco**: name mapping 20240715

## 1.3.46 (2024-07-12)

### Fix

- keep updir
- instructions for running locally
- use param to stop running fn5
- set desired branches for subworkflows

## 1.3.45 (2024-07-12)

### Fix

- **myco**: mapping lookup 20240712b

## 1.3.44 (2024-07-10)

### Fix

- Remove s3fs mounting code (not used)

## 1.3.43 (2024-07-10)

### Fix

- update comp mapping files

## 1.3.42 (2024-07-09)

### Fix

- map tuples to files
- use tuples in channels

## 1.3.41 (2024-07-08)

### Fix

- add nf-test for knowledge json output

## 1.3.40 (2024-07-08)

### Fix

- De-referene sub-workflows
- Update cm mykorbe name mapping

## 1.3.39 (2024-07-04)

### Fix

- remove comma to make json valid

## 1.3.38 (2024-07-04)

### Fix

- set version to 1.3.37
- remove mask from knowledge

## 1.3.36 (2024-07-03)

### Fix

- Update species name mapping ref data

## 1.3.35 (2024-07-03)

### Fix

- use full vcf output

## 1.3.34 (2024-06-27)

### Fix

- Unlink sub workflows
- Use knowledge bucket for reference data

## 1.3.33 (2024-06-24)

### Fix

- Remove sub repos
- Omit taxa summary json from user outputs

## 1.3.32 (2024-06-24)

### Fix

- Species name formatting

## 1.3.31 (2024-06-24)

### Fix

- unpack gvcf path ONT

## 1.3.30 (2024-06-21)

### Fix

- add paths gvcf and null_positions paths to tb-predict

## 1.3.29 (2024-06-10)

### Fix

- clean up extra krakendb param
- use kraken mmap when on k8s

## 1.3.28 (2024-06-03)

### Fix

- write bracken report to bucket

## 1.3.27 (2024-05-29)

### Fix

- fix input dir

## 1.3.26 (2024-05-22)

### Fix

- add params for fn5 2.0.0

## 1.3.25 (2024-05-17)

### Fix

- update gatekeeper workflow

## 1.3.24 (2024-04-09)

### Fix

- Don't use cached kraken2 hash table

## 1.3.23 (2024-04-09)

### Fix

- pass ref file instead of dir

## 1.3.22 (2024-04-08)

### Fix

- Restore api_token param

## 1.3.21 (2024-04-08)

### Fix

- Don't use cached kraken2 hash table

## 1.3.20 (2024-04-08)

### Fix

- Parameter needed for Sundial
- Reintroduce testing param

## 1.3.19 (2024-04-08)

### Fix

- Remove params prefix

### Refactor

- Move more paramters to config
- Move ref data paths to config
- Move default params to config
- Move bucket config to `nextflow.config`

## 1.3.18 (2024-04-02)

### Fix

- add relatedness bucket to FN5 call

## 1.3.17 (2024-03-18)

### Fix

- update called workflow name for sundial

## 1.3.16 (2024-03-15)

### Fix

- update sundial workflow name

## 1.3.15 (2024-03-04)

### Fix

- remove superfluous nodeAffinity annotations

## 1.3.14 (2024-03-04)

### Fix

- update podAffinity

## 1.3.13 (2024-03-01)

### Fix

- don't duplicate entire pod spec
- use right nf syntax
- add node affinity for writing processes

## 1.3.12 (2024-03-01)

## 1.3.11 (2024-03-01)

### Fix

- add annotation to mark nf pods as not safe to evict

## 1.3.10 (2024-02-29)

### Fix

- Add retries to processes

## 1.3.9 (2024-02-29)

### Fix

- Add CPU and RAM to all processes

## 1.3.8 (2024-02-29)

### Fix

- use while loop instead of if

## 1.3.7 (2024-02-28)

### Fix

- remove time directive

## 1.3.6 (2024-02-28)

### Fix

- work around pod affinity

## 1.3.5 (2024-02-27)

### Fix

- add pod affinity to nf pods

## 1.3.4 (2024-02-15)

### Fix

- hopefully get right fastp tuple
- hopefuly write fastp files properly

## 1.3.3 (2024-02-14)

### Fix

- add extra gatekeeper files to bucket

## 1.3.2 (2024-02-09)

### Fix

- use WHO v2

## 1.3.1 (2024-01-22)

### Fix

- re-enable FN5

## 1.3.0 (2024-01-18)

### Feat

- update to using ont repos

### Fix

- give default empty string value to test_container param
- add seq platform for runner script
- update steps pre sundial/clockwork

## 1.2.0 (2024-01-17)

### Feat

- use commitizen for version control

## v1.1.2 (2024-01-10)

### Fix

- **report**: ensure html report can be overwritten

## v1.1.1 (2023-12-19)

### Fix

- redirect s3fs echos to stderr

## v1.1.0 (2023-12-19)

### Feat

- use hostpath mounted buckets

### Fix

- remove s3fs secret

## v1.0.0 (2023-12-18)

### Feat

- uses ont-enabled human read removal pipeline, controlled by flag
- Prefix file names with sampleID
- file saved with sample id prefix
- use image pull secret for all pods config
- Add labels to pods
- Use a standard name for summary
- Use name mapping reference data
- use k8s secret for bucket mounting instead of file on PVC
- Breaking - accept new style manifest
- Pass ref data names to summary
- Process to write ref data filenames to json
- add mounting of api key as a secret
- Add default error strategy
- Use cached kraken2 reference data
- Do not require dummy file
- Pass pipeline versions to summary workflow

### Fix

- preparations for poller-based release process
- **s3fs**: ensure buckets are unmounted on exit
- remove feat_ont flag
- seq_platform check needs to be subworkflow
- perform check on seq_platform param
- Clockwork now under gpas and add clockwork_bcf tools
- limit to 8 cpus
- add resource limits
- Drop unknown trace field
- Specify and link k8s retries
- Add debug info to trace output
- Use 20231109 species name lookup
- Set `rc`
- Give `rename_name_mapping` s3fs
- Copy and rename name mapping file
- fix failed CI
- use docker login rather than action
- make CI login with container registry to download private images
- fix malformed nextflow config
- use newer AMR catalogue
- remove fn5 error log from outputs
- remove set -x from s3fs setup
- mount as env variable and make file on the fly
- Add fasta adjudication to gnomonicus
- Remove echo on unmount completed
- **unmount**: catch last $s
- **unmount**: escape $ within script blocks
- **exit**: fix exit code capture
- **umount**: try to umount but don't fail if already umounted
- Unmount buckets after process
- **teardown**: add umount script for processes
- **nonempty**: add nonempty arg to s3fs mount arguments
- Include species_list in metadata
- ensure testing resources are not used
- give default api token value
- use F catalogue
- use minutes
- ensure we sleep for enough time
- Do not write kraken json to output bucket
- Do not write errors to bucket
- Do not ignore sub_workflows
- Dummy `pipeline_versions.txt` for dev
- Do not gitignore subworkflows
- Ignore nextflow debug output
- Ignore symlinked `data/`
- Remove `data/` (not used)
- Ignore sub workflows dir for dev
- typo in knowledge bucket

## v0.0.6 (2023-08-02)

### Feat

- **jobs**: Run nextflow tasks as jobs not pods
- **parameters**: update parameters for poller

### Fix

- **containers**: Add containers for nextflow k8s processer
- **profiles**: add profiles API instead of env var for executor
