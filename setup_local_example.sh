mkdir -p data/inputs/illumina
mkdir -p data/inputs/ont

# download simple examples
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR479/004/ERR4796484/ERR4796484_1.fastq.gz -O data/inputs/illumina/ERR4796484_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR479/004/ERR4796484/ERR4796484_2.fastq.gz -O data/inputs/illumina/ERR4796484_2.fastq.gz

wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR903/006/ERR9030326/ERR9030326.fastq.gz -O data/inputs/ont/ERR9030326.fastq.gz


MAKE_MIX=false
if [ "$MAKE_MIX" = true ]; then
    # download abscessus
    mkdir -p data/inputs/abscessus/illumina
    mkdir -p data/inputs/abscessus/ont

    wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR320/050/SRR32024550/SRR32024550_1.fastq.gz -O data/inputs/abscessus/illumina/SRR32024550_1.fastq.gz
    wget ftp.sra.ebi.ac.uk/vol1/fastq/SRR320/050/SRR32024550/SRR32024550_2.fastq.gz -O data/inputs/abscessus/illumina/SRR32024550_2.fastq.gz

    wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR160/065/ERR16089665/ERR16089665.fastq.gz -O data/inputs/abscessus/ont/ERR16089665.fastq.gz

    # use seqkit to make a 50 50 mix
    mkdir -p data/inputs/mix/illumina
    mkdir -p data/inputs/mix/ont
    numreads=100000

    seqkit head -n $numreads data/inputs/illumina/ERR4796484_1.fastq.gz -o data/inputs/mix/illumina/reads_1.fastq.gz
    seqkit head -n $numreads data/inputs/illumina/ERR4796484_2.fastq.gz -o data/inputs/mix/illumina/reads_2.fastq.gz
    seqkit head -n $numreads data/inputs/abscessus/illumina/SRR32024550_1.fastq.gz | gzip >> data/inputs/mix/illumina/reads_1.fastq.gz
    seqkit head -n $numreads data/inputs/abscessus/illumina/SRR32024550_2.fastq.gz | gzip >> data/inputs/mix/illumina/reads_2.fastq.gz

    numreads=10000

    seqkit head -n $numreads data/inputs/ont/ERR9030326.fastq.gz -o data/inputs/mix/ont/reads.fastq.gz
    seqkit head -n $numreads data/inputs/abscessus/ont/ERR16089665.fastq.gz | gzip >> data/inputs/mix/ont/reads.fastq.gz
fi
