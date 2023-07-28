process countReads {
    /**
    * @QCcheckpoint fail sample if there are < 100k raw reads
    */


    publishDir "${params.output_dir}/$sample_name", mode: 'copy', overwrite: 'true', pattern: '*{_err.json,_report.json}'

    input:
    tuple val(sample_name), path(fq1), path(fq2)

    output:
    tuple val(sample_name), path(fq1), path(fq2), stdout,  emit: countReads_fqs
    path "${sample_name}_err.json", emit: countReads_log optional true
    path "${sample_name}_report.json", emit: countReads_report optional true

    script:
    error_log = "${sample_name}_err.json"
    report_json = "${sample_name}_report.json"

    """
    num_reads=\$(fqtools count $fq1 $fq2)
    echo \$num_reads
    if (( \$num_reads > 1 )); then printf "${sample_name}"; else jq -n --arg key "\$num_reads" '{"error": ("sample did not have > 100k pairs of raw reads it only contained " + \$key)}' > ${error_log} && printf "fail" && jq -s ".[0] * .[1]" ${error_log} ${error_log} > ${report_json}; fi
    """


    stub:
    error_log = "${sample_name}_err.json"

    """
    printf ${params.countReads_runfastp}
    touch ${error_log}
    """
}