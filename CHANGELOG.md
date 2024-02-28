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
