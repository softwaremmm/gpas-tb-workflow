#!/usr/bin/env nextflow

// sub workflows import
include { find_neighbour_6 } from "./sub_workflows/fn5_pipeline/main.nf"
include { clockwork } from "./sub_workflows/clockwork_pipeline/main.nf"
include { gatekeeper_myco } from "./sub_workflows/gatekeeper_pipeline/main.nf"
include { dynamic_competitive_mapping_wf } from "./sub_workflows/competitivemapping_pipeline/main.nf"
include { lineagecalling } from "./sub_workflows/lineagecalling_pipeline/main.nf"
include { gnomonicus_workflow } from "./sub_workflows/tb-predict-pipeline/main.nf"
include { summary } from "./sub_workflows/summary_pipeline/main.nf"
include { rundial } from "./sub_workflows/rundial/main.nf"

// the location in the buckets for the current run
// params can be overriden for local running
params.outdir = "${params.outputs_bucket}/${params.sample_id}/${params.run_id}"
params.sample_input_dir = "${params.inputs_bucket}/${params.sample_id}/${params.run_id}"

// Default file suffixes
params.input_paired_suffix = "*_{1,2}.fastq.gz"
params.input_single_suffix = "*.fastq.gz"

workflow {

    // metadata
    pipeline_versions_file = channel.fromPath("${projectDir}/PIPELINE_BUILD")
        .filter { it -> file(it).exists() == true }

    // This step is for provenance tracking only
    knowledge_ch = gather_knowledge(
        params.manifest,
        params.species_list,
        params.name_mapping,
        params.clockwork_ref,
        params.tb_ref_genome,
        params.tb_amr_cat,
        params.rundial_ref,
    )

    if (params.seq_platform == 'illumina') {
        clean_fastq_ch = channel.fromFilePairs("${params.sample_input_dir}/${params.input_paired_suffix}", checkIfExists: true, flat: false)
    }
    else if (params.seq_platform == 'ont') {
        clean_fastq_ch = channel.fromPath("${params.sample_input_dir}/${params.input_single_suffix}", checkIfExists: true)
            .map { it -> [it.getName().replaceFirst(/(?i)\.(fastq|fq)\.gz$/, ""), it] }
    }

    check_valid_input(clean_fastq_ch, params.seq_platform)

    // View first 3 so users can check if correct
    clean_fastq_ch.take(3).view()


    // Gatekeeper: Trimming and positive filtering of Kraken2 Unclassified and Mycobacteriaceae reads
    gatekeeper_ch = gatekeeper_myco(clean_fastq_ch, params.kraken2_db_path, params.seq_platform)

    //Create a new channel if the condition to test (enough Unclassifidies and Mycrobacteriae reads) and the channel to use to proceed the execution (paths)
    gatekeeper_ch_output = gatekeeper_ch.kraken2_filtered_samples.join(gatekeeper_ch.kraken2_enough_reads)

    gk_enough_reads_ch = gatekeeper_ch_output
        .filter { it -> it[2] == "true" }
        .map { it -> [it[0], it[1]] }
        .view { "Gatekeeper output sample has enough reads" }

    // print message if sample does not have enough reads to proceed
    gatekeeper_ch_output
        .filter { it -> it[2] != "true" }
        .view { "Gatekeeper output sample does not have enough reads. END OF THE PIPELINE" }

    //Pipeline proceeds only if gk_enough_reads_ch exists.

    // Speciation
    competitive_mapping_ch = dynamic_competitive_mapping_wf(
        gk_enough_reads_ch,
        params.ref_genome_dirs,
        params.sylph_dbs,
        params.taxonomy_files,
        params.fixed_refs,
        params.ref_for_fastqs,
        params.seq_platform,
    )
    lineagecalling_ch = lineagecalling(gk_enough_reads_ch, params.seq_platform)

    // (sample_name, ref_id, fastqs)
    cm_enough_reads_ch = competitive_mapping_ch.ref_reads
        .filter { it -> it[3] == "true" }
        .map { it -> [it[0], it[1], it[2]] }
        .view { it -> "Competitive Mapping output sample has enough reads for " + it[1] }


    // need to select reference fasta to use for assembly
    pick_reference(
        cm_enough_reads_ch.map { it -> [it[0], it[1]] },
        params.reference_genomes_dir,
    )


    // Clockwork/Rundial is called only if cm_enough_reads_ch exists.
    if (params.seq_platform == 'illumina') {
        println("Will run clockwork")
        reads_to_assemble = cm_enough_reads_ch.join(pick_reference.out.clockwork, by: [0, 1]).view()
        clockwork_ch = clockwork(
            reads_to_assemble
        )
        final_fasta_ch = clockwork_ch.final_fasta
        assembly_report = clockwork_ch.tb_clockwork_report_json
        assembler_files = clockwork_ch.final_fasta.concat(
            clockwork_ch.variants_vcf,
            clockwork_ch.cortex_vcf,
            clockwork_ch.all_calls_vcf,
            clockwork_ch.samtools_vcf,
            clockwork_ch.map_bam,
            clockwork_ch.map_bam_bai,
            clockwork_ch.tb_clockwork_report_json,
            clockwork_ch.tb_clockwork_error_json,
        )
        gnomonicus_input = clockwork_ch.variants_vcf.join(clockwork_ch.all_calls_vcf_decompressed, by: [0, 1])
    }
    else if (params.seq_platform == 'ont') {
        println("Will run rundial")
        reads_to_assemble = cm_enough_reads_ch.join(pick_reference.out.fasta, by: [0, 1]).view()
        rundial_ch = rundial(
            reads_to_assemble,
            params.clair3_model_dir,
            params.basecalling_model,
        )
        final_fasta_ch = rundial_ch.final_fasta
        assembly_report = rundial_ch.creation_report_json
        assembler_files = rundial_ch.alignment.concat(
            rundial_ch.gvcf,
            rundial_ch.final_fasta,
            rundial_ch.variants_vcf,
            rundial_ch.all_calls_vcf,
            rundial_ch.creation_report_json,
        )

        gnomonicus_input = rundial_ch.variants_vcf.join(rundial_ch.all_calls_vcf, by: [0, 1])
    }

    gnomonicus_input = gnomonicus_input.join(pick_reference.out.genbank, by: [0, 1])
    gnomonicus_ch = gnomonicus_workflow(gnomonicus_input, params.seq_platform)

    if (params.run_fn6 != "false") {
        // FN6 doesn't use tuple channels as not run locally
        find_neighbour_6(final_fasta_ch.map { it -> it[1] }, params.relatedness_species, params.api_url, params.api_token, params.relatedness_bucket, params.relatedness_pvc_saves, params.tb_ref, params.tb_mask, 20)
    }



    // Make summary
    // Rename mapping file so that summary python picks it up
    name_mapping_ch = rename_name_mapping(params.name_mapping)
    tb_gnomonicus_json = gnomonicus_ch.gnomonicus_json.filter { it -> it[1] == "Mycobacterium_tuberculosis" }
        .map { it -> [it[0], it[2]] }
    tb_assembly_report = assembly_report.filter { it -> it[1] == "Mycobacterium_tuberculosis" }
        .map { it -> [it[0], it[2]] }
    sample_reports = gatekeeper_ch.gatekeeper_report
        .mix(
            competitive_mapping_ch.report_json,
            lineagecalling_ch.json_report,
            tb_gnomonicus_json,
            tb_assembly_report,
        )
        .groupTuple()

    // force this channel to have a single item which is a tuple
    shared_reports = pipeline_versions_file
        .mix(
            knowledge_ch.knowledge,
            name_mapping_ch.name_mapping,
        )
        .toList()
        .map { it -> [it] }

    // Take cross product and combine lists
    // Should now have channel with elements like [sample_id, [report1, report2, ...]]
    all_reports_ch = sample_reports.combine(shared_reports).map { it -> [it[0], it[1] + it[2]] }
    summary(all_reports_ch)


    // Copy to buckets

    output_files = gatekeeper_ch.gatekeeper_report.mix(
        gatekeeper_ch.fastp_report,
        gatekeeper_ch.kraken2_outputs.map { it -> [it[0], it[1]] },
        gatekeeper_ch.kraken2_outputs.map { it -> [it[0], it[2]] },
        competitive_mapping_ch.report_csv,
        competitive_mapping_ch.report_json,
        competitive_mapping_ch.sylph_report,
        competitive_mapping_ch.sylph_query,
        competitive_mapping_ch.sylph_taxonomy_report,
        competitive_mapping_ch.depth_plot,
        lineagecalling_ch.json_report,
        summary.out.main_report,
    )

    // add fastqs to output list by flattening if needed
    output_files = output_files.mix(
        gatekeeper_ch.kraken2_filtered_samples.mix(
            gatekeeper_ch.fastp_fastqs,
        ).flatMap { reads, files ->
            def fileList = files instanceof List ? files : [files]

            fileList.collect { file ->
                tuple(reads, file)
            }
        }
    )

    write_to_bucket(output_files)


    // copy species specific files to bucket
    species_output_files = assembler_files.mix(
        gnomonicus_ch.gnomonicus_json,
        gnomonicus_ch.gnomonicus_vcf,
        gnomonicus_ch.gnomonicus_variants,
        gnomonicus_ch.gnomonicus_mutations,
        gnomonicus_ch.gnomonicus_effects,
        gnomonicus_ch.gnomonicus_predictions,
    ).map { it -> [it[0], it[1], it[2], "true"] }

    // add fastqs to output list by flattening if needed
    species_output_files = species_output_files.mix(
        cm_enough_reads_ch.flatMap { reads, ref_id, files ->
            def fileList = files instanceof List ? files : [files]

            fileList.collect { file ->
                tuple(reads, ref_id, file, "false")
            }
        }
    )

    write_species_to_bucket(species_output_files)
}

