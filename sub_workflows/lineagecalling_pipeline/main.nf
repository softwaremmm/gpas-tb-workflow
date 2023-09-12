#!/usr/bin/env nextflow

//Set DSL2 syntax
nextflow.enable.dsl = 2

//Define ANSI colours for ease
ANSI_GREEN = "\033[1;32m"
ANSI_RESET = "\033[0m"

params.help = ''

//Constant
fastq_pattern = "*_{1,2}.fastq.gz"


process mykrobe {
  cpus 5
  memory '6 GB'
  container 'lhr.ocir.io/lrbvkel2wjot/gpas/lineagecalling_container:v0.12.2'

  input:
    tuple val(sample_name), path(fq1), path(fq2)

  output:
    path "lc_report.json", emit: report
    path "subspecies_error.json", emit: error

  script:
    mykrobe_report = "lc_report.json"
    mykrobe_error = "subspecies_error.json"

    """
    mykrobe predict --threads $task.cpus --memory 6GB --sample ${sample_name} --species tb --format json --output ${mykrobe_report} -1 $fq1 $fq2
    touch ${mykrobe_error}
    """
}

process mykrobe_json {
    cpus 5
    memory '500 MB'
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/lineagecalling_container:v0.12.2'

  input:
    tuple val(sample_name), path(fq1), path(fq2)
    path lc_report

  output:
    path "subspecies_report.json", emit: mykrobe_report

  script:
  subspecies_report = "subspecies_report.json"
    """
    cat ${lc_report} |
      jq '.[].phylogenetics' |
      jq 'walk(if type=="object" and has("Unknown") then del(.) else . end)' |
      jq 'del(..|nulls)' > ${subspecies_report}
    """
}

workflow lineagecalling {
  take:
    input_files

  main:
   
    input_files.view { it } // print channel contents to console
    lineage_calling_ch = mykrobe(input_files)
    mykrobe_json_output = mykrobe_json(input_files, lineage_calling_ch.report)

  emit:
    json_report = mykrobe_json_output.mykrobe_report
    json_error = lineage_calling_ch.error
}

workflow.onComplete {
    if ( workflow.success ) {
        log.info """
        ===========================================
        Lineage calling (Mykrobe) Workflow completed successfully
        """
        .stripIndent()
    }
    else {
        log.info """
        ===========================================
        Lineage calling (Mykrobe) finished with errors
        """
        .stripIndent()
    }
}
 

workflow {
  if (params.input_dir == '') {
    exit 1, 'error: --input_dir is mandatory'
  }

  if (params.help) {
    log.info '''
            ========================================================================
            Lineage Calling

            Checks lineage using `mykrobe`.

            Parameters:
            ------------------------------------------------------------------------
            --input_dir  Directory holding the fastq files *_{1,2}.fastq.gz
            '''

            .stripIndent()

    exit(0)
  }

  log.info """
        ========================================================================
        Lineage Calling

        Checks lineage using `mykrobe`.

        Parameters:
        ------------------------------------------------------------------------

        --input_dir    $params.input_dir

        Runtime data:
        ------------------------------------------------------------------------

        Running with profile  ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
        Running as user       ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
        Launch directory      ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
        Project directory     ${ANSI_GREEN}${projectDir}${ANSI_RESET}
        """
        .stripIndent()

  Channel.fromFilePairs("$params.input_dir/${fastq_pattern}", checkIfExists:true, flat:true)
    .ifEmpty { error "cannot find any reads matching ${fastq_pattern} in ${indir}" }
    .set { input_files }


  main:
    lineagecalling(input_files)
}
