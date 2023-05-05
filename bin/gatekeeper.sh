#!/usr/bin/env bash
echo "gatekeeper script got fastqs:" $1 $2 $3
touch $1_filtered_R2.fastq.gz
touch $1_filtered_R1.fastq.gz
touch qc_report.json

