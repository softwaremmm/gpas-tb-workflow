project_dir = projectDir

process kraken2 {

    publishDir "${params.output_dir}/$sample_name/kraken2_filtered_reads", mode: 'copy', pattern: '*_kraken2_filtered_{1,2}.fastq', overwrite: 'true'
    publishDir "${params.output_dir}/$sample_name/speciation_reports_for_reads", mode: 'copy', pattern: '*_kraken_report.*'
    publishDir "${params.output_dir}/$sample_name", mode: 'copy', overwrite: 'true', pattern: '*{_err.json,_report.json}'

    input:
    tuple val(sample_name), path(fq1), path(fq2)
    path(database)

    output:
    tuple val(sample_name), path("${sample_name}_kraken_report.txt"), path("${sample_name}_kraken_report.json"), emit: kraken2_json
    tuple val(sample_name), path("${sample_name}_kraken2_filtered_1.fastq"), path("${sample_name}_kraken2_filtered_2.fastq"), emit: kraken2_filtering
    path "${sample_name}_gatekeeper_report.json", emit: gatekeeper_report_json optional true
    path "${sample_name}_err.json", emit: kraken2_log optional true
    path "${sample_name}_report.json", emit: kraken2_report optional true

    script:
    kraken2_report = "${sample_name}_kraken_report.txt"
    kraken2_json = "${sample_name}_kraken_report.json"
    error_log = "${sample_name}_err.json"
    report_json = "${sample_name}_report.json"
    gatekeeper_report_json = "${sample_name}_gatekeeper_report.json"
    kraken2_filtered_reads_1 = "${sample_name}_kraken2_filtered_1.fastq"
    kraken2_filtered_reads_2 = "${sample_name}_kraken2_filtered_2.fastq"

    """
    kraken2 --threads ${task.cpus} --db ${database} --output ${kraken2_json} --report ${kraken2_report} --paired $fq1 $fq2
    python3 ${baseDir}/lib/read_kraken_report.py -filepath ${kraken2_report} -output_filepath ${gatekeeper_report_json} -kraken2_keys 0 1 2 1762 9606
    python3  ${baseDir}/lib/kraken_tools/extract_kraken_reads.py\
    -k  ${kraken2_json}\
    -s1 $fq1\
    -s2 $fq2\
    -o  ${kraken2_filtered_reads_1}\
    -o2 ${kraken2_filtered_reads_2}\ --taxid 0 1762  --report ${kraken2_report} --include-children --fastq-output
    """

    stub:
    kraken2_report = "${sample_name}_kraken_report.txt"
    kraken2_json = "${sample_name}_kraken_report.json"
    kraken2_read_classification = "${sample_name}_read_classifications.txt"
    error_log = "${sample_name}_err.json"
    gatekeeper_report_json = "${sample_name}_gatekeeper_report.json"
    kraken2_filtered_reads_1 = "${sample_name}_kraken2_filtered_1.fastq"
    kraken2_filtered_reads_2 = "${sample_name}_kraken2_filtered_2.fastq"

    """
    touch ${kraken2_report}
    touch ${kraken2_json}
    touch ${error_log}
    touch ${gatekeeper_report_json}
    touch ${kraken2_filtered_reads_1}
    touch ${kraken2_filtered_reads_2}
    """
}
