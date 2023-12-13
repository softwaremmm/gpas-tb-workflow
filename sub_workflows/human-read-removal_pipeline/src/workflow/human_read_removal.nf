include { process_hostile } from '../process/hostile.nf'

seq_platforms = ['ont', 'illumina']

workflow human_read_removal {
    take:
    fastq_files
    human_genome_dir
    seq_platform

    main:
    // Checks could be done at a higher level

    // seq_platform should be a String, not a channel
    if (seq_platform.getClass() != java.lang.String) {
        throw new Exception("seq_platform should be a string, not a ${seq_platform.getClass()}")
    }

    // Should be supported by this workflow
    if (! (seq_platform in seq_platforms)) {
        throw new Exception("seq platform invalid. Should be one of $seq_platforms!")
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

    hostile_output = process_hostile(fastq_files, human_genome_dir, seq_platform)

    emit:
    clean_fastq = hostile_output.clean_fastq
    hostile_report = hostile_output.hostile_report
}
