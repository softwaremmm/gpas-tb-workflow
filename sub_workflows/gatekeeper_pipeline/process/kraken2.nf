project_dir = projectDir

process kraken2 {

    errorStrategy { sleep(Math.pow(2, task.attempt) * 60 as long); return 'retry' } //seconds
    maxRetries 5

    container 'lhr.ocir.io/lrbvkel2wjot/gpas/gatekeeper_pipeline:v0.0.2-rc1'
    cpus 4
    memory { 100.GB * (0.8 + (task.attempt/5)) }

    input:
    tuple val(sample_name), path(fq1), path(fq2)
    path(database)
    val (min_num_reads)

    output:
    tuple val(sample_name), path("speciation_report.txt"), path("kraken_json.json"), emit: kraken2_out
    tuple val(sample_name), path("mycobacterial_reads_1.fastq.gz"), path("mycobacterial_reads_2.fastq.gz"), emit: kraken2_filtering
    path "speciation_report.json", emit: gatekeeper_report_json optional true
    path "speciation_error.json", emit: kraken2_log optional true

    script:
    kraken2_report = "speciation_report.txt"
    kraken2_json = "kraken_json.json"
    error_log = "speciation_error.json"

    gatekeeper_report_json = "speciation_report.json"
    kraken2_filtered_reads_1 = "mycobacterial_reads_1.fastq"
    kraken2_filtered_reads_2 = "mycobacterial_reads_2.fastq"

    kraken2_names = "'unclassified' 'root' 'Bacteria' 'Mycobacteriaceae' 'Homo sapiens'"
    relevant_taxids = "0 1762" //Unclassified and Mycobacteriaceae Kraken2 Tax Ids

    """
    if [ ${workflow.profile} == 'kubernetes' ]
    then
        echo "Running with kubernetes"
        /bin/bash ${projectDir}/lib/s3fs_setup.sh $WORKSPACE
    fi

    jq -n '[]' > ${error_log}
    kraken2 --threads 6 --db ${database} --output ${kraken2_json} --report ${kraken2_report} --paired $fq1 $fq2
    python3 ${moduleDir}/../lib/read_kraken_report.py -filepath ${kraken2_report} -output_filepath ${gatekeeper_report_json} -kraken2_names ${kraken2_names}

    num_reads=\$(jq '[.unclassified, .Mycobacteriaceae] | add' ${gatekeeper_report_json})

    echo "Number of Unclassified and Mycobacteriaceae reads: \${num_reads}"

    if [ \$num_reads -ge ${min_num_reads} ]
      then
           # Sample has enough reads of Unclassified and Mycobacteriaceae

           python3 ${moduleDir}/../lib/kraken_tools/extract_kraken_reads.py\
                -k  ${kraken2_json}\
                -s1 $fq1\
                -s2 $fq2\
                -o  ${kraken2_filtered_reads_1}\
                -o2 ${kraken2_filtered_reads_2}\ --taxid ${relevant_taxids} --report ${kraken2_report} --include-children --fastq-output
           gzip ${kraken2_filtered_reads_1}
           gzip ${kraken2_filtered_reads_2}
       else
           echo "Sample does not have enough Unclassified and Mycobacteriaceae reads to continue"
           if [[ ! -e ${error_log} ]]; then echo '[{}]' > ${error_log}; fi
           jq '. += [{"num_reads_error":"Not enough reads"}]' ${error_log} > error_log.json.tmp
           mv error_log.json.tmp ${error_log}
           touch ${gatekeeper_report_json}
           touch ${kraken2_filtered_reads_1}.gz
           touch ${kraken2_filtered_reads_2}.gz
           if [[ ! -e ${kraken2_report} ]]; then touch ${kraken2_report}; fi
           if [[ ! -e ${kraken2_json} ]]; then touch ${kraken2_json}; fi
    fi

    if [ ${workflow.profile} == 'kubernetes' ]
    then
        /bin/bash ${projectDir}/lib/s3fs_teardown.sh
    fi    
    """

    stub:
    kraken2_report = "speciation_report.txt"
    kraken2_json = "kraken_json.json"
    error_log = "speciation_error.json"

    gatekeeper_report_json = "speciation_report.json"
    kraken2_filtered_reads_1 = "mycobacterial_reads_1.fastq.gz"
    kraken2_filtered_reads_2 = "mycobacterial_reads_2.fastq.gz"

    """
    touch ${kraken2_report}
    touch ${kraken2_json}
    touch ${error_log}
    touch ${gatekeeper_report_json}
    touch ${kraken2_filtered_reads_1}
    touch ${kraken2_filtered_reads_2}
    """
}
