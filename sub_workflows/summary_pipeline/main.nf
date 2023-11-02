#!/usr/bin/env nextflow

//Set DSL2 syntax
nextflow.enable.dsl = 2

//Define ANSI colours for ease
ANSI_GREEN = "\033[1;32m"
ANSI_RESET = "\033[0m"

params.help = ''

process summary_json {
    cpus 1
    memory '0.5 GB'
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/summary_pipeline:1.11.1'

    debug true
    pod label: "name", value: "summary_pipeline:summary_json"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

  input:
    path reports

  output:
    path "main_report.json", emit: main_report
    path "main_error.json", emit: main_error

  script:
    """
    summary_json --reports ${reports} --output main_report.json
    touch main_error.json
    """
}

workflow summary {
  take:
    reports_list

  main:
    log.info """
        ========================================================================
        Summary

        Combines output from workflow steps to create a single summary JSON file.
    """.stripIndent()

    if (params.reports_list == '') {
    exit 1, 'error: A list of reports is mandatory'
    }

    summary_json_output = summary_json(reports_list)

  emit:
    main_report = summary_json_output.main_report
    error_report = summary_json_output.main_error
}

workflow {
  log.info """
        Runtime data:
        ------------------------------------------------------------------------

        Running with profile  ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
        Running as user       ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
        Launch directory      ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
        Project directory     ${ANSI_GREEN}${projectDir}${ANSI_RESET}
        """
        .stripIndent()
  if (params.help) {
    log.info '''
            ========================================================================
            Summary

            Combines output from workflow steps to create a single summary JSON file.

            Parameters:
            ------------------------------------------------------------------------
            --reports_list  List of paths to reports e.g.
            Path to gatekeeper report (`speciation_report.json`).
            Path to competitive mapping report (`species_comparison_report.json`).
            Path to mykrobe report (`subspecies_report.json`).
            Path to gnomonicus report (`resistance_prediction_report.json`).
            '''

            .stripIndent()

    exit(0)
    }
  main:
    reports_list = params.reports?.split(',') as List
    reports_list_abs = reports_list.collect { it -> projectDir/it }
    summary(reports_list_abs)
}
