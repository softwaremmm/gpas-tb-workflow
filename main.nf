#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// CURRENTLY NOT WORKING, IN DEVELOPMENT

// Kubernetes Related Buckets
if (workflow.profile != 'kubernetes') {

    params.uploads_bucket = "./data/uploads"
    params.inputs_bucket = "./data/inputs"
    params.outputs_bucket = "./data/outputs"
    params.relatedness_bucket = "./data/relatedness"
    params.knowledge_bucket = "./data/knowledge"
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

// the location in the buckets for the current run
params.outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id/"
params.indir = "$params.inputs_bucket/$params.sample_id/$params.run_id/"
params.updir = "$params.uploads_bucket/$params.sample_id/"
params.reldir = "$params.relatedness_bucket/$params.sample_id/$params.run_id/"
params.knowdir = "$params.knowledge_bucket/$params.sample_id/$params.run_id/"

// files for the current run locations
params.reads = "$params.indir/*_{1,2}.fastq.gz"
params.minimap2_index = "./data/h37rv.mmi"
params.catalogue = "./data/mtb_catalogue.vcf"

// sub workflows import
subwork_folder = "${projectDir}/sub_workflows"
include { find_neighbour_5 } from "${subwork_folder}/fn5_pipeline/main.nf"
include { run_clockwork } from "${subwork_folder}/clockwork_pipeline/main.nf"

workflow call_clockwork {

    container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/clockwork:latest"

    Channel
            .fromFilePairs("$params.reads", checkIfExists:true, flat:true)
            | run_clockwork
}

workflow call_fn5 {

    container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/fn5:latest"

    find_neighbour5()

}

workflow {
    main:
        call_clockwork()
}
