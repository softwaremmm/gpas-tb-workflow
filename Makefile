clean:
	find . -type d -name .nextflow | xargs rm -rf
	find . -type d -name work | xargs rm -rf
	find . -type f -regex '.*\.nextflow\.log.*' | xargs rm -f
	find . -type f -name 'trace*.txt' | xargs rm -f
	find . -type d -name .nf-test | xargs rm -rf

get-example-inputs:
	# Download example inputs
	bash setup_local_example.sh

clone-subworkflows:
	bash clone_sub_workflows.sh

get-big-kraken:
	# Download 20230605 Kraken2 database
	mkdir -p data/knowledge/kraken2_db
	wget -O data/knowledge/kraken2_db/kraken2_db.tar.gz https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20230605.tar.gz
	tar -xvzf data/knowledge/kraken2_db/kraken2_db.tar.gz -C data/knowledge/kraken2_db
	rm data/knowledge/kraken2_db/kraken2_db.tar.gz

get-small-kraken:
	# Download 20230605 Kraken2 database
	mkdir -p data/knowledge/kraken2_db
	wget -O data/knowledge/kraken2_db/k2_pluspfp_08gb_20231009.tar.gz https://genome-idx.s3.amazonaws.com/kraken/k2_pluspfp_08gb_20231009.tar.gz
	tar -xvzf data/knowledge/kraken2_db/k2_pluspfp_08gb_20231009.tar.gz -C data/knowledge/kraken2_db
	rm data/knowledge/kraken2_db/k2_pluspfp_08gb_20231009.tar.gz

get-ref-data:
	# Download reference data from bucket
	mkdir -p data/
	aws s3 sync s3://gpas_myco_reference_data/2.5.3/data/ data/ --no-sign-request --endpoint-url https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com


install-big-kraken: clone-subworkflows \
						get-ref-data \
						get-big-kraken

install-small-kraken: clone-subworkflows \
						get-ref-data \
						get-small-kraken
