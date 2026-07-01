mkdir -p data/inputs/illumina
mkdir -p data/inputs/ont

# download simple examples
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR479/004/ERR4796484/ERR4796484_1.fastq.gz -O data/inputs/illumina/ERR4796484_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR479/004/ERR4796484/ERR4796484_2.fastq.gz -O data/inputs/illumina/ERR4796484_2.fastq.gz

wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR903/006/ERR9030326/ERR9030326.fastq.gz -O data/inputs/ont/ERR9030326.fastq.gz
