run-nextflow-with-stub:
	nextflow run . -profile local -stub

run-nextflow:
	nextflow run . -profile local

clean:
	find . -type d -name .nextflow | xargs rm -rf
	find . -type d -name work | xargs rm -rf
	find . -type f -regex '.*\.nextflow\.log.*' | xargs rm -f

debug:
	docker run --rm -it -v /mnt/volume_data:/mnt/volume_data --network host --name debug-container lhr.ocir.io/lrbvkel2wjot/gpas/gatekeeper_pipeline:latest /bin/bash 

test-main-workflow:
	sudo nextflow run . --sample_id WTCHG_885333_73205296_1 -profile local