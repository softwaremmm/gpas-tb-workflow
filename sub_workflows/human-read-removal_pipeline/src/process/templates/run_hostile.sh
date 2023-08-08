#!/bin/bash

call_hostile() {
  echo "bash script started at `date`"
  sleep 5
  echo "Sample name: $sample_name"
  echo "fastq 1: $fq1"
  echo "fastq 2: $fq2"
  echo "Human genome dir: $human_genome_dir"

  hostile clean --rename \
      	--fastq1 $fq1 \
      	--fastq2 $fq2 \
      	--index $human_genome_dir/human-t2t-hla-argos985-mycob140 \
      	--out-dir . > decontamination-log.json

  echo "bash script completed"
}

call_hostile
