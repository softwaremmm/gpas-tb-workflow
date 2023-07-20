process fastp {
    input:
    tuple val(sample_name), path(fq1), path(fq2)

    output:
    tuple val(sample_name), path("${sample_name}_cleaned_1.fq.gz"), path("${sample_name}_cleaned_2.fq.gz"), emit: fastp_fqs
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
    fastp -i $fq1 -I $fq2 -o ${sample_name}_cleaned_1.fq -O ${sample_name}_cleaned_2.fq -j ${fastp_json} -h ${fastp_html} --length_required 50 --average_qual 10 --low_complexity_filter --correction --cut_right --cut_tail --cut_tail_window_size 1 --cut_tail_mean_quality 20 &&\
    echo "OK" || 2> ${fastp_error}

    if [ -f ${fastp_error} ]; then
        touch ${clean_fq1}
        touch ${clean_fq2}
        touch ${fastp_json}
        touch ${fastp_html}
    else
        gzip ${sample_name}_cleaned_1.fq
        gzip ${sample_name}_cleaned_2.fq
    fi    
    """

    stub:
    clean_fq1  = "${sample_name}_cleaned_1.fq.gz"
    clean_fq2  = "${sample_name}_cleaned_2.fq.gz"
    fastp_json = "${sample_name}_fastp.json"
    fastp_html = "${sample_name}_fastp.html"
    fastp_error  = "${sample_name}_err.json"


    """
    touch ${fastp_json}
    touch ${fastp_html}
    touch ${clean_fq1}
    touch ${fastp_html}
    """
}
