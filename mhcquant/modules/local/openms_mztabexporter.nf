process OPENMS_MZTABEXPORTER {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/openms:2.8.0--h7ca0330_2' :
        'quay.io/biocontainers/openms:2.8.0--h7ca0330_2' }"
    input:
        tuple val(meta), path(mztab)
    output:
        tuple val(meta), path("*.mzTab"), emit: mztab
        path "versions.yml"             , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.prefix ?: "${meta.sample}_${meta.condition}"
        def args             = task.ext.args  ?: ''
        """
        MzTabExporter -in $mztab \\
            -out ${prefix}.mzTab \\
            -threads $task.cpus \\
            $args
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            openms: \$(echo \$(FileInfo --help 2>&1) | sed 's/^.*Version: //; s/-.*\$//' | sed 's/ -*//; s/ .*\$//')
        END_VERSIONS
        """
}
