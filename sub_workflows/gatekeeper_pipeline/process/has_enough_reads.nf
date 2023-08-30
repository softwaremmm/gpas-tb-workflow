process has_enough_reads {
    container 'lhr.ocir.io/lrbvkel2wjot/gpas/pipeline-utils:latest'
    cpus = 1
    memory = "500MB"

    input:
    path(json)

    output:
    stdout

    script:

    """
    if grep -q "Not enough reads" ${json}; then
        echo "false" | tr -d '\n'
    else
        echo "true" | tr -d '\n'
    fi
    """

}
