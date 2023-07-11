#!/usr/bin/env nextflow
nextflow.enable.dsl=2


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

params.reads = "$params.uploads_bucket/$params.sample_id/*_R{1,2}.fastq.gz"
params.minimap2_index = "./data/h37rv.mmi"
params.catalogue = "./data/mtb_catalogue.vcf"

params.outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id/"

subwork_folder = "${projectDir}/sub_workflows"
include { find_neighbour_5 } from "${subwork_folder}/fn5_pipeline/main"

workflow run_fn5 {

    container "lhr.ocir.io/lrbvkel2wjot/oxfordmmm/fn5:latest"

    find_neighbour5()

}

workflow {
    main:
        run_fn5()
}
