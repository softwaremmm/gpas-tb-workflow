#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Kubernetes Related Buckets
if ("${workflow.profile}" != 'kubernetes') {
    params.uploads_bucket = "$projectDir/data/uploads"
    params.inputs_bucket = "$projectDir/data/inputs"
    params.outputs_bucket = "$projectDir/data/outputs"
    params.relatedness_bucket = "$projectDir/data/relatedness"
    params.knowledge_bucket = "$projectDir/data/relatedness/knowledge"
    params.kraken2_db_path = "${params.knowledge_bucket}/kraken2_db"
} else {
    params.uploads_bucket = "/workspace/buckets/upload_bucket"
    params.inputs_bucket = "/workspace/buckets/input_bucket"
    params.outputs_bucket = "/workspace/buckets/output_bucket"
    params.relatedness_bucket = "/workspace/buckets/relatedness_bucket"
    params.knowledge_bucket = "/workspace/buckets/relatedness_bucket/knowledge"
    params.kraken2_db_path = "$projectDir/kraken2_db"
}


// Run Configurations
params.sample_id = 1
params.run_id = 1
params.help = ''
params.api_url = 'https://dev.portal.gpas.world'
params.species = 'tb'
params.api_token = ''
// Currently only illumina supported for whole pipeline
params.seq_platform = ''
supported_seq_platforms = ['illumina', 'ont']

// the location in the buckets for the current run
outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id"
indir = "$params.inputs_bucket/$params.sample_id/$params.run_id"
updir = "$params.uploads_bucket/$params.sample_id"
reldir = "$params.relatedness_bucket/$params.sample_id/$params.run_id"

// knowledge parameters
params.manifest = "${params.knowledge_bucket}/manifest/manifest_20231001"
params.species_list = "${params.knowledge_bucket}/manifest/species_list_manifest_20231001.csv"
params.name_mapping = "${params.knowledge_bucket}/manifest/competitive_mapping_mykrobe_names_20231109.csv"
params.ref_files = "${params.knowledge_bucket}/clockwork/tb/Ref_prepare"
params.tb_ref_genome = "${params.knowledge_bucket}/tuberculosis_amr_catalogues/catalogues/NC_000962.3/NC_000962.3.gbk"
params.tb_amr_cat = "${params.knowledge_bucket}/tuberculosis_amr_catalogues/catalogues/NC_000962.3/NC_000962.3_WHO-UCN-GTB-PCI-2021.7_v1.1_GARC1_RFUS.csv"
params.tb_minor_alleles = "${params.knowledge_bucket}/minor_alleles.txt"
params.human_genome_dir = "${params.knowledge_bucket}/human-genome"
params.sundial_ref = "${params.knowledge_bucket}/sundial"
params.sundial_mask = "${params.knowledge_bucket}/sundial/compass-mask_20231215.bed"

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
include { run_sundial_snps } from "${subwork_folder}/sundial/main.nf"

// metadata
pipeline_versions_file = Channel.fromPath( "${projectDir}/PIPELINE_BUILD" )
                                .filter{ file(it).exists() == true }

if (params.seq_platform == 'illumina') {
    dirty_reads_ch = Channel.fromFilePairs("${updir}/*_{1,2}.fastq.gz", checkIfExists:true, flat:false).view()
}
else if (params.seq_platform == 'ont') {
    dirty_reads_ch = Channel.fromPath("${updir}/*.fastq.gz", checkIfExists:true).map(it -> [it.simpleName, it]).first()
}

// sample_id_ch = Channel.from(params.sample_id)
// fq1_ch = Channel.fromPath("/${updir}/*_1.fastq.gz")
// fq2_ch = Channel.fromPath("/${updir}/*_2.fastq.gz")
// dirty_reads_ch = sample_id_ch.merge(fq1_ch).merge(fq2_ch).map(it -> [it[0], [it[1], it[2]]])

