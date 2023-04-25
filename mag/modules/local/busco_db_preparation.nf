process BUSCO_DB_PREPARATION {
    tag "${database.baseName}"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"
    input:
    path database
    output:
    path "buscodb/*"    , emit: db
    path database       , emit: database
    path "versions.yml" , emit: versions
    script:
    """
    mkdir buscodb
    tar -xf ${database} -C buscodb
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version 2>&1 | sed -n 1p | sed 's/tar (GNU tar) //')
    END_VERSIONS
    """
}
