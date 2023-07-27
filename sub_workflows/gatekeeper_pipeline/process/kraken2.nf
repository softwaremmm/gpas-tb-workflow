project_dir = projectDir


process kraken2 {

    container 'lhr.ocir.io/lrbvkel2wjot/gpas/gatekeeper_pipeline:latest'


    input:
    tuple val(sample_name), path(fq1), path(fq2)
    val (min_num_reads)
    path(database)

    output:
    tuple val(sample_name), path("${sample_name}_kraken_report.txt"), path("${sample_name}_kraken_report.json"), emit: kraken2_out
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
    kraken2_names = "'unclassified' 'root' 'Bacteria' 'Mycobacteriaceae' 'Homo sapiens'"
    relevant_taxids = "0 1762" //Unclassified and Mycobacteriaceae Kraken2 Tax Ids

    """
    echo ${baseDir}
    echo ${moduleDir}
    kraken2 --threads ${task.cpus} --db ${database} --output ${kraken2_json} --report ${kraken2_report} --paired $fq1 $fq2
    python3 ${moduleDir}/../lib/read_kraken_report.py -filepath ${kraken2_report} -output_filepath ${gatekeeper_report_json} -kraken2_names ${kraken2_names}

    num_reads=\$(jq '[.unclassified, .Mycobacteriaceae] | add' ${gatekeeper_report_json})

    echo "Number of Unclassified and Mycobacteriaceae reads: \${num_reads}"



    if [[ \$num_reads -ge $min_num_reads ]]
      then
           echo "Sample has enough reads of Unclassified and Mycobacteriaceae"
           python3 ${moduleDir}/../lib/kraken_tools/extract_kraken_reads.py\
                -k  ${kraken2_json}\
                -s1 $fq1\
                -s2 $fq2\
                -o  ${kraken2_filtered_reads_1}\
                -o2 ${kraken2_filtered_reads_2}\ --taxid ${relevant_taxids} --report ${kraken2_report} --include-children --fastq-output
       else
           echo "Sample does not have enough Unclassified and Mycobacteriaceae reads to continue"
           if [[ ! -e ${error_log} ]]; then echo '{}' > ${error_log}; fi
           jq '.num_reads_error="Not enough reads"' ${error_log} > temp.json && mv temp.json ${error_log}
           touch ${gatekeeper_report_json}
           touch ${kraken2_filtered_reads_1}
           touch ${kraken2_filtered_reads_2}
           if [[ ! -e ${kraken2_report} ]]; then touch ${kraken2_report}; fi
           if [[ ! -e ${kraken2_json} ]]; then touch ${kraken2_json}; fi
    fi

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