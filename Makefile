run-nextflow:
	sudo nextflow run . -profile local,no_fn5 --sample_id 1 --run_id 1 --api_token "token" --species test \
	--seq_platform illumina -resume

clean:
	find . -type d -name .nextflow | xargs rm -rf
	find . -type d -name work | xargs rm -rf
	find . -type f -regex '.*\.nextflow\.log.*' | xargs rm -f
	find . -type f -regex 'trace*.txt' | xargs rm -f
