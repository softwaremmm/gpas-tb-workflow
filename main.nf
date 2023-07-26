#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// CURRENTLY NOT WORKING, IN DEVELOPMENT

// Kubernetes Related Buckets
if ("$workflow.profile" != 'kubernetes') {
    params.uploads_bucket = "$projectDir/data/uploads"
    params.inputs_bucket = "$projectDir/data/inputs"
    params.outputs_bucket = "$projectDir/data/outputs"
    params.relatedness_bucket = "$projectDir/data/relatedness"
    params.knowledge_bucket = "$projectDir/data/relatedness/knowledge"
} else {
    params.uploads_bucket = "/data/uploads"
    params.inputs_bucket = "/data/inputs"
    params.outputs_bucket = "/data/outputs"
    params.relatedness_bucket = "/data/relatedness"
    params.knowledge_bucket = "/data/relatedness/knowledge"
}


// Run Configurations
params.sample_id = 1
params.run_id = 1
params.help = ''
params.api_url = ''

// the location in the buckets for the current run
outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id"
indir = "$params.inputs_bucket/$params.sample_id/$params.run_id"
updir = "$params.uploads_bucket/$params.sample_id"
reldir = "$params.relatedness_bucket/$params.sample_id/$params.run_id"

// files for the current run locations
dirty_reads = "$updir/*_{1,2}.fastq.gz"
clean_reads = "$indir/*_{1,2}.fastq.gz"
minimap2_index = "./data/h37rv.mmi"
catalogue = "./data/mtb_catalogue.vcf"

// sub workflows import
subwork_folder = "${projectDir}/sub_workflows"
//include { find_neighbour_5 } from "${subwork_folder}/fn5_pipeline/main.nf"
//include { clockwork } from "${subwork_folder}/clockwork_pipeline/main.nf"


input_reads = Channel.fromFilePairs("$clean_reads", checkIfExists:true, flat:true)

// dummy WP3
process gatekeeper {
    container "docker.io/debian:12-slim"
    input:
        tuple val(x), path(sample_reads1), path(sample_reads2)
    output:
        path("kraken_report.json"), emit: kraken_report_json
        path("fastp_report.json"), emit: fastp_report_json
        path("kraken_report.txt"), emit: kraken_report_txt
        path("gatekeeper_error.json"), emit: gatekeeper_error_json
        path("gatekeeper_report.txt"), emit: gatekeeper_report_txt

    script:
        """
        touch kraken_report.json
        touch fastp_report.json
        touch kraken_report.txt
        touch gatekeeper_error.json
        touch gatekeeper_report.txt
        """
}

workflow call_wp3 {
    take:
        reads
    main:
        gatekeeper(reads)
    emit:
        kraken_reads_ch = Channel.fromFilePairs("$clean_reads", checkIfExists:true, flat:true)
        clean_reads_ch = Channel.fromFilePairs("$clean_reads", checkIfExists:true, flat:true)
        kraken_report_json = gatekeeper.out.kraken_report_json
        fastp_report_json = gatekeeper.out.fastp_report_json
        kraken_report_txt = gatekeeper.out.kraken_report_txt
        gatekeeper_error_json = gatekeeper.out.gatekeeper_error_json
        gatekeeper_report_txt = gatekeeper.out.gatekeeper_report_txt
}

//dummy WP4
process competitivemapping {
    container "docker.io/debian:12-slim"
    input:
        tuple val(x), path(sample_reads1), path(sample_reads2)
        val(threshhold)
    output:
        path("competitivemapping_report.json"), emit: competitivemapping_report_json
        path("competitivemapping_error.json"), emit: competitivemapping_error_json
        path("lc_error.json"), emit: lc_error_json
        path("mykrobe_report.json"), emit: mykrobe_report_json

    script:
        """
        touch competitivemapping_report.json
        touch competitivemapping_error.json
        touch lc_error.json
        touch mykrobe_report.json
        """
}

workflow call_wp4 {
    take:
    reads

    main:
        competitivemapping(reads, 20)
    emit:
        reads_ch = reads
        competitivemapping_report_json = competitivemapping.out.competitivemapping_report_json
        competitivemapping_error_json = competitivemapping.out.competitivemapping_error_json
        lc_error_json = competitivemapping.out.lc_error_json
        mykrobe_report_json = competitivemapping.out.mykrobe_report_json
}

// dummy WP5
process run_clockwork {
    container "docker.io/debian:12-slim"
    input:
        tuple val(x), path(sample_reads1), path(sample_reads2)
    output:
        path("Outdir/1/cortex.vcf"), emit: cortex_vcf, optional: true
        path("Outdir/1/final.gvcf"), emit: final_gvcf
        path("Outdir/1/final.fasta"), emit: final_fasta
        path("Outdir/1/final.vcf"), emit: final_vcf
        path("Outdir/1/samtools.vcf"), emit: samtools_vcf
        path("Outdir/1/map.bam"), emit: map_bam
        path("Outdir/1/map.bam.bai"), emit: map_bam_bai
        path("Outdir/1/tb_clockwork_report.json"), emit: tb_clockwork_report_json
        path("Outdir/1/tb_clockwork_error.json"), emit: tb_clockwork_error_json

    script:
        """
        mkdir -p ./Outdir
        mkdir -p ./Outdir/1
        touch ./Outdir/1/cortex.vcf
        touch ./Outdir/1/final.gvcf
        touch ./Outdir/1/final.fasta
        touch ./Outdir/1/final.vcf
        touch ./Outdir/1/samtools.vcf
        touch ./Outdir/1/map.bam
        touch ./Outdir/1/map.bam.bai
        touch ./Outdir/1/tb_clockwork_report.json
        touch ./Outdir/1/tb_clockwork_error.json
        """
}

