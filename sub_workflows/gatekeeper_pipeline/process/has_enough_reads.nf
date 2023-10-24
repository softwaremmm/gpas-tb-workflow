process has_enough_reads {
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/pipeline-utils:v0.0.2'
    cpus = 1
    memory = "500MB"

    input:
    path(json)

    output:
    stdout

    script:

    """
    if [[ ! -f ${json} ]] ; then
        echo 'File ${json} does not exist, aborting.'
        exit -1
    fi
    
    if grep -q "Not enough reads" ${json}; then
        echo -n "false"
    else
        echo -n "true"
    fi
    """

}
