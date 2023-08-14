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
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/summary_pipeline:latest'

  input:
    path gatekeeper
    path mapping
    path mykrobe
    path gnomonicus

  output:
    path "main_report.json", emit: main_report
    path "main_error.json", emit: main_error

  script:
    """
    summary_json --gatekeeper ${gatekeeper} --mapping ${mapping} --mykrobe ${mykrobe} --gnomonicus ${gnomonicus} --output main_report.json
    touch main_error.json
    """
}

workflow summary {
  take:
    gatekeeper_report_path
    mapping_report_path
    mykrobe_report_path
    gnomonicus_report_path

  main:
    if (params.gatekeeper_report_path == '') {
    exit 1, 'error: --gatekeeper_report_path is mandatory'
    }
    if (params.mapping_report_path == '') {
    exit 1, 'error: --mapping_report_path is mandatory'
    }
    if (params.mykrobe_report_path == '') {
    exit 1, 'error: --mykrobe_report_path is mandatory'
    }
    if (params.gnomonicus_report_path == '') {
    exit 1, 'error: --gnomonicus_report_path is mandatory'
    }

    if (params.help) {
    log.info '''
            ========================================================================
            Summary

            Combines output from workflow steps to create a single summary JSON file.

            Parameters:
            ------------------------------------------------------------------------
            --gatekeeper_report_path  Path to gatekeeper report (`gatekeeper_report.json`).
            --mapping_report_path  Path to competitive mapping report (`competitivemapping_report.json`).
            --mykrobe_report_path  Path to mykrobe report (`mykrobe_report.json`).
            --gnomonicus_report_path  Path to gnomonicus report (`gnomonicus.json`).
            '''

            .stripIndent()

    exit(0)
    }

  log.info """
        ========================================================================
        Summary

        Combines output from workflow steps to create a single summary JSON file.

        Parameters:
        ------------------------------------------------------------------------

        --gatekeeper_report_path    $params.gatekeeper_report_path
        --mapping_report_path       $params.mapping_report_path
        --mykrobe_report_path       $params.mykrobe_report_path
        --gnomonicus_report_path    $params.gnomonicus_report_path

        Runtime data:
        ------------------------------------------------------------------------

        Running with profile  ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
        Running as user       ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
        Launch directory      ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
        Project directory     ${ANSI_GREEN}${projectDir}${ANSI_RESET}
        """
        .stripIndent()

    summary_json_output = summary_json(gatekeeper_report_path, mapping_report_path, mykrobe_report_path, gnomonicus_report_path)

  emit:
    main_report = summary_json_output.main_report
    error_report = summary_json_output.main_error
}

workflow {
  main:
    summary(projectDir/params.gatekeeper_report_path, projectDir/params.mapping_report_path, projectDir/params.mykrobe_report_path, projectDir/params.gnomonicus_report_path)
}