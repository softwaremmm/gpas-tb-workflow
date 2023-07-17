#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// CURRENTLY NOT WORKING, IN DEVELOPMENT

// Kubernetes Related Buckets
if (workflow.profile != 'kubernetes') {
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
include { clockwork } from "${subwork_folder}/clockwork_pipeline/main.nf"


input_reads = Channel.fromFilePairs("$clean_reads", checkIfExists:true, flat:true)

// dummy WP3
process gatekeeper {
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

workflow call_fn5 {
    take:
    fasta

    main:
        container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/fn5:latest"
        // find_neighbour5(fasta)

}

process runPrediction {
    input:
        path(vcf)

    output:
        path("gnomonicus-out.json"), emit: gnomonicus_json
    
    script:
    """
        touch gnomonicus-out.json
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
    output:
        path('main_report.json'), emit: main_report_json
        path('main_error.json'), emit: main_error_json
    script:
    """
    touch main_report.json
    touch main_error.json
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
        call_wp3.out.kraken_report_json.first().copyTo("${outdir}/speciation_reports_for_reads/kraken_report.json")
        call_wp3.out.fastp_report_json.first().copyTo("${outdir}/raw_read_QC_reports/fastp_report.json")
        call_wp3.out.kraken_report_txt.first().copyTo("${outdir}/speciation_reports_for_reads/kraken_report.txt")
        call_wp3.out.gatekeeper_error_json.first().copyTo("${outdir}/gatekeeper_error.json")
        call_wp3.out.gatekeeper_report_txt.first().copyTo("${outdir}/gatekeeper_report.txt")

        // wp4
        call_wp4(kraken_reads_ch)
        filtered_reads_ch = call_wp4.out.reads_ch
        call_wp4.out.competitivemapping_report_json.first().copyTo("${outdir}/competitivemapping_report.json")
        call_wp4.out.competitivemapping_error_json.first().copyTo("${outdir}/competitivemapping_error.json")
        call_wp4.out.lc_error_json.first().copyTo("${outdir}/lc_error.json")
        call_wp4.out.mykrobe_report_json.first().copyTo("${outdir}/mykrobe_report.json")

        // WP5
        clockwork(filtered_reads_ch)
        fasta_ch = clockwork.out.final_gvcf_fasta
        fasta_ch.first().copyTo("${outdir}/tb/final.fasta")
        vcf_ch = clockwork.out.final_vcf
        vcf_ch.first().copyTo("${outdir}/tb/final.vcf")
        clockwork.out.cortex_vcf.first().copyTo("${outdir}/tb/cortex.vcf")
        clockwork.out.final_gvcf.first().copyTo("${outdir}/tb/final.gvcf")
        clockwork.out.samtools_vcf.first().copyTo("${outdir}/tb/samtools.vcf")
        clockwork.out.map_bam.first().copyTo("${outdir}/tb/map.bam")
        clockwork.out.map_bam_bai.first().copyTo("${outdir}/tb/map.bam.bai")
        clockwork.out.tb_clockwork_report_json.first().copyTo("${outdir}/tb_clockwork_report.json")
        clockwork.out.tb_clockwork_error_json.first().copyTo("${outdir}/tb_clockwork_error.json")
        
        // WP6
        call_wp6(vcf_ch)
        call_wp6.out.gnomonicus_json.first().copyTo("${outdir}/tb/gnomonicus.json")

        //WP7
        // call_fn5(fasta_ch)

        // WP8
        call_wp8()
        call_wp8.out.main_report_json.copyTo("${outdir}/main_report.json")
        call_wp8.out.main_error_json.copyTo("${outdir}/main_error.json")
}
