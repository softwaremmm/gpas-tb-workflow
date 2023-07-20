#!/usr/bin/env nextflow

include {fastp} from './process/quality_check.nf'
include {kraken2} from './process/kraken2.nf'

//Constants
fastq_pattern = "*_{1,2}.fastq.gz"


//Parameters
params.input_dir = ""
params.kraken2_db_path = ""
params.help = ""

workflow gatekeeper{

    take:
        input_dir
        kraken2_db_path

    main:

    if (params.help) {
            log.info """
            ========================================================================
            Gatekeeper Workflow

            Parameters:
            ------------------------------------------------------------------------
            --input_dir    Path to the sample's directory
            --kraken2_db_path   Path to the kraken dataset directory

            """
            .stripIndent()
            exit(0)
        }


        if ( input_dir == "" ) {
            exit 1, "error: --input_dir is mandatory"
        }

        if ( kraken2_db_path == "" ) {
            exit 1, "error: --kraken2_db_path is mandatory"
        }

        inputdir_amended = "${input_dir}".replaceFirst(/$/, "/")
        indir = "${inputdir_amended}"
        reads = indir + fastq_pattern

        Channel.fromFilePairs(reads, flat: true, checkIfExists: true, size: -1)
            .ifEmpty { error "cannot find any reads matching ${fastq_pattern} in ${indir}" }
            .set{ input_files }

        Channel.fromPath(params.kraken2_db_path)
            .set{ dataset }

        input_files.view{it}

        fastp_output = fastp(input_files)

        kraken2_output = kraken2(input_files, dataset)
    
    emit:

        fastp_report = fastp_output.fastp_json
        fastp_error = fastp_output.fastp_error
  
        kraken2_filtered_samples = kraken2_output.kraken2_filtering
        kraken2_outputs = kraken2_output.kraken2_out
        kraken2_error = kraken2_output.kraken2_log

        gatekeeper_report = kraken2_output.gatekeeper_report_json

}

workflow.onComplete {
    if ( workflow.success ) {
        log.info """
        ===========================================
        Workflow completed successfully
        """
        .stripIndent()
    }
    else {
        log.info """
        ===========================================
        Finished with errors
        """
        .stripIndent()
    }
}

workflow{
    main:
        gatekeeper(params.input_dir, params.kraken2_db_path)
}


