#!/usr/bin/env nextflow
nextflow.enable.dsl=2


// Kubernetes Related Buckets
if ("$EXECUTOR" != 'k8s') {
    params.uploads_bucket = "./data/uploads"
    params.inputs_bucket = "./data/inputs"
    params.outputs_bucket = "./data/outputs"
    params.relatedness_bucket = "./data/relatedness"
} else {
    params.uploads_bucket = "/data/uploads"
    params.inputs_bucket = "/data/inputs"
    params.outputs_bucket = "/data/outputs"
    params.relatedness_bucket = "/data/relatedness"
}

// Run Configurations
params.sample_id = 1
params.run_id = 1

params.reads = "$params.uploads_bucket/$params.sample_id/$params.run_id/*_R{1,2}.fastq.gz"
params.minimap2_index = "./data/h37rv.mmi"
params.catalogue = "./data/mtb_catalogue.vcf"
params.outdir = "$params.outputs_bucket/$params.sample_id/$params.run_id/"
params.push = false
params.restApiUrl = "http://localhost:5000"


process preprocess {
    container "ubuntu:latest"

    input:
        tuple val(sample_id), path(reads)

    output:
        tuple path("*_filtered_R1.fastq.gz"), path("*_filtered_R2.fastq.gz"), path("speciation_report.json"), emit: filtered_reads_speciation
        path("qc_report.json", emit: qc_report)

    script:
        """
        gatekeeper.sh ${sample_id} ${reads[0]} ${reads[1]}
        echo 'tb' > speciation_report.json
        """

    stub:
        """
        echo "gatekeeper script got fastqs"
        touch aln_filtered_R2.fastq.gz
        touch aln_filtered_R1.fastq.gz
        touch qc_report.json
        echo 'tb' > speciation_report.json
        """
}

process mutation_calling {
    container "ubuntu:latest"

    input:
        tuple path(filtered_r1), path(filtered_r2), path(speciation)

    output:
        path("variants.vcf", emit: variants)

    script:
        """
        echo "mutation calling"
        minimap2 -ax map-ont ${params.minimap2_index} ${filtered_r1} ${filtered_r2} | samtools sort -o aln.bam
        samtools index aln.bam
        bcftools mpileup -Ou -f ${params.minimap2_index} aln.bam | bcftools call -mv -Oz -o variants.vcf
        """

    stub:
        """
        echo 'mutation calling'
        echo Running input
        echo touch aln.bam
        if [ 'call' == 'call' ]
        then
            echo "call mode"
            touch variants.vcf
        fi
        """
}

process resistance_prediction {
    container "ubuntu:latest"

    input:
        path(variants)

    output:
        path("resistance_report.json", emit: resistance_report)

    script:
        """
        gnomonicus ${variants} ${params.catalogue}
        """

    stub:
        """
        echo Running file
        touch resistance_report.json
        """
}

process push_qc_report {
    container "ubuntu:latest"

    input:
        path(json_report)

    script:
        """
        curl -X POST --header "Content-Type: application/json" --data @qc_report.json ${params.restApiUrl}/report
        """
}

// Note that nextflow does not allow you to use the same process more than once
process push_resistance_report {
    container "ubuntu:latest"

    input:
        path(json_report)

    script:
        """
        curl -X POST --header "Content-Type: application/json" --data @resistance_report.json ${params.restApiUrl}/report
        """
}

workflow {
    // Preprocess samples
    preprocess(Channel.fromFilePairs(params.reads, size: 2))

    if ( params.push )
        push_qc_report(preprocess.out.qc_report)

    // Mutation calling
    mutation_calling(preprocess.out.filtered_reads_speciation)

    // Predict resistance
    resistance_prediction(mutation_calling.out.variants)

    if ( params.push )
        push_resistance_report(resistance_prediction.out.resistance_report)
}

// Save the results to the output directory
//ch_qc_reports.dump(tag: "QC Reports", dest: "${params.outdir}/qc_reports")
//ch_resistance_reports.dump(tag: "Resistance Reports", dest: "${params.outdir}/resistance_reports")
