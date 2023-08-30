include { process_hostile } from '../process/hostile.nf'

workflow human_read_removal {
  take:
  fastq_files
  human_genome_dir

  main:
  hostile_output = process_hostile(fastq_files, human_genome_dir)

  emit:
  clean_fastq = hostile_output.clean_fastq
  hostile_report = hostile_output.hostile_report
}

