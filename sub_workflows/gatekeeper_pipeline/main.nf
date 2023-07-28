#!/usr/bin/env nextflow

include {fastp} from './process/quality_check.nf'
include {countReads} from './process/count_reads.nf'
include {kraken2} from './process/kraken2.nf'

//Constants
fastq_pattern = "*_{1,2}.f*q*"


//Parameters
params.input_dir = ""
params.output_dir = ""
params.kraken2_db_path = ""
params.help = ""


workflow gatekeeper{

    take:
        input_dir
        output_dir
        kraken2_db_path

    main:

    if (params.help) {
            log.info """
            ========================================================================
            Competitive Mapping Workflow

            Parameters:
            ------------------------------------------------------------------------
            --input_dir    Path to the sample's directory
            --output_dir   Path to the workflow's output directory
            --kraken2_db_path   Path to the kraken dataset directory

            """
            .stripIndent()
            exit(0)
        }


        if ( input_dir == "" ) {
            exit 1, "error: --input_dir is mandatory"
        }

        if ( output_dir == "" ) {
            exit 1, "error: --output_dir is mandatory"
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
            .set{ database }

        input_files.view{it}

        fastp(input_files)

        kraken2(input_files, database)

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
        gatekeeper(params.input_dir, params.output_dir, params.kraken2_db_path)
}


