sudo nextflow run . -profile local,no_fn5 --sample_id 1 --run_id 1 --api_token "token" --species test \
  --seq_platform illumina -resume

sudo nextflow run . -profile local,no_fn5 --sample_id 2 --run_id 1 --api_token "token" --species test \
  --seq_platform ont -resume
