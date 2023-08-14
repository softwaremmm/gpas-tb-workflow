WORKSPACE = ""
process fastp {
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/gatekeeper_pipeline:latest'
    input:
    tuple val(sample_name), path(fq1), path(fq2)

    output:
    tuple val(sample_name), path("${sample_name}_cleaned_1.fastq.gz"), path("${sample_name}_cleaned_2.fastq.gz"), emit: fastp_fqs
    path "fastp_report.json", emit: fastp_json
    path "fastp_error.json", emit: fastp_error
 
    script:
    clean_fq1  = "${sample_name}_cleaned_1.fastq.gz"
    clean_fq2  = "${sample_name}_cleaned_2.fastq.gz"
    fastp_json = "fastp_report.json"
    fastp_html = "fastp.html"
    fastp_error  = "fastp_error.json"

    """
    # FOR DEV PURPOSES ONLY

    echo "Running with kb8"
    s3fs "$WORKSPACE-dirtydata" /workspace/buckets/upload_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style
    s3fs "$WORKSPACE-readyforprocessing" /workspace/buckets/input_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style
    s3fs "$WORKSPACE-output" /workspace/buckets/output_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style
    s3fs "$WORKSPACE-relatedness" /workspace/buckets/relatedness_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style


    fastp -i $fq1 \
    -I $fq2 \
    -o ${sample_name}_cleaned_1.fastq.gz \
    -O ${sample_name}_cleaned_2.fastq.gz \
    -j ${fastp_json} -h ${fastp_html} \
    --length_required 50 \
    --low_complexity_filter \
    --cut_right \
    --cut_tail  \
    --detect_adapter_for_pe \
    --thread 16 &&\
    echo "OK" || 2> ${fastp_error}

    if [ -f ${fastp_error} ]; then
        touch ${clean_fq1}
        touch ${clean_fq2}
        touch ${fastp_json}
        touch ${fastp_html}
    else
        touch ${fastp_error}
    fi

    """

    stub:
    clean_fq1  = "${sample_name}_cleaned_1.fastq.gz"
    clean_fq2  = "${sample_name}_cleaned_2.fastq.gz"
    fastp_json = "fastp_report.json"
    fastp_html = "fastp.html"
    fastp_error  = "fastp_error.json"



    """
    touch ${fastp_json}
    touch ${fastp_html}
    touch ${fastp_error}
    """
}