process gather_knowledge {

    debug true
    pod label: "name", value: "gpas-tb-workflow:gather_knowledge"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    // Write knowledge (reference data) paths to JSON

    input:
        path(manifest)
        path(species_list)
        path(name_mapping)
        path(ref_files)
        path(tb_ref_genome)
        path(tb_amr_cat)
        path(tb_minor_alleles)
        path(human_genome_dir)
        path(sundial_ref)
        path(sundial_mask)

    output:
        path("knowledge.json"), emit: knowledge

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
            trap 'PROCESS_EXIT=\$?; /bin/bash ${projectDir}/lib/s3fs_teardown.sh; exit \$PROCESS_EXIT;' EXIT
        fi

        echo '{' > knowledge.json
        echo '"manifest": "${manifest}",' >> knowledge.json
        echo '"species_list": "${species_list}",' >> knowledge.json
        echo '"name_mapping": "${name_mapping}",' >> knowledge.json
        echo '"ref_files": "${ref_files}",' >> knowledge.json
        echo '"tb_ref_genome": "${tb_ref_genome}",' >> knowledge.json
        echo '"tb_amr_cat": "${tb_amr_cat}",' >> knowledge.json
        echo '"tb_minor_alleles": "${tb_minor_alleles}",' >> knowledge.json
        echo '"human_genome_dir": "${human_genome_dir}",' >> knowledge.json
        echo '"sundial_ref": "${sundial_ref}",' >> knowledge.json
        echo '"sundial_mask": "${sundial_mask}"' >> knowledge.json
        echo '}' >> knowledge.json
        """
}

process rename_name_mapping {

    // Rename name_mapping reference data file
    // for consumption by summary pipeline

    input:
        path(name_mapping)

    output:
        path("name_mapping.csv"), emit: name_mapping

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
            trap 'PROCESS_EXIT=\$?; /bin/bash ${projectDir}/lib/s3fs_teardown.sh; exit \$PROCESS_EXIT;' EXIT
        fi

        cp "${name_mapping}" name_mapping.csv
        """
}

process write_clean_reads_to_input {

    debug true
    pod label: "name", value: "gpas-tb-workflow:write_clean_reads_to_input"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
        tuple val(x), path(samples)
        val(seq_platform)

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
            trap 'PROCESS_EXIT=\$?; /bin/bash ${projectDir}/lib/s3fs_teardown.sh; exit \$PROCESS_EXIT;' EXIT
        fi

        mkdir -p ${indir}
        if [ $seq_platform == 'ont' ]
        then
            cp ${samples} ${indir}
        elif [ $seq_platform == 'illumina' ]
        then
            cp ${samples[0]} ${indir}
            cp ${samples[1]} ${indir}
        fi
        """
}

process write_to_bucket {

    debug true
    pod label: "name", value: "gpas-tb-workflow:write_to_bucket"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
        path(output_file)

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
            trap 'PROCESS_EXIT=\$?; /bin/bash ${projectDir}/lib/s3fs_teardown.sh; exit \$PROCESS_EXIT;' EXIT
        fi

        mkdir -p ${outdir}
        cp ${output_file} ${outdir}/${params.sample_id}_\$(basename ${output_file})
        """
}

