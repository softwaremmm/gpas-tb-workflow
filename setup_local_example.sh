mkdir -p data/inputs/1/1
mkdir -p data/inputs/2/1
mkdir -p data/outputs

# download simple examples
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR479/004/ERR4796484/ERR4796484_1.fastq.gz -O data/inputs/1/1/ERR4796484_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR479/004/ERR4796484/ERR4796484_2.fastq.gz -O data/inputs/1/1/ERR4796484_2.fastq.gz

wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR903/006/ERR9030326/ERR9030326.fastq.gz -O data/inputs/2/1/ERR9030326.fastq.gz
