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

        fastp_output = fastp(input_dir)
        println input_dir
        println kraken2_db_path
        kraken2_output = kraken2(input_dir, kraken2_db_path)
    
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

        //inputdir_amended = "${params.input_dir}".replaceFirst(/$/, "/")
        //indir = "${inputdir_amended}"
        //reads = indir + fastq_pattern

        input_files = Channel.fromFilePairs("${params.input_dir}/*_{1,2}.fastq.gz", flat: true, checkIfExists: true, size: -1)
            .ifEmpty { error "cannot find any reads matching ${fastq_pattern} in ${indir}" }

        //input_files.view{it}
        gatekeeper(input_files, params.kraken2_db_path)
}


