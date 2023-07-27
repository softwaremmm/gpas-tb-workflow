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
  container 'lhr.ocir.io/lrbvkel2wjot/gpas/lineagecalling_pipeline:latest'

  input:
    tuple val(sample_name), path(fq1), path(fq2)

  output:
    path "${sample_name}_lc_report.json", emit: report

  script:
    mykrobe_report = "${sample_name}_lc_report.json"

    """
    mykrobe predict --sample ${sample_name} --species tb --format json --output ${mykrobe_report} -1 $fq1 $fq2
    """
}

process mykrobe_json {
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/lineagecalling_pipeline:latest'

  input:
    tuple val(sample_name), path(fq1), path(fq2)
    path lc_report

  output:
    path "${sample_name}_mykrobe_report.json", emit: mykrobe_report

  script:
    """
    echo "hi"
    cat ${lc_report} |
      jq '.[].phylogenetics' |
      jq 'walk(if type=="object" and has("Unknown") then del(.) else . end)' |
      jq 'del(..|nulls)' > ${sample_name}_mykrobe_report.json
    """
}

workflow lineagecalling {
  take:
    input_files

  main:
   
    input_files.view { it } // print channel contents to console
    lc_report = mykrobe(input_files)
    mykrobe_json_output = mykrobe_json(input_files, lc_report)

  emit:
    json_report = mykrobe_json_output.mykrobe_report
}

workflow.onComplete {
    if ( workflow.success ) {
        log.info """
        ===========================================
        Lineage calling (Mycrobe) Workflow completed successfully
        """
        .stripIndent()
    }
    else {
        log.info """
        ===========================================
        Lineage calling (Mycrobe) finished with errors
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
