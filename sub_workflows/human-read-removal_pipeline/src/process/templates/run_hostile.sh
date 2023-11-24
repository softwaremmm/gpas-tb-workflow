#!/bin/bash

call_hostile() {
  echo "bash script started at `date`"
  sleep 5

  echo $WORKSPACE
  if [ ${workflow.profile} == 'kubernetes' ]
  then
      echo "Running with kubernetes"
      echo $projectDir
      /bin/bash $projectDir/lib/s3fs_setup.sh $WORKSPACE
  fi

  echo "Sample name: $sample_name"
  echo "fastq 1: $fq1"
  echo "fastq 2: $fq2"
  echo "Human genome dir: $human_genome_dir"

  hostile clean --rename --threads ${task.cpus} --aligner-args="--reorder" \
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

  if [ ${workflow.profile} == 'kubernetes' ]
  then
      /bin/bash ${projectDir}/lib/s3fs_teardown.sh
  fi

  echo "bash script completed"
}

call_hostile
