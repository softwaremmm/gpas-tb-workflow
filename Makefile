clean:
	find . -type d -name .nextflow | xargs rm -rf
	find . -type d -name work | xargs rm -rf
	find . -type f -regex '.*\.nextflow\.log.*' | xargs rm -f
	find . -type f -name 'trace*.txt' | xargs rm -f
	find . -type d -name .nf-test | xargs rm -rf

run-illumina:
	sudo nextflow run . -profile local --sample_id 1 --run_id 1 \
	--seq_platform illumina -resume

run-ont:
	sudo nextflow run . -profile local --sample_id 2 --run_id 1 \
	--seq_platform ont -resume

