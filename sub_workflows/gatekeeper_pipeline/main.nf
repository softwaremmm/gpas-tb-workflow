#!/usr/bin/env nextflow

include {fastp} from './process/quality_check.nf'
include {kraken2} from './process/kraken2.nf'
include {has_enough_reads} from './process/has_enough_reads.nf'

//Constants
fastq_pattern = "*_{1,2}.fastq.gz"
default_min_num_reads = 20000

//Parameters
params.input_dir = ""
params.kraken2_db_path = ""
params.help = ""
params.min_num_reads=""

workflow gatekeeper {

    take:
        input_dir
        kraken2_db_path

    main:

    if (params.min_num_reads) {
         min_num_reads = params.min_num_reads
    }else{
        min_num_reads = default_min_num_reads
    }

    fastp_output = fastp(input_dir)
    kraken2_output = kraken2(fastp_output.fastp_fqs, kraken2_db_path, min_num_reads)
    
    emit:

        fastp_report = fastp_output.fastp_json
        fastp_error = fastp_output.fastp_error
  
        kraken2_filtered_samples = kraken2_output.kraken2_filtering
        kraken2_outputs = kraken2_output.kraken2_out
        kraken2_error = kraken2_output.kraken2_log

        kraken2_enough_reads = has_enough_reads(kraken2_output.kraken2_log)
        
        gatekeeper_report = kraken2_output.gatekeeper_report_json

}

workflow.onComplete {
    if ( workflow.success ) {
        log.info """
        ===========================================
        Gatekeeper Workflow completed successfully
        """
        .stripIndent()
    }
    else {
        log.info """
        ===========================================
        Gatekeeper finished with errors
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
            --min_num_reads   Minimum number of reads (optional)

            """
            .stripIndent()
            exit(0)
        }

        input_files = Channel.fromFilePairs("${params.input_dir}/${fastq_pattern}", flat: true, checkIfExists: true, size: -1)
            .ifEmpty { error "cannot find any reads matching ${fastq_pattern} in ${params.input_dir}" }

        gatekeeper(input_files, params.kraken2_db_path)
}


