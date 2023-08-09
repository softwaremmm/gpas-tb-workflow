#!/usr/bin/env nextflow
nextflow.enable.dsl=2

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
params.api_url = 'https://dev.portal.gpas.world'

// the location in the buckets for the current run
outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id"
indir = "$params.inputs_bucket/$params.sample_id/$params.run_id"
updir = "$params.uploads_bucket/$params.sample_id"
reldir = "$params.relatedness_bucket/$params.sample_id/$params.run_id"

// knowledge parameters
params.kraken2_db_path = "${params.knowledge_bucket}/kraken2_db"
params.manifest = "${params.knowledge_bucket}/manifest/target_101_new.fasta"
params.ref_files = "${params.knowledge_bucket}/clockwork/tb/Ref_prepare"
params.tb_ref_genome = "${params.knowledge_bucket}/tuberculosis_amr_catalogues/catalogues/NC_000962.3/NC_000962.3.gbk"
params.tb_amr_cat = "${params.knowledge_bucket}/tuberculosis_amr_catalogues/catalogues/NC_000962.3/NC_000962.3_WHO-UCN-GTB-PCI-2021.7_v1.0_GARC1_RUS.csv"
params.tb_minor_alleles = "${params.knowledge_bucket}/minor_alleles.txt"
params.human_genome_dir = "${params.knowledge_bucket}/human-genome"

// sub workflows import
subwork_folder = "${projectDir}/sub_workflows"
include { find_neighbour_5 } from "${subwork_folder}/fn5_pipeline/main.nf"
include { clockwork } from "${subwork_folder}/clockwork_pipeline/main.nf"
include { gatekeeper } from "${subwork_folder}/gatekeeper_pipeline/main.nf"
include { competitive_mapping } from "${subwork_folder}/competitivemapping_pipeline/main.nf"
include { lineagecalling } from "${subwork_folder}/lineagecalling_pipeline/main.nf"
include { gnomonicus_workflow } from "${subwork_folder}/tb-predict-pipeline/main.nf"
include { summary } from "${subwork_folder}/summary_pipeline/main.nf"
include { human_read_removal } from "${subwork_folder}/human-read-removal_pipeline/src/workflow/human_read_removal.nf"

dirty_reads_ch = Channel.fromFilePairs("${updir}/*_{1,2}.fastq.gz", checkIfExists:true, flat:true)

process write_clean_reads_to_input {
    input:
        tuple val(x), path(sample1), path(sample2)

    script:
        """
        mkdir -p ${indir}
        cp ${sample1} ${indir}
        cp ${sample2} ${indir}
        """
}

process write_to_bucket {
    input:
        path(output_file)
    
    script:
        """
        mkdir -p ${outdir}
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
        mkdir -p ${outdir}
        cp ${sample1} ${outdir}
        cp ${sample2} ${outdir}
        """
}


workflow {
    main:

        // wp2

        human_read_removal_ch = human_read_removal(dirty_reads_ch, Channel.fromPath(params.human_genome_dir))
     
        write_clean_reads_to_input(human_read_removal_ch.clean_fastq)

        // Gatekeeper: Trimming and positive filtering of Kraken2 Unclassified and Mycobacteriaceae reads
        gatekeeper_ch = gatekeeper(human_read_removal_ch.clean_fastq, params.kraken2_db_path)
    
        //Create a new channel if the condition to test (enough Unclassifidies and Mycrobacteriae reads) and the channel to use to proceed the execution (paths)
        gatekeeper_ch_output = gatekeeper_ch.kraken2_filtered_samples.merge(gatekeeper_ch.kraken2_enough_reads)

        gk_enough_reads_ch = gatekeeper_ch_output
            .filter { it[3] == "true"} //A new channel will be created only if the it[3] (enough reads) is true
            .map(it -> [it[0], it[1], it[2]]) //The value for the new channel will have a tuble of sample name, path1, path2
            .view{"Gatekeeper output sample has enough reads"}

        gk_not_enough_reads_ch = gatekeeper_ch_output
            .filter { it[3] == "false"} //A new channel will be created only if the it[3] (enough reads) is true
            .view{"Gatekeeper output sample does not have enough reads. END OF THE PIPELINE"}
        
        // //Pipeline proceeds only if gk_enough_reads_ch exists.
        // //lineagecalling_ch = lineagecalling(gk_enough_reads_ch) 
        competitive_mapping_ch = competitive_mapping(gk_enough_reads_ch, params.manifest)
        //Create a new channel if the condition to test (enough h37r-v reads) and the channel to use to proceed the execution (paths)
        competitive_mapping_ch_output = competitive_mapping_ch.cm_sample_paths.merge(competitive_mapping_ch.cm_enough_reads)

        cm_enough_reads_ch = competitive_mapping_ch_output
            .filter { it[3] == "true"} 
            .map(it -> [it[0], it[1], it[2]])
            .view{"Competitive Mapping output sample has enough reads"}

        // cm_not_enough_reads = competitive_mapping_ch_output
        //     .filter { it[3] == "false"} 
        //     .view{"Competitive Mapping output sample does not have enough reads. END OF THE PIPELINE"}


        // // WP5 -> Clockwork_ch is called only if  cm_enough_reads_ch exists. 
        // clockwork_ch = clockwork(cm_enough_reads_ch, params.ref_files)
        
        // // WP6
        // gnomonicus_ch = gnomonicus_workflow(clockwork_ch.final_vcf, params.tb_ref_genome, params.tb_amr_cat, params.tb_minor_alleles)
        // gnomonicus_json = gnomonicus_ch.gnomonicus_json

        // // WP7
        // fn5_ch = find_neighbour_5(clockwork_ch.final_fasta, "test", params.api_url, params.api_token)

        // // copy species specific files to bucket
        // clockwork_ch.final_fasta.concat(
        //     clockwork_ch.final_vcf,
        //     clockwork_ch.cortex_vcf,
        //     clockwork_ch.final_gvcf,
        //     clockwork_ch.samtools_vcf,
        //     clockwork_ch.map_bam,
        //     clockwork_ch.map_bam_bai,
        //     gnomonicus_ch.gnomonicus_json,
        //     fn5_ch.error_log,
        //     clockwork_ch.tb_clockwork_report_json,
        //     clockwork_ch.tb_clockwork_error_json,
        // ) | write_species_to_bucket

        // // WP8
        // summary(gatekeeper_ch.gatekeeper_report, 
        //     competitive_mapping_ch.cm_report, 
        //     lineagecalling_ch.json_report, 
        //     gnomonicus_json) 
        
        //copy to bucket
        gatekeeper_ch.gatekeeper_report.concat(
            gatekeeper_ch.kraken2_error,
            gatekeeper_ch.fastp_report,
            gatekeeper_ch.fastp_error,
            competitive_mapping_ch.cm_report,
            // call_wp4.out.competitivemapping_error_json,
            // lineagecalling_ch.lc_error_json,
            //lineagecalling_ch.json_report,
            //summary.out.main_report,
            //summary.out.error_report,
            human_read_removal_ch.hostile_report,
        ) | write_to_bucket

        // // copy fastq files to bucket
        // gatekeeper_ch.kraken2_filtered_samples.concat(
        //     gatekeeper_ch.kraken2_outputs,
        //     competitive_mapping_ch.cm_sample_paths,
        // ) | write_samples_to_bucket

}
