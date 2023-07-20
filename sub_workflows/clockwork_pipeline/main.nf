#!/usr/bin/env nextflow

//Set DSL2 syntax
nextflow.enable.dsl=2

//Define ANSI colours for ease
ANSI_GREEN = "\033[1;32m"
ANSI_RESET = "\033[0m"

params.help = ''
params.sample_reads = ''
params.species = 'tb'

if (workflow.profile != 'kubernetes') {
    params.knowledge_bucket = "$projectDir/data/relatedness/knowledge"
} else {
    params.knowledge_bucket = "/data/relatedness/knowledge"
}

process run_clockwork{
    debug true

    input:
        tuple val(x), path(sample_reads1), path(sample_reads2)
    output:
        path("Outdir/1/cortex.vcf"), emit: cortex_vcf, optional: true
        path("Outdir/1/final.gvcf"), emit: final_gvcf
        path("Outdir/1/final.gvcf.fasta"), emit: final_gvcf_fasta
        path("Outdir/1/final.vcf"), emit: final_vcf
        path("Outdir/1/samtools.vcf"), emit: samtools_vcf
        path("Outdir/1/map.bam"), emit: map_bam
        path("Outdir/1/map.bam.bai"), emit: map_bam_bai
        path("Outdir/1/tb_clockwork_report.json"), emit: tb_clockwork_report_json
        path("Outdir/1/tb_clockwork_error.json"), emit: tb_clockwork_error_json
    beforeScript 'chmod 777 .'

    container 'lhr.ocir.io/lrbvkel2wjot/oxfordmmm/clockwork:latest'
    containerOptions "-v ${params.knowledge_bucket}/clockwork/tb/Ref_prepare:/Ref_prepare:ro -v ./Outdir:/Outdir:rw"

    script:
        """
        clockwork variant_call_one_sample --keep_bam --no_trim /Ref_prepare /Outdir/1/ ${sample_reads1} ${sample_reads2}
        if [ ! -f ".Outdir/1/cortex.vcf" ]; then
            touch ./Outdir/1/cortex.vcf
        fi
        touch ./Outdir/1/tb_clockwork_report.json
        touch ./Outdir/1/tb_clockwork_error.json
        """
    stub:
        """
        echo $PWD
        mkdir -p ./Outdir
        mkdir -p ./Outdir/1
        touch ./Outdir/1/cortex.vcf
        touch ./Outdir/1/final.gvcf
        touch ./Outdir/1/final.gvcf.fasta
        touch ./Outdir/1/final.vcf
        touch ./Outdir/1/samtools.vcf
        touch ./Outdir/1/map.bam
        touch ./Outdir/1/map.bam.bai
        touch ./Outdir/1/tb_clockwork_report.json
        touch ./Outdir/1/tb_clockwork_error.json
        """
}

workflow clockwork{
    take:
    reads

    main:

        run_clockwork(reads)
    
    emit:
        cortex_vcf = run_clockwork.out.cortex_vcf
        final_gvcf = run_clockwork.out.final_gvcf
        final_gvcf_fasta = run_clockwork.out.final_gvcf_fasta
        final_vcf = run_clockwork.out.final_vcf
        samtools_vcf = run_clockwork.out.samtools_vcf
        map_bam = run_clockwork.out.map_bam
        map_bam_bai = run_clockwork.out.map_bam_bai
        tb_clockwork_report_json = run_clockwork.out.tb_clockwork_report_json
        tb_clockwork_error_json = run_clockwork.out.tb_clockwork_error_json
}



workflow{
    main:
        if (params.help) {
            log.info """
            ========================================================================
            Clockwork

            Processing bacterial sequence data (Illumina only) and variant calling.

            Parameters:
            ------------------------------------------------------------------------
            --sample_reads  Directory holding the fastq files *reads{1,2}.fq.gz
            --species       Name of the species this belongs to. Default = 'tb'
            """
            .stripIndent()
            exit(0)
        }

        log.info """
        ========================================================================
        Clockwork

        Processing bacterial sequence data (Illumina only) and variant calling.

        Parameters:
        ------------------------------------------------------------------------
        --sample_read    $params.sample_read
        --species        $params.species

        Runtime data:
        ------------------------------------------------------------------------
        Running with profile  ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
        Running as user       ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
        Launch directory      ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
        Project directory     ${ANSI_GREEN}${projectDir}${ANSI_RESET}
        """
        .stripIndent()

        Channel
            .fromFilePairs("$params.sample_read/*_{1,2}.fastq.gz", checkIfExists:true, flat:true)
            | clockwork
}