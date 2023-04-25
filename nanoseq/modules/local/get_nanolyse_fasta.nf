process GET_NANOLYSE_FASTA {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://containers.biocontainers.pro/s3/SingImgsRepo/biocontainers/v1.2.0_cv1/biocontainers_v1.2.0_cv1.img' :
        'biocontainers/biocontainers:v1.2.0_cv1' }"
    output:
    path "*fasta.gz"  , emit: ch_nanolyse_fasta
    script:
    """
    curl \\
    -L https://github.com/wdecoster/nanolyse/raw/master/reference/lambda.fasta.gz \\
    -o lambda.fasta.gz
    """
}
