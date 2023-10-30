nextflow.enable.dsl = 2

include { human_read_removal } from './src/workflow/human_read_removal.nf'

// Constants
input_fastq_suffix = "*_{1,2}.fastq.gz"

// Parameters
params.input_dir = ""
params.input_fastq_prefix = ""
params.human_genome_dir = ""

workflow {
  main:
  input_fastq_pattern = params.input_fastq_prefix + input_fastq_suffix

  input_fastq_files = Channel
      .fromFilePairs("${params.input_dir}/${input_fastq_pattern}",
          flat: true,
          checkIfExists: true,
          size: -1)
      .ifEmpty { error "cannot find any reads matching ${input_fastq_pattern} in ${params.input_dir}" }

  println(input_fastq_files.getClass())
  println(input_fastq_files)

  input_fastq_files.view { it ->
    {
      println()
      log.info "Type: ${it.getClass()}"

      it.each {
        element ->
          {
            def elementType = element.getClass()
            log.info "Element --- Type: ${elementType}, Value: ${element}"
          }
      }

      return it
    }
  }

  human_read_removal(
      input_fastq_files,
      Channel.fromPath(params.human_genome_dir)
  )
}

workflow.onComplete {
  if ( workflow.success ) {
    log.info """
        ===========================================
        Human read removal Workflow completed successfully
        """
        .stripIndent()
  }
  else {
    log.info """
        ===========================================
        Human read removal Workflow finished with errors
        """
        .stripIndent()
  }
}
