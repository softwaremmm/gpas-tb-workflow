#!/usr/bin/env nextflow

//Set DSL2 syntax
nextflow.enable.dsl=2

//Define ANSI colours for ease
ANSI_GREEN = "\033[1;32m"
ANSI_RESET = "\033[0m"

params.help = ''
params.sample_reads = ''
params.species = 'tb'
params.ref_files = ''

project_dir = projectDir
outdir = "outdir"

process run_clockwork{
    container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/clockwork:latest"
    debug true

    input:
        tuple val(x), path(sample_reads1), path(sample_reads2)
        path(ref_files)
    output:
        path("${outdir}/cortex.vcf"), emit: cortex_vcf, optional: true
        path("${outdir}/final.gvcf"), emit: final_gvcf
        path("${outdir}/final.fasta"), emit: final_fasta
        path("${outdir}/final.vcf"), emit: final_vcf
        path("${outdir}/samtools.vcf"), emit: samtools_vcf
        path("${outdir}/map.bam"), emit: map_bam
        path("${outdir}/map.bam.bai"), emit: map_bam_bai
        path("${outdir}/tb_clockwork_report.json"), emit: tb_clockwork_report_json
        path("${outdir}/tb_clockwork_error.json"), emit: tb_clockwork_error_json
    beforeScript 'chmod 777 .'

    script:
        """
        clockwork variant_call_one_sample --keep_bam --no_trim ${ref_files} ${outdir} ${sample_reads1} ${sample_reads2}
        if [ ! -f "cortex.vcf" ]; then
            touch ${outdir}/ cortex.vcf
        fi
        mv ${outdir}/final.gvcf.fasta ${outdir}/final.fasta
        touch ${outdir}/tb_clockwork_report.json
        touch ${outdir}/tb_clockwork_error.json
        """
    stub:
        """
        echo $PWD
        mkdir -p "${outdir}"
        touch "${outdir}/cortex.vcf"
        touch "${outdir}/final.gvcf"
        touch "${outdir}/final.gvcf.fasta"
        touch "${outdir}/final.vcf"
        touch "${outdir}/samtools.vcf"
        touch "${outdir}/map.bam"
        touch "${outdir}/map.bam.bai"
        touch "${outdir}/tb_clockwork_report.json"
        touch "${outdir}/tb_clockwork_error.json"
        """
}

workflow clockwork{
    take:
    reads
    ref_files

    main:

        run_clockwork(reads, ref_files)
    
    emit:
        cortex_vcf = run_clockwork.out.cortex_vcf
        final_gvcf = run_clockwork.out.final_gvcf
        final_fasta = run_clockwork.out.final_fasta
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
            --ref_files     Location of the reference genome pre prepared files
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
        --ref_files      $params.ref_files

        Runtime data:
        ------------------------------------------------------------------------
        Running with profile  ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
        Running as user       ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
        Launch directory      ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
        Project directory     ${ANSI_GREEN}${projectDir}${ANSI_RESET}
        """
        .stripIndent()

        read_ch = Channel.fromFilePairs("$params.sample_read/*_{1,2}.fastq.gz", checkIfExists:true, flat:true)
        clockwork(read_ch, params.ref_files)
}