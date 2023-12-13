#!/bin/bash


call_hostile() {
    echo "bash script started at `date`"
    sleep 5

    echo workspace: $WORKSPACE
    if [ ${workflow.profile} == 'kubernetes' ]
    then
        echo "Running with kubernetes"
        echo $projectDir
        /bin/bash $projectDir/lib/s3fs_setup.sh $WORKSPACE
    fi



    echo "Sample name: $sample_name"
    echo "Sequencing platform: $seq_platform"
    echo "fastqs: $fqs"
    echo "Human genome dir: $human_genome_dir"

    if [ $seq_platform == 'ont' ]
    then
        hostile clean --rename --reorder --threads 3 \
            --fastq1 ${fqs[0]}  \
            --index $human_genome_dir/human-t2t-hla-argos985-mycob140.fa.gz \
            --out-dir . > decontamination-log.json || exit 1

        echo "Renaming files"
        echo "$clean_name to $new_clean_name"
        mv $clean_name $new_clean_name
    elif [ $seq_platform == 'illumina' ]
    then
        hostile clean --rename --reorder --threads 3 \
            --fastq1 ${fqs[0]} \
            --fastq2 ${fqs[1]} \
            --index $human_genome_dir/human-t2t-hla-argos985-mycob140 \
            --out-dir . > decontamination-log.json || exit 1

        echo "Renaming files"
        echo "$clean_1_name to $new_clean_1_name"
        echo "$clean_2_name to $new_clean_2_name"
        mv $clean_1_name $new_clean_1_name
        mv $clean_2_name $new_clean_2_name
    fi


    if [ ${workflow.profile} == 'kubernetes' ]
    then
        /bin/bash ${projectDir}/lib/s3fs_teardown.sh
    fi

    echo "bash script completed"
}

call_hostile
