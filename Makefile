run-nextflow-with-stub:
	nextflow run . -profile local -stub

run-nextflow:
	nextflow run . -profile local

clean:
	find . -type d -name .nextflow | xargs rm -rf
	find . -type d -name work | xargs rm -rf
	find . -type f -regex '.*\.nextflow\.log.*' | xargs rm -f