workflow check_valid_input {
    take:
    fastq_files
    seq_platform

    main:

    def supported_seq_platforms = ['illumina', 'ont']

    // seq_platform should be a String, not a channel
    if (seq_platform.getClass() != java.lang.String) {
        throw new Exception("seq_platform should be a string, not a ${seq_platform.getClass()}")
    }

    // Should be supported by this workflow
    if (!(seq_platform in supported_seq_platforms)) {
        throw new Exception("seq platform supported. Should be one of ${supported_seq_platforms}!")
    }

    // Check if correct number of fastq files
    if (seq_platform == 'ont') {
        fastq_files
            .filter { it ->
                it[1] instanceof Path
            }
            .ifEmpty {
                throw new Exception("invalid fastqs ~ ont expects a single fastq file provided as a path")
            }
    }
    else if (seq_platform == 'illumina') {
        fastq_files
            .filter { it ->
                it[1] instanceof Collection && it[1].size() == 2
            }
            .ifEmpty {
                throw new Exception("invalid fastqs ~ illumina expects 2 fastq files provided as a tuple")
            }
    }
}


process gather_knowledge {
    pod label: "name", value: "gpas-tb-workflow:gather_knowledge"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    path manifest
    path species_list
    path name_mapping
    path clockwork_ref
    path tb_ref_genome
    path tb_amr_cat
    path rundial_ref

    output:
    path ("knowledge.json"), emit: knowledge

    script:
    """
    echo '{' > knowledge.json
    echo '"manifest": "${manifest}",' >> knowledge.json
    echo '"species_list": "${species_list}",' >> knowledge.json
    echo '"name_mapping": "${name_mapping}",' >> knowledge.json
    echo '"ref_files": "${clockwork_ref}",' >> knowledge.json
    echo '"tb_ref_genome": "${tb_ref_genome}",' >> knowledge.json
    echo '"tb_amr_cat": "${tb_amr_cat}",' >> knowledge.json
    echo '"rundial_ref": "${rundial_ref}"' >> knowledge.json
    echo '}' >> knowledge.json
    """
}

