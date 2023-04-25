process OPENMS_MAPALIGNERIDENTIFICATION {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/openms:2.8.0--h7ca0330_2' :
        'quay.io/biocontainers/openms:2.8.0--h7ca0330_2' }"
    input:
        tuple val(meta), path(idxml)
    output:
        tuple val(meta), path("*.trafoXML"), emit: trafoxml
        path "versions.yml"                , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def out_names        = idxml.collect { it.baseName+'.trafoXML' }.join(' ')
        def args             = task.ext.args  ?: ''
        """
        MapAlignerIdentification -in $idxml \\
            -trafo_out ${out_names} \\
            $args
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            openms: \$(echo \$(FileInfo --help 2>&1) | sed 's/^.*Version: //; s/-.*\$//' | sed 's/ -*//; s/ .*\$//')
        END_VERSIONS
        """
}
