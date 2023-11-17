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

// project_dir = projectDir
outdir = "outdir"

process run_clockwork{
    container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/clockwork:v0.12.2"
    cpus = 1
    memory = "16 GB"
    debug true
    pod label: "name", value: "clockwork_pipeline:run_clockwork"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
        tuple val(x), path(sample_reads1), path(sample_reads2)
        path(ref_files)
    output:
        path("${outdir}/alternate-cortex.vcf"), emit: cortex_vcf, optional: true
        path("${outdir}/alternate.gvcf.gz"), emit: final_gvcf
        path("${outdir}/final.fasta"), emit: final_fasta
        path("${outdir}/final.vcf"), emit: final_vcf
        path("${outdir}/alternate-samtools.vcf"), emit: samtools_vcf
        path("${outdir}/final.bam"), emit: map_bam
        path("${outdir}/final.bam.bai"), emit: map_bam_bai
        path("${outdir}/genome_creation_error.json"), emit: tb_clockwork_error_json
    beforeScript 'chmod 777 .'

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
        fi
        
        clockwork variant_call_one_sample --keep_bam --no_trim ${ref_files} ${outdir} ${sample_reads1} ${sample_reads2}
        if [ ! -f "cortex.vcf" ]; then
            touch ${outdir}/ cortex.vcf
        fi

        mv ${outdir}/cortex.vcf ${outdir}/alternate-cortex.vcf
        mv ${outdir}/final.gvcf ${outdir}/alternate.gvcf
        gzip ${outdir}/alternate.gvcf
        mv ${outdir}/final.gvcf.fasta ${outdir}/final.fasta
        mv ${outdir}/samtools.vcf ${outdir}/alternate-samtools.vcf
        mv ${outdir}/map.bam ${outdir}/final.bam
        mv ${outdir}/map.bam.bai ${outdir}/final.bam.bai
        touch ${outdir}/genome_creation_error.json

        if [ ${workflow.profile} == 'kubernetes' ]
        then
            /bin/bash ${projectDir}/lib/s3fs_teardown.sh
        fi
        """
    stub:
        """
        echo $PWD
        mkdir -p "${outdir}"
        touch "${outdir}/alternate-cortex.vcf"
        touch "${outdir}/alternate.gvcf.gz"
        touch "${outdir}/final.fasta"
        touch "${outdir}/final.vcf"
        touch "${outdir}/alternate-samtools.vcf"
        touch "${outdir}/final.bam"
        touch "${outdir}/final.bam.bai"
        touch "${outdir}/genome_creation_error.json"
        """
}

process calc_counts{
    container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/clockwork_bcftools:v1.18.0"
    cpus = 1
    memory = "1 GB"
    debug true
    pod label: "name", value: "clockwork_pipeline:calc_counts"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
        path(gvcf_file)
        path(fasta_file)
        path(report_template)
    output:
        path("genome_creation_report.json"), emit: tb_clockwork_report_json

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
        fi

        bcftools query -f '%CHROM\\t%POS\\t%REF\\t%ALT\\t%INFO\\t[%GT]\\t[%DP4]\\t[%COV]\\n'  ${gvcf_file} | \
        awk 'BEGIN {FS=OFS="\\t"} {split(\$7, arr1, ","); split(\$8, arr2, ","); \$7=arr1[1]; \$8=arr1[2]; \$9=arr1[3]; \$10=arr1[4]; \$11=arr2[1]; \$12=arr2[2]; print}'  | \
        awk -F'\\t' '(\$7 + \$8 >= 10 && \$9 > 1 && \$10 > 1) || (\$11 > 1  && \$12>10) || (\$12>1  && \$11>10) ' > het_list
        export het_count=\$(cat het_list | wc -l | xargs)
        export fixed_coverage=\$(tail -n +2 ${fasta_file} | grep -oE "[NXOZ\\-]" | wc -l | xargs)
        export coverage=\$(tail -n +2 ${fasta_file} | tr -d '[:space:]' | wc -c | xargs)
        export fixed_coverage_percentage=\$(awk -v coverage=\$coverage -v fixed_coverage=\$fixed_coverage 'BEGIN { print 100 - (100 * (fixed_coverage / coverage))}')
        echo "Het Count: \$het_count"
        echo "Fixed coverage: \$fixed_coverage"
        echo "Coverage: \$coverage"
        echo "Fixed coverage percentage: \$fixed_coverage_percentage"

        cat $report_template | envsubst > "genome_creation_report.json"

        if [ ${workflow.profile} == 'kubernetes' ]
        then
            /bin/bash ${projectDir}/lib/s3fs_teardown.sh
        fi
        """

    stub:
        """
        touch "genome_creation_report.json"
        """
}

workflow clockwork{
    take:
    reads
    ref_files

    main:

        run_clockwork(reads, ref_files)
        calc_counts(run_clockwork.out.final_gvcf, run_clockwork.out.final_fasta, "${moduleDir}/tb_clockwork_report.json.template")
    
    emit:
        cortex_vcf = run_clockwork.out.cortex_vcf
        final_gvcf = run_clockwork.out.final_gvcf
        final_fasta = run_clockwork.out.final_fasta
        final_vcf = run_clockwork.out.final_vcf
        samtools_vcf = run_clockwork.out.samtools_vcf
        map_bam = run_clockwork.out.map_bam
        map_bam_bai = run_clockwork.out.map_bam_bai
        tb_clockwork_report_json = calc_counts.out.tb_clockwork_report_json
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
            --sample_read   Directory holding the fastq files *reads{1,2}.fq.gz
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

        Channel.fromFilePairs("$params.sample_read/*_{1,2}.fastq.gz", checkIfExists:true, flat:true)
            .set { read_ch }
        clockwork(read_ch, params.ref_files)
}
