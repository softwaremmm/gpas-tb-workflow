run-nextflow-with-stub:
	nextflow run . -profile local -stub --sample_read .

run-nextflow:
	nextflow run . -profile local --sample_read .

clean:
	find . -type d -name .nextflow | xargs rm -rf
	find . -type d -name work | xargs rm -rf
	find . -type f -regex '.*\.nextflow\.log.*' | xargs rm -f
