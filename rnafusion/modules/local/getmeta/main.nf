process GET_META {
    tag 'getmeta'
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://containers.biocontainers.pro/s3/SingImgsRepo/biocontainers/v1.2.0_cv1/biocontainers_v1.2.0_cv1.img' :
        'biocontainers/biocontainers:v1.2.0_cv1' }"
    input:
    tuple val(meta), path(reads)
    path file
    output:
    tuple val(meta), path(file)     , emit: file
    script:
    """
    """
}