workflow call_wp5 {
    take:
    reads

    main:
        run_clockwork(reads)
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

process runPrediction {
    container "docker.io/debian:12-slim"
    input:
        path(vcf)

    output:
        path("gnomonicus.json"), emit: gnomonicus_json

    script:
        """
        touch gnomonicus.json
        """
}

workflow call_wp6 {
    take:
    vcf

    main:
        runPrediction(vcf)

    emit:
        gnomonicus_json = runPrediction.out.gnomonicus_json

}

process create_main_json {
    container "docker.io/debian:12-slim"
    output:
        path('main_report.json'), emit: main_report_json
        path('main_error.json'), emit: main_error_json

    script:
        """
        touch main_report.json
        touch main_error.json
        """
}

process write_to_bucket {
    input:
        path(output_file)
    
    script:
        """
        cp ${output_file} ${outdir}
        """
}

process write_species_to_bucket {
    input:
        path(output_file)

    script:
        """
        mkdir -p ${outdir}/tb
        cp ${output_file} ${outdir}/tb
        """
}

process write_samples_to_bucket {
    input:
        tuple val(x), path(sample1), path(sample2)

    script:
        """
        cp ${sample1} ${outdir}
        cp ${sample2} ${outdir}
        """
}

workflow call_wp8 {
    main:
        create_main_json()
    emit:
        main_report_json = create_main_json.out.main_report_json
        main_error_json = create_main_json.out.main_error_json
}

workflow {
    main:

        // wp3
        call_wp3(input_reads)
        kraken_reads_ch = call_wp3.out.kraken_reads_ch
        clean_reads = call_wp3.out.clean_reads_ch 

        call_wp3.out.kraken_reads_ch.flatten().buffer( size:2, skip:1 ).flatten().first().copyTo("${outdir}/kraken_fastq_1.fastq.gz")
        call_wp3.out.kraken_reads_ch.flatten().buffer( size:2, skip:1 ).flatten().last().copyTo("${outdir}/kraken_fastq_2.fastq.gz")
        call_wp3.out.clean_reads_ch.flatten().buffer( size:2, skip:1 ).flatten().first().copyTo("${outdir}/clean_fastq_1.fastq.gz")
        call_wp3.out.clean_reads_ch.flatten().buffer( size:2, skip:1 ).flatten().last().copyTo("${outdir}/clean_fastq_2.fastq.gz")

        // wp4
        call_wp4(kraken_reads_ch)
        filtered_reads_ch = call_wp4.out.reads_ch

        // WP5
        call_wp5(filtered_reads_ch)
        fasta_ch = call_wp5.out.final_fasta
        vcf_ch = call_wp5.out.final_vcf

        // WP6
        call_wp6(vcf_ch)

        //WP7
        // call_fn5(fasta_ch)

        // WP8
        call_wp8()

        //copy to bucket
        call_wp3.out.kraken_report_json.concat(
            call_wp3.out.kraken_report_txt,
            call_wp3.out.gatekeeper_error_json,
            call_wp3.out.gatekeeper_report_txt,
            call_wp3.out.fastp_report_json,
            call_wp4.out.competitivemapping_report_json,
            call_wp4.out.competitivemapping_error_json,
            call_wp4.out.lc_error_json,
            call_wp4.out.mykrobe_report_json,
            call_wp5.out.tb_clockwork_report_json,
            call_wp5.out.tb_clockwork_error_json,
            call_wp8.out.main_report_json,
            call_wp8.out.main_error_json,
        ) | write_to_bucket

        call_wp3.out.kraken_report_json.concat(
            call_wp3.out.kraken_report_txt,
            call_wp3.out.gatekeeper_error_json,
            call_wp3.out.gatekeeper_report_txt,
            call_wp3.out.fastp_report_json,
            call_wp4.out.competitivemapping_report_json,
            call_wp4.out.competitivemapping_error_json,
            call_wp4.out.lc_error_json,
            call_wp4.out.mykrobe_report_json,
            call_wp5.out.tb_clockwork_report_json,
            call_wp5.out.tb_clockwork_error_json,
            call_wp8.out.main_report_json,
            call_wp8.out.main_error_json,
        ) | write_to_bucket

        // copy species specific files to bucket
        call_wp5.out.final_fasta.concat(
            call_wp5.out.final_vcf,
            call_wp5.out.cortex_vcf,
            call_wp5.out.final_gvcf,
            call_wp5.out.samtools_vcf,
            call_wp5.out.map_bam,
            call_wp5.out.map_bam_bai,
            call_wp6.out.gnomonicus_json,
        ) | write_species_to_bucket
}