process write_species_to_bucket {

    debug true
    pod label: "name", value: "gpas-tb-workflow:write_species_to_bucket"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
        path(output_file)

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
            trap 'PROCESS_EXIT=\$?; /bin/bash ${projectDir}/lib/s3fs_teardown.sh; exit \$PROCESS_EXIT;' EXIT
        fi

        mkdir -p ${outdir}/tb
        cp ${output_file} ${outdir}/tb/${params.sample_id}_\$(basename ${output_file})
        """
}

process write_samples_to_bucket {

    debug true
    pod label: "name", value: "gpas-tb-workflow:write_samples_to_bucket"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
        tuple val(x), path(samples)
        val(seq_platform)

    script:
        """
        if [ ${workflow.profile} == 'kubernetes' ]
        then
            echo "Running with kubernetes"
            /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
            trap 'PROCESS_EXIT=\$?; /bin/bash ${projectDir}/lib/s3fs_teardown.sh; exit \$PROCESS_EXIT;' EXIT
        fi

        mkdir -p ${outdir}
        if [ $seq_platform == 'ont' ]
        then
            cp ${samples} ${outdir}/${params.sample_id}_\$(basename ${samples})
        elif [ $seq_platform == 'illumina' ]
        then
            cp ${samples[0]} ${outdir}/${params.sample_id}_\$(basename ${samples[0]})
            cp ${samples[1]} ${outdir}/${params.sample_id}_\$(basename ${samples[1]})
        fi
        """
}

workflow check_valid_input {
    take:
        fastq_files
        seq_platform

    main:
        // seq_platform should be a String, not a channel
        if (seq_platform.getClass() != java.lang.String) {
            throw new Exception("seq_platform should be a string, not a ${seq_platform.getClass()}")
        }

        // Should be supported by this workflow
        if (! (seq_platform in supported_seq_platforms)) {
            throw new Exception("seq platform supported. Should be one of $supported_seq_platforms!")
        }

        // Check if correct number of fastq files
        if (seq_platform == 'ont') {
            fastq_files.filter {
                it -> it[1] instanceof Path
            }.ifEmpty{throw new Exception("invalid fastqs ~ ont expects a single fastq file provided as a path")}
        } else if (seq_platform == 'illumina') {
            fastq_files.filter {
                it -> it[1] instanceof Collection && it[1].size() == 2
            }.ifEmpty{throw new Exception("invalid fastqs ~ illumina expects 2 fastq files provided as a tuple")}
        }
}

workflow {
    main:

        // This step is for provenance tracking only
        knowledge_ch = gather_knowledge(params.manifest,
                                        params.species_list,
                                        params.name_mapping,
                                        params.ref_files,
                                        params.tb_ref_genome,
                                        params.tb_amr_cat,
                                        params.tb_minor_alleles,
                                        params.human_genome_dir,
                                        params.sundial_ref,
                                        params.sundial_mask)

        // wp2

        check_valid_input(dirty_reads_ch, params.seq_platform)

        human_read_removal_ch = human_read_removal(dirty_reads_ch, Channel.fromPath(params.human_genome_dir), params.seq_platform)
        clean_fastq_ch = human_read_removal_ch.clean_fastq
        
        write_clean_reads_to_input(clean_fastq_ch, params.seq_platform)

        // Gatekeeper: Trimming and positive filtering of Kraken2 Unclassified and Mycobacteriaceae reads
        gatekeeper_ch = gatekeeper(clean_fastq_ch, params.kraken2_db_path, params.seq_platform)

        //Create a new channel if the condition to test (enough Unclassifidies and Mycrobacteriae reads) and the channel to use to proceed the execution (paths)
        gatekeeper_ch_output = gatekeeper_ch.kraken2_filtered_samples.merge(gatekeeper_ch.kraken2_enough_reads)

        gk_enough_reads_ch = gatekeeper_ch_output
            .filter { it[2] == "true"} //A new channel will be created only if the it[2] (enough reads) is true
            .map(it -> [it[0], it[1]]) //The value for the new channel will have a tuble of sample name, [fastq path(s)]
            .view{"Gatekeeper output sample has enough reads"}

        gk_not_enough_reads_ch = gatekeeper_ch_output
            .filter { it[2] == "false"} //A new channel will be created only if the it[2] (enough reads) is true
            .view{"Gatekeeper output sample does not have enough reads. END OF THE PIPELINE"}


        //Pipeline proceeds only if gk_enough_reads_ch exists.

        // Speciation
        competitive_mapping_ch = competitive_mapping(gk_enough_reads_ch, params.manifest, params.species_list, params.seq_platform)
        lineagecalling_ch = lineagecalling(gk_enough_reads_ch, params.seq_platform)

        //Create a new channel if the condition to test (enough h37r-v reads) and the channel to use to proceed the execution (paths)
        competitive_mapping_ch_output = competitive_mapping_ch.cm_sample_paths.merge(competitive_mapping_ch.cm_enough_reads)


        cm_enough_reads_ch = competitive_mapping_ch_output
            .filter { it[2] == "true"}
            .map(it -> [it[0], it[1]])
            .view{"Competitive Mapping output sample has enough reads"}

        cm_not_enough_reads = competitive_mapping_ch_output
            .filter { it[2] == "false"}
            .view{"Competitive Mapping output sample does not have enough reads. END OF THE PIPELINE"}


        // WP5 -> Clockwork/Sundial_ch is called only if cm_enough_reads_ch exists.
        if (params.seq_platform == 'illumina') {
            println "Running clockwork"
            clockwork_ch = clockwork(cm_enough_reads_ch.map(it -> [it[0], it[1][0], it[1][1]]), params.ref_files)
            final_vcf_ch = clockwork_ch.final_vcf
            final_fasta_ch = clockwork_ch.final_fasta
            assemble_report = clockwork_ch.tb_clockwork_report_json
            assembler_files = clockwork_ch.final_fasta.concat(
                clockwork_ch.final_vcf,
                clockwork_ch.cortex_vcf,
                clockwork_ch.final_gvcf,
                clockwork_ch.samtools_vcf,
                clockwork_ch.map_bam,
                clockwork_ch.map_bam_bai,
                clockwork_ch.tb_clockwork_report_json,
                clockwork_ch.tb_clockwork_error_json,
            )
        } else if (params.seq_platform == 'ont') {
            println "Running sundial"
            sundial_ch = run_sundial_snps(cm_enough_reads_ch, params.sundial_ref, params.sundial_mask)
            final_vcf_ch = sundial_ch.final_vcf.map(it -> it[1])
            final_fasta_ch = sundial_ch.final_fasta.map(it -> it[1])
            assemble_report = sundial_ch.sundial_report_json.map(it -> it[1])
            assembler_files = sundial_ch.alignment.concat(
                sundial_ch.gvcf,
                sundial_ch.final_fasta,
                sundial_ch.final_vcf,
                sundial_ch.full_consensus,
                sundial_ch.variants_vcf,
                sundial_ch.sundial_report_json,
            ).map(it -> it[1])
        }

        // WP6
        gnomonicus_ch = gnomonicus_workflow(final_vcf_ch, params.tb_ref_genome, params.tb_amr_cat, params.tb_minor_alleles, final_fasta_ch)
        gnomonicus_json = gnomonicus_ch.gnomonicus_json

        //WP7
        fn5_ch = find_neighbour_5(final_fasta_ch, params.species, params.api_url, params.api_token)

        // copy species specific files to bucket
        assembler_files.concat(gnomonicus_ch.gnomonicus_json)
         | write_species_to_bucket

        // Make summary
        name_mapping_ch = rename_name_mapping(params.name_mapping)
        pipeline_versions_file.concat(
            knowledge_ch.knowledge,            
            gatekeeper_ch.gatekeeper_report,
            competitive_mapping_ch.cm_report,
            lineagecalling_ch.json_report,
            name_mapping_ch.name_mapping,
            assemble_report, // Want to update summarise, as current sundial just mimicks clockwork
            gnomonicus_ch.gnomonicus_json
        ).toList() | summary // WP8

        //copy to bucket
        gatekeeper_ch.gatekeeper_report.concat(
            gatekeeper_ch.fastp_report,
            gatekeeper_ch.kraken2_outputs.map{it -> [it[1]]},
            competitive_mapping_ch.cm_report,
            lineagecalling_ch.json_report,
            summary.out.main_report,
            human_read_removal_ch.hostile_report,
        ) | write_to_bucket

        // copy fastq files to bucket
        write_samples_to_bucket(
            gatekeeper_ch.kraken2_filtered_samples.concat(
                competitive_mapping_ch.cm_sample_paths
            ),
            params.seq_platform
        )
}
