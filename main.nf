#!/usr/bin/env nextflow
nextflow.enable.dsl=2

supported_seq_platforms = ['illumina', 'ont']

// the location in the buckets for the current run
outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id"
indir_for_sample = "$params.inputs_bucket/$params.sample_id/$params.run_id"
updir = "$params.uploads_bucket/$params.sample_id"
reldir = "$params.relatedness_bucket/$params.sample_id/$params.run_id"

// sub workflows import
subwork_folder = "./sub_workflows"
include { find_neighbour_5 } from "${subwork_folder}/fn5_pipeline/main.nf"
include { clockwork } from "${subwork_folder}/clockwork_pipeline/main.nf"
include { gatekeeper_myco } from "${subwork_folder}/gatekeeper_pipeline/main.nf"
include { competitive_mapping } from "${subwork_folder}/competitivemapping_pipeline/main.nf"
include { lineagecalling } from "${subwork_folder}/lineagecalling_pipeline/main.nf"
include { gnomonicus_workflow } from "${subwork_folder}/tb-predict-pipeline/main.nf"
include { summary } from "${subwork_folder}/summary_pipeline/main.nf"
include { run_sundial } from "${subwork_folder}/sundial/main.nf"

// metadata
pipeline_versions_file = Channel.fromPath( "${projectDir}/PIPELINE_BUILD" )
                                .filter{ file(it).exists() == true }

if (params.seq_platform == 'illumina') {
    clean_fastq_ch = Channel.fromFilePairs("${indir_for_sample}/*_{1,2}.fastq.gz", checkIfExists:true, flat:false).view()
}
else if (params.seq_platform == 'ont') {
    clean_fastq_ch = Channel.fromPath("${indir_for_sample}/*.fastq.gz", checkIfExists:true).map(it -> [it.simpleName, it]).first()
}

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
        path(sundial_ref)

    output:
        path("knowledge.json"), emit: knowledge

    script:
        """
        echo '{' > knowledge.json
        echo '"manifest": "${manifest}",' >> knowledge.json
        echo '"species_list": "${species_list}",' >> knowledge.json
        echo '"name_mapping": "${name_mapping}",' >> knowledge.json
        echo '"ref_files": "${ref_files}",' >> knowledge.json
        echo '"tb_ref_genome": "${tb_ref_genome}",' >> knowledge.json
        echo '"tb_amr_cat": "${tb_amr_cat}",' >> knowledge.json
        echo '"sundial_ref": "${sundial_ref}"' >> knowledge.json
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
        cp "${name_mapping}" name_mapping.csv
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
                                        params.sundial_ref)

        check_valid_input(clean_fastq_ch, params.seq_platform)

        // Gatekeeper: Trimming and positive filtering of Kraken2 Unclassified and Mycobacteriaceae reads
        gatekeeper_ch = gatekeeper_myco(clean_fastq_ch, params.kraken2_db_path, params.seq_platform)

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
            final_fasta_ch = clockwork_ch.final_fasta.map(it -> it[1])
            assemble_report = clockwork_ch.tb_clockwork_report_json.map(it -> it[1])
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
            gnomonicus_input = clockwork_ch.final_vcf.join(clockwork_ch.final_gvcf_decompressed)

        } else if (params.seq_platform == 'ont') {
            println "Running sundial"
            sundial_ch = run_sundial(cm_enough_reads_ch, params.sundial_ref, params.sundial_mask)
            final_fasta_ch = sundial_ch.final_fasta.map(it -> it[1])
            assemble_report = sundial_ch.sundial_report_json.map(it -> it[1])
            assembler_files = sundial_ch.alignment.concat(
                sundial_ch.gvcf,
                sundial_ch.final_fasta,
                sundial_ch.final_vcf,
                sundial_ch.full_consensus,
                sundial_ch.full_vcf,
                sundial_ch.sundial_report_json,
            )

            gnomonicus_input = sundial_ch.final_vcf.join(sundial_ch.full_vcf)
        }

        // WP6
        gnomonicus_ch = gnomonicus_workflow(gnomonicus_input, params.tb_ref_genome, params.tb_amr_cat, params.null_positions)
        gnomonicus_json = gnomonicus_ch.gnomonicus_json

        //WP7
        if (params.run_fn5 != "false") {
            fn5_ch = find_neighbour_5(final_fasta_ch, params.species, params.api_url, params.api_token, params.relatedness_bucket, params.tb_ref, params.tb_mask, 20)
        }

        // copy species specific files to bucket
        assembler_files.concat(gnomonicus_ch.gnomonicus_json)
            .map(it -> it[1]),concat(
                gnomonicus_ch.variants_csv,
                gnomonicus_ch.mutations_csv,
                gnomonicus_ch.effects_csv,
                gnomonicus_ch.predictions_csv
            )
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
            gnomonicus_ch.gnomonicus_json.map(it -> it[1])
        ).toList() | summary // WP8

        //copy to bucket
        gatekeeper_ch.gatekeeper_report.concat(
            gatekeeper_ch.fastp_report,
            gatekeeper_ch.kraken2_outputs.map{it -> [it[1]]},
            gatekeeper_ch.kraken2_outputs.map{it -> [it[2]]},
            competitive_mapping_ch.cm_report,
            lineagecalling_ch.json_report,
            summary.out.main_report,
        ) | write_to_bucket

        // copy fastq files to bucket
        write_samples_to_bucket(
            gatekeeper_ch.kraken2_filtered_samples.concat(
                competitive_mapping_ch.cm_sample_paths,
                gatekeeper_ch.fastp_fastqs
            ),
            params.seq_platform
        )
}
