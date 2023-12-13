include { get_hostile_clean_file_name; get_report_file_name; get_new_clean_file_name } from './utils/file_naming.nf'

clean_name = ''
new_clean_name = ''
clean_1_name = ''
clean_2_name = ''
new_clean_1_name = ''
new_clean_2_name = ''
hostile_report_file_name = ''

process process_hostile {
    container "lhr.ocir.io/lrbvkel2wjot/gpas/hostile:0.4.0"
    label 'hostile'
    cpus 4
    memory { seq_platform == 'ont' ? 16.GB * task.attempt : 8.GB * task.attempt }

    publishDir "outputs", mode: 'copy'

    errorStrategy 'retry'
    maxRetries 2

    debug true
    pod label: "name", value: "human-read-removal_pipeline:process_hostile"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), path(fqs)
    path(human_genome_dir)
    val(seq_platform)

    output:
    // Note: outputs are sorted automatically
    tuple val(sample_name), path("*.fastq.gz", includeInputs: false), emit: clean_fastq
    path hostile_report_file_name, emit: hostile_report

    stub:
    hostile_report_file_name = "decontamination-log.json"
    new_clean_name = get_new_clean_file_name(sample_name, 0)
    new_clean_1_name = get_new_clean_file_name(sample_name, 1)
    new_clean_2_name = get_new_clean_file_name(sample_name, 2)

    """
    if [ $seq_platform == 'ont' ]
    then
        touch ${new_clean_name}
    elif [ $seq_platform == 'illumina' ]
    then
        touch ${new_clean_1_name}
        touch ${new_clean_2_name}
    fi
    touch ${hostile_report_file_name}
    """

    script:
    println()
    log.info "=========== HOSTILE PROCESS ==========="
    log.info "Sample name: ${sample_name}, type: ${sample_name.getClass()}"
    log.info "Sequencing platform: ${seq_platform}, type: ${seq_platform.getClass()}"
    log.info "Fastqs:"
    for (fq in fqs){
        log.info "$fq, type: ${fq.getClass()}"
    }
    log.info "Human genome directory: ${human_genome_dir}, type: ${human_genome_dir.getClass()}"

    hostile_report_file_name = "decontamination-log.json"
    if (seq_platform == 'ont') {
        clean_name = get_hostile_clean_file_name(fqs[0], 0)
        new_clean_name = get_new_clean_file_name(sample_name, 0)
    }
    else if (seq_platform == 'illumina') {
        clean_1_name = get_hostile_clean_file_name(fqs[0], 1)
        clean_2_name = get_hostile_clean_file_name(fqs[1], 2)
        new_clean_1_name = get_new_clean_file_name(sample_name, 1)
        new_clean_2_name = get_new_clean_file_name(sample_name, 2)
    }

    template 'run_hostile.sh'
}

process hostile_consumer {
    input:
    tuple val(sample_name), path(fqs)

    output:
    val 'Done'

    script:
    log.info "===========HOSTILE CONSUMER PROCESS==========="
    log.info "Sample name: ${sample_name}, type: ${sample_name.getClass()}"
    log.info "Fastqs:"
    for (fq in fqs){
        log.info "$fq, type: ${fq.getClass()}"
    }
    """
    echo "hostile consumer"
    """
}
