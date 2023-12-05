include { get_clean_file_name; get_report_file_name; get_new_clean_file_name } from './utils/file_naming.nf'

clean_1_name = ''
clean_2_name = ''
new_clean_1_name = ''
new_clean_2_name = ''
hostile_report_file_name = ''

process process_hostile {
  container "lhr.ocir.io/lrbvkel2wjot/gpas/hostile:0.4.0"
  label 'hostile'
  cpus 4
  memory { 8.GB * task.attempt }

  errorStrategy 'retry'
  maxRetries 2

  debug true
  pod label: "name", value: "human-read-removal_pipeline:process_hostile"
  pod label: "sample_id", value: "${params.sample_id}"
  pod label: "run_id", value: "${params.run_id}"

  input:
  tuple val(sample_name), path(fq1), path(fq2)
  path(human_genome_dir)

  output:
  tuple val(sample_name), path(new_clean_1_name), path(new_clean_2_name), emit: clean_fastq
  path hostile_report_file_name, emit: hostile_report

  stub:
  hostile_report_file_name = get_report_file_name()
  new_clean_1_name = get_new_clean_file_name(sample_name, 1)
  new_clean_2_name = get_new_clean_file_name(sample_name, 2)


  """
  touch ${new_clean_1_name}
  touch ${new_clean_2_name}
  touch ${hostile_report_file_name}
  """

  script:
  clean_1_name = get_clean_file_name(fq1, 1)
  clean_2_name = get_clean_file_name(fq2, 2)
  hostile_report_file_name = get_report_file_name()

  new_clean_1_name = get_new_clean_file_name(sample_name, 1)
  new_clean_2_name = get_new_clean_file_name(sample_name, 2)

  println()
  log.info "=========== HOSTILE PROCESS ==========="
  log.info "Sample name: ${sample_name}, type: ${sample_name.getClass()}"
  log.info "fastq 1: ${fq1}, type: ${fq1.getClass()}"
  log.info "fastq 2: ${fq2}, type: ${fq2.getClass()}"
  log.info "Human genome directory: ${human_genome_dir}, type: ${human_genome_dir.getClass()}"

  template 'run_hostile.sh'
}

process hostile_consumer {
  input:
  tuple val(sample_name), path(fq1), path(fq2)

  output:
  val 'Done'

  script:
  log.info "===========HOSTILE CONSUMER PROCESS==========="
  log.info "Sample name: ${sample_name}, type: ${sample_name.getClass()}"
  log.info "fastq 1: ${fq1}, type: ${fq1.getClass()}"
  log.info "fastq 2: ${fq2}, type: ${fq2.getClass()}"
  """
  echo "hostile consumer"
  """
}