process rename_name_mapping {
    // Rename name_mapping reference data file
    // for consumption by summary pipeline
    pod label: "name", value: "gpas-tb-workflow:rename_name_mapping"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    path name_mapping

    output:
    path ("name_mapping.csv"), emit: name_mapping

    script:
    """
    cp "${name_mapping}" name_mapping.csv
    """
}

process pick_reference {
    publishDir "${params.publish_dir}", enabled: params.publish_dir != "", mode: "copy", saveAs: { filename -> sample_name + "_" + filename }
    cpus 1
    maxRetries 2
    memory "1GB"

    pod label: "name", value: "gpas-tb-workflow:pick_reference"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), val(ref_id)
    path reference_genomes_dir

    output:
    tuple val(sample_name), val(ref_id), path("*.fasta.gz"), emit: fasta, optional: true
    tuple val(sample_name), val(ref_id), path("*.gbk"), path("*.csv"), path("*null_positions.txt"), emit: genbank, optional: true
    tuple val(sample_name), val(ref_id), path("clockwork"), emit: clockwork, optional: true

    script:
    """
    # should have a folder with same name as ref_id
    if [ ! -d "${reference_genomes_dir}/${ref_id}" ]; then
        echo "Reference genome directory ${reference_genomes_dir}/${ref_id} does not exist"
        exit 1
    fi

    cp -r ${reference_genomes_dir}/${ref_id}/* .
    """
}

process write_to_bucket {
    pod label: "name", value: "gpas-tb-workflow:write_to_bucket"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), path(output_file)

    script:
    """
    mkdir -p ${params.outdir}
    if [ "${params.sample_id}" == "LOCAL" ]
    then
        cp ${output_file} ${params.outdir}/${sample_name}_\$(basename ${output_file})
    else
        cp ${output_file} ${params.outdir}/${params.sample_id}_\$(basename ${output_file})
    fi
    """
}



process write_species_to_bucket {
    pod label: "name", value: "gpas-tb-workflow:write_species_to_bucket"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), val(ref_id), path(output_file), val(add_ref_prefix)

    script:
    """
    outdir=${params.outdir}/${ref_id}
    mkdir -p \${outdir}

    if [ "${params.sample_id}" == "LOCAL" ]
    then
        file_prefix=${sample_name}
    else
        file_prefix=${params.sample_id}
    fi

    if [ "${add_ref_prefix}" == "true" ]
    then
        file_prefix=\${file_prefix}_${ref_id}
    fi

    cp ${output_file} \${outdir}/\${file_prefix}_\$(basename ${output_file})
    """
}
