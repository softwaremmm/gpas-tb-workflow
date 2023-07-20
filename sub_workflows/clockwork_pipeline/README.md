# clockwork_pipeline
Nextflow Pipeline for clockwork, mycobacterial_mapping

## Running
* Clone the repo and `cd` into the created directory
* Run the following code
```
nextflow run . -profile local --sample_read ./data/inputs/1/1/
```

Under the `work` directory your output should be similar to the following
```
work
└── 51
    └── cbcbac4f68d43e365c67321b2ff844
        ├── Outdir
        │   └── 1
        │       ├── cortex
        │       │   ├── cortex.in.fofn
        │       │   ├── cortex.in.index
        │       │   ├── cortex.in.index_ref.fofn
        │       │   ├── cortex.log
        │       │   └── cortex.out
        │       │       ├── binaries
        │       │       │   └── uncleaned
        │       │       │       └── 31
        │       │       │           ├── sample.unclean.kmer31.q5.ctx
        │       │       │           ├── sample.unclean.kmer31.q5.ctx.build_log
        │       │       │           ├── sample.unclean.kmer31.q5.ctx.covg
        │       │       │           └── sample.unclean.kmer31.q5.ctx.covg.pdf
        │       │       ├── calls
        │       │       └── vcfs
        │       │           └── tmp_working
        │       ├── cortex.vcf
        │       ├── final.gvcf
        │       ├── final.gvcf.fasta
        │       ├── final.vcf
        │       ├── map.bam
        │       ├── map.bam.bai
        │       ├── samtools.vcf
        │       ├── tb_clockwork_error.json
        │       └── tb_clockwork_report.json
        ├── tuberculosis_1_1.fastq.gz -> /Users/Marc/temp/clockwork_pipeline/data/inputs/1/1/tuberculosis_1_1.fastq.gz
        └── tuberculosis_1_2.fastq.gz -> /Users/Marc/temp/clockwork_pipeline/data/inputs/1/1/tuberculosis_1_2.fastq.gz
```

In this example you are getting an empty cortex.vcf as the sample files do not contain enough data
