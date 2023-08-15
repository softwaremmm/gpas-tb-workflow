#!/bin/bash

call_hostile() {
  echo "bash script started at `date`"
  sleep 5

  echo "Mounting buckets using s3fs"
  s3fs "$WORKSPACE-dirtydata" /workspace/buckets/upload_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style

  s3fs "$WORKSPACE-readyforprocessing" /workspace/buckets/input_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style

  s3fs "$WORKSPACE-output" /workspace/buckets/output_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style

  s3fs "$WORKSPACE-relatedness" /workspace/buckets/relatedness_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style

  echo "Sample name: $sample_name"
  echo "fastq 1: $fq1"
  echo "fastq 2: $fq2"
  echo "Human genome dir: $human_genome_dir"

  hostile clean --rename \
      	--fastq1 $fq1 \
      	--fastq2 $fq2 \
      	--index $human_genome_dir/human-t2t-hla-argos985-mycob140 \
      	--out-dir . > decontamination-log.json

  echo "Renaming files"
  echo "hostile clean 1 name: $clean_1_name"
  echo "hostile clean 2 name: $clean_2_name"
  echo "Renamed clean 1 name: $new_clean_1_name"
  echo "Renamed clean 2 name: $new_clean_2_name"

  mv $clean_1_name $new_clean_1_name
  mv $clean_2_name $new_clean_2_name

  echo "bash script completed"
}

call_hostile
