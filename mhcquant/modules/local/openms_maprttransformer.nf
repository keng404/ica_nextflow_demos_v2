process OPENMS_MAPRTTRANSFORMER {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/openms:2.8.0--h7ca0330_2' :
        'quay.io/biocontainers/openms:2.8.0--h7ca0330_2' }"
    input:
        tuple val(meta), path(alignment_file), path(trafoxml)
    output:
        tuple val(meta), path("*_aligned.*"), emit: aligned
        path "versions.yml"                 , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.prefix ?: "${meta.id}_aligned"
        def fileExt          = alignment_file.collect { it.name.tokenize("\\.")[1] }.join(' ')
        """
        MapRTTransformer -in $alignment_file \\
            -trafo_in $trafoxml \\
            -out ${prefix}.${fileExt} \\
            -threads $task.cpus
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            openms: \$(echo \$(FileInfo --help 2>&1) | sed 's/^.*Version: //; s/-.*\$//' | sed 's/ -*//; s/ .*\$//')
        END_VERSIONS
        """
}
