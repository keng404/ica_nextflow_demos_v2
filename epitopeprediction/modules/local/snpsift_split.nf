process SNPSIFT_SPLIT {
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/snpsift:4.2--hdfd78af_5' :
        'quay.io/biocontainers/snpsift:4.2--hdfd78af_5' }"
    input:
    tuple val(meta), path(input_file)
    output:
    tuple val(meta), path("*.vcf"), emit: splitted
    path "versions.yml", emit: versions
    script:
    """
    SnpSift split ${input_file}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpsift: \$( echo \$(SnpSift split -h 2>&1) | sed 's/^.*version //' | sed 's/(.*//' | sed 's/t//g' )
    END_VERSIONS
    """
}
