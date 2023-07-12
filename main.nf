#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// CURRENTLY NOT WORKING, IN DEVELOPMENT

// Kubernetes Related Buckets
if (workflow.profile != 'kubernetes') {
    params.uploads_bucket = "$projectDir/data/uploads"
    params.inputs_bucket = "$projectDir/data/inputs"
    params.outputs_bucket = "$projectDir/data/outputs"
    params.relatedness_bucket = "$projectDir/data/relatedness"
    params.knowledge_bucket = "$projectDir/data/knowledge"
} else {
    params.uploads_bucket = "/data/uploads"
    params.inputs_bucket = "/data/inputs"
    params.outputs_bucket = "/data/outputs"
    params.relatedness_bucket = "/data/relatedness"
    params.knowledge_bucket = "/data/knowledge"
}


// Run Configurations
params.sample_id = 1
params.run_id = 1
params.help = ''
params.api_url = ''

// the location in the buckets for the current run
outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id/"
indir = "$params.inputs_bucket/$params.sample_id/$params.run_id/"
updir = "$params.uploads_bucket/$params.sample_id/"
reldir = "$params.relatedness_bucket/$params.sample_id/$params.run_id/"
knowdir = "$params.knowledge_bucket/$params.sample_id/$params.run_id/"

// files for the current run locations
dirty_reads = "$updir/*_{1,2}.fastq.gz"
clean_reads = "$indir/*_{1,2}.fastq.gz"
minimap2_index = "./data/h37rv.mmi"
catalogue = "./data/mtb_catalogue.vcf"

// sub workflows import
subwork_folder = "${projectDir}/sub_workflows"
include { find_neighbour_5 } from "${subwork_folder}/fn5_pipeline/main.nf"
include { run_clockwork } from "${subwork_folder}/clockwork_pipeline/main.nf"

// dummy WP3
workflow call_wp3 {
    take:
    reads

    main: 
        log.info "Running WP3"
    
    emit:
        reads_ch = Channel.fromFilePairs("$clean_reads", checkIfExists:true, flat:true)
}

//dummy WP4
workflow call_wp4 {
    take:
    reads

    main:
        log.info "Running WP4"

    emit:
        reads_ch = reads
}

workflow call_clockwork {
    take:
    reads

    main:
        run_clockwork(reads)
    
    emit:
        final_gvcf_fasta = run_clockwork.out.final_gvcf_fasta
}

workflow call_fn5 {
    take:
    fasta

    main:
        container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/fn5:latest"
        // find_neighbour5(fasta)

}

workflow {
    main:
        dirty_reads_ch = Channel.fromFilePairs("$dirty_reads", checkIfExists:true, flat:true)

        // wp3
        call_wp3(dirty_reads)
        clean_reads_ch = call_wp3.out.reads_ch

        // wp4
        call_wp4(clean_reads_ch)
        filtered_reads_ch = call_wp4.out.reads_ch

        // WP5
        call_clockwork(filtered_reads_ch)
        fasta_ch = call_clockwork.out.final_gvcf_fasta

        // WP6


        //WP7
        // call_fn5(fasta_ch)
}
