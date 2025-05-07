#!/usr/bin/env nextflow

// sub workflows import
include { find_neighbour_5 } from "./sub_workflows/fn5_pipeline/main.nf"
include { clockwork } from "./sub_workflows/clockwork_pipeline/main.nf"
include { gatekeeper_myco } from "./sub_workflows/gatekeeper_pipeline/main.nf"
include { competitive_mapping } from "./sub_workflows/competitivemapping_pipeline/main.nf"
include { lineagecalling } from "./sub_workflows/lineagecalling_pipeline/main.nf"
include { gnomonicus_workflow } from "./sub_workflows/tb-predict-pipeline/main.nf"
include { summary } from "./sub_workflows/summary_pipeline/main.nf"
include { run_sundial } from "./sub_workflows/sundial/main.nf"

// the location in the buckets for the current run
// params can be overriden for local running
params.outdir = "${params.outputs_bucket}/${params.sample_id}/${params.run_id}"
params.sample_input_dir = "${params.inputs_bucket}/${params.sample_id}/${params.run_id}"

// Default file suffixes
params.input_paired_suffix = "*_{1,2}.fastq.gz"
params.input_single_suffix = "*.fastq.gz"

workflow {

    // metadata
    pipeline_versions_file = Channel
        .fromPath("${projectDir}/PIPELINE_BUILD")
        .filter { file(it).exists() == true }

    // This step is for provenance tracking only
    knowledge_ch = gather_knowledge(
        params.manifest,
        params.species_list,
        params.name_mapping,
        params.ref_files,
        params.tb_ref_genome,
        params.tb_amr_cat,
        params.sundial_ref,
    )

    if (params.seq_platform == 'illumina') {
        clean_fastq_ch = Channel.fromFilePairs("${params.sample_input_dir}/${params.input_paired_suffix}", checkIfExists: true, flat: false)
    }
    else if (params.seq_platform == 'ont') {
        clean_fastq_ch = Channel
            .fromPath("${params.sample_input_dir}/${params.input_single_suffix}", checkIfExists: true)
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
        .filter { it[2] == "true" }
        .map { it -> [it[0], it[1]] }
        .view { "Gatekeeper output sample has enough reads" }

    gk_not_enough_reads_ch = gatekeeper_ch_output
        .filter { it[2] != "true" }
        .view { "Gatekeeper output sample does not have enough reads. END OF THE PIPELINE" }

    //Pipeline proceeds only if gk_enough_reads_ch exists.

    // Speciation
    competitive_mapping_ch = competitive_mapping(gk_enough_reads_ch, params.manifest, params.species_list, params.seq_platform)
    lineagecalling_ch = lineagecalling(gk_enough_reads_ch, params.seq_platform)

    //Create a new channel if the condition to test (enough h37r-v reads) and the channel to use to proceed the execution (paths)
    competitive_mapping_ch_output = competitive_mapping_ch.cm_tb_reads.join(competitive_mapping_ch.cm_enough_reads)


    cm_enough_reads_ch = competitive_mapping_ch_output
        .filter { it[2] == "true" }
        .map { it -> [it[0], it[1]] }
        .view { "Competitive Mapping output sample has enough reads" }

    cm_not_enough_reads = competitive_mapping_ch_output
        .filter { it[2] != "true" }
        .view { "Competitive Mapping output sample does not have enough reads. END OF THE PIPELINE" }


    // Clockwork/Sundial_ch is called only if cm_enough_reads_ch exists.
    if (params.seq_platform == 'illumina') {
        println("Will run clockwork")
        clockwork_ch = clockwork(cm_enough_reads_ch, params.ref_files)
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
        gnomonicus_input = clockwork_ch.final_vcf.join(clockwork_ch.final_gvcf_decompressed)
    }
    else if (params.seq_platform == 'ont') {
        println("Will run sundial")
        sundial_ch = run_sundial(cm_enough_reads_ch, params.sundial_ref, params.sundial_mask)
        final_fasta_ch = sundial_ch.final_fasta
        assemble_report = sundial_ch.sundial_report_json
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

    gnomonicus_ch = gnomonicus_workflow(gnomonicus_input, params.seq_platform, params.tb_ref_genome, params.tb_amr_cat, params.null_positions)

    if (params.run_fn5 != "false") {
        // FN5 doesn't use tuple channels as not run locally
        find_neighbour_5(final_fasta_ch.map {it[1]}, params.species, params.api_url, params.api_token, params.relatedness_bucket, params.tb_ref, params.tb_mask, 20)
    }



    // Make summary
    // Rename mapping file so that summary python picks it up
    name_mapping_ch = rename_name_mapping(params.name_mapping)
    sample_reports = gatekeeper_ch.gatekeeper_report
        .mix(
            competitive_mapping_ch.cm_report,
            lineagecalling_ch.json_report,
            gnomonicus_ch.gnomonicus_json,
            assemble_report,
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

    // copy species specific files to bucket
    assembler_files.mix(gnomonicus_ch.gnomonicus_json)
        | write_species_to_bucket

    //copy to bucket
    gatekeeper_ch.gatekeeper_report.mix(
        gatekeeper_ch.fastp_report,
        gatekeeper_ch.kraken2_outputs.map { it -> [it[0], it[1]] },
        gatekeeper_ch.kraken2_outputs.map { it -> [it[0], it[2]] },
        competitive_mapping_ch.cm_report,
        competitive_mapping_ch.cm_csv,
        lineagecalling_ch.json_report,
        summary.out.main_report,
    )
        | write_to_bucket

    // copy fastq files to bucket
    write_samples_to_bucket(
        gatekeeper_ch.kraken2_filtered_samples.mix(
            competitive_mapping_ch.cm_tb_reads,
            gatekeeper_ch.fastp_fastqs,
        ),
        params.seq_platform,
    )
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
    path ref_files
    path tb_ref_genome
    path tb_amr_cat
    path sundial_ref

    output:
    path ("knowledge.json"), emit: knowledge

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
    tuple val(sample_name), path(output_file)

    script:
    """
    outdir=${params.outdir}/${params.species}
    mkdir -p \${outdir}
    if [ "${params.sample_id}" == "LOCAL" ]
    then
        cp ${output_file} \${outdir}/${sample_name}_\$(basename ${output_file})
    else
        cp ${output_file} \${outdir}/${params.sample_id}_\$(basename ${output_file})
    fi
    """
}

process write_samples_to_bucket {
    pod label: "name", value: "gpas-tb-workflow:write_samples_to_bucket"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), path(samples)
    val seq_platform

    script:
    """
    mkdir -p ${params.outdir}
    root_name=${params.sample_id}
    if [ "${params.sample_id}" == "LOCAL" ]
    then
        root_name=${sample_name}
    fi

    if [ ${seq_platform} == 'ont' ]
    then
        cp ${samples} ${params.outdir}/\${root_name}_\$(basename ${samples})
    elif [ ${seq_platform} == 'illumina' ]
    then
        cp ${samples[0]} ${params.outdir}/\${root_name}_\$(basename ${samples[0]})
        cp ${samples[1]} ${params.outdir}/\${root_name}_\$(basename ${samples[1]})
    fi
    """
}
