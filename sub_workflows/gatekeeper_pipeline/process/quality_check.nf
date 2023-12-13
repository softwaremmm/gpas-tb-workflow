process fastp {
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/gatekeeper_pipeline:v0.0.3'

    cpus = 2
    memory = "4GB"

    debug true
    pod label: "name", value: "gatekeeper_pipeline:fastp"
    pod label: "sample_id", value: "${params.sample_id}"
    pod label: "run_id", value: "${params.run_id}"

    input:
    tuple val(sample_name), path(fq1), path(fq2)

    output:
    tuple val(sample_name), path("${sample_name}_cleaned_1.fastq.gz"), path("${sample_name}_cleaned_2.fastq.gz"), emit: fastp_fqs
    path "read_preprocessing_report.json", emit: fastp_json
    path "read_preprocessing_error.json", emit: fastp_error

    script:
    clean_fq1  = "${sample_name}_cleaned_1.fastq.gz"
    clean_fq2  = "${sample_name}_cleaned_2.fastq.gz"
    fastp_json = "read_preprocessing_report.json"
    fastp_error  = "read_preprocessing_error.json"
    fastp_html = "fastp.html"


    """
    if [ ${workflow.profile} == 'kubernetes' ]
    then
        echo "Running with kubernetes"
        /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
        trap 'PROCESS_EXIT=\$?; /bin/bash ${projectDir}/lib/s3fs_teardown.sh; exit \$PROCESS_EXIT;' EXIT
    fi

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
    --thread 16 \
    2>> tmp_error.txt || cat tmp_error.txt >> ${fastp_error}


    if [ -s ${fastp_error} ]; then
        echo "Fastp Fail"
        touch ${clean_fq1}
        touch ${clean_fq2}
        touch ${fastp_json}
        touch ${fastp_html}
        exit 1
    else
        echo "OK"
        touch ${fastp_error}
    fi
    """

    stub:
    clean_fq1  = "${sample_name}_cleaned_1.fastq.gz"
    clean_fq2  = "${sample_name}_cleaned_2.fastq.gz"
    fastp_json = "read_preprocessing_report.json"
    fastp_error  = "read_preprocessing_error.json"
    fastp_html = "fastp.html"



    """
    touch ${fastp_json}
    touch ${fastp_html}
    touch ${fastp_error}
    """
}
