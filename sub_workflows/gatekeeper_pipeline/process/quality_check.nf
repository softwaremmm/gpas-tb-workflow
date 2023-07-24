process checkFqValidity {
    /**
    * @QCcheckpoint confirm that fqtools validates both fastqs
    */

    errorStrategy 'terminate'

    publishDir "${params.output_dir}/$sample_name", mode: 'copy', overwrite: 'true', pattern: '*{_err.json,_report.json}'

    input:
    tuple val(sample_name), path(fq1), path(fq2)

    output:
    tuple val(sample_name), path(fq1), path(fq2), stdout, emit: checkValidity_fqs
    path "${sample_name}_err.json", emit: checkValidity_log optional true
    path "${sample_name}_report.json", emit: checkValidity_report optional true

    script:
    error_log = "${sample_name}_err.json"
    report_json = "${sample_name}_report.json"

    """
    is_ok=\$(fqtools validate $fq1 $fq2)

    if [ \$is_ok == 'OK' ]; then printf 'OK'; else echo '{"error":"sample did not pass fqtools validation check"}' | jq '.' > ${error_log} && jq -s ".[0] * .[1]" ${error_log} ${error_log} > ${report_json}; fi
    """

    stub:
    error_log  = "${sample_name}_err.json"

    """
    printf ${params.checkFqValidity_isok}
    touch ${error_log}
    """
}

process fastp {

    publishDir "${params.output_dir}/$sample_name/raw_read_QC_reports", mode: 'copy', pattern: '*_fastp.json'
    publishDir "${params.output_dir}/$sample_name/output_reads", mode: 'copy', pattern: '*.fq.gz'
    publishDir "${params.output_dir}/$sample_name", mode: 'copy', overwrite: 'true', pattern: '*{_err.json,_fast.html,_report.json}'

    input:
    tuple val(sample_name), path(fq1), path(fq2)

    output:
    tuple val(sample_name), path("${sample_name}_cleaned_1.fq.gz"), path("${sample_name}_cleaned_2.fq.gz"), stdout, emit: fastp_fqs
    path("${sample_name}_fastp.json", emit: fastp_json)
    path "${sample_name}_err.json", emit: fastp_error optional true
    path "${sample_name}_report.json", emit: fastp_report optional true
   
    script:
    clean_fq1  = "${sample_name}_cleaned_1.fq.gz"
    clean_fq2  = "${sample_name}_cleaned_2.fq.gz"
    fastp_json = "${sample_name}_fastp.json"
    fastp_html = "${sample_name}_fastp.html"
    fastp_error  = "${sample_name}_err.json"
    report_json = "${sample_name}_report.json"

    """
    fastp -i $fq1 -I $fq2 -o ${clean_fq1} -O ${clean_fq2} -j ${fastp_json} -h ${fastp_html} --length_required 50 --average_qual 10 --low_complexity_filter --correction --cut_right --cut_tail --cut_tail_window_size 1 --cut_tail_mean_quality 20 &&\
    echo "OK" || 2> ${fastp_error}

    if [ -f ${fastp_error} ]; then
        touch ${clean_fq1}
        touch ${clean_fq2}
        touch ${fastp_json}
        touch ${fastp_html}
    fi
    """

    stub:
    clean_fq1  = "${sample_name}_cleaned_1.fq.gz"
    clean_fq2  = "${sample_name}_cleaned_2.fq.gz"
    fastp_json = "${sample_name}_fastp.json"
    fastp_html = "${sample_name}_fastp.html"
    fastp_error  = "${sample_name}_err.json"


    """
    touch ${clean_fq1}
    touch ${clean_fq2}
    touch ${fastp_json}
    touch ${fastp_html}
    """
}
