process OPENMS_DECOYDATABASE {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/openms:2.8.0--h7ca0330_2' :
        'quay.io/biocontainers/openms:2.8.0--h7ca0330_2' }"
    input:
        tuple val(meta), path(fasta)
    output:
        tuple val(meta), path("*.fasta"), emit: decoy
        path "versions.yml"             , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.prefix ?: "${fasta.baseName}_decoy"
        """
        DecoyDatabase -in $fasta \\
            -out ${prefix}.fasta \\
            -decoy_string DECOY_ \\
            -decoy_string_position prefix
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            openms: \$(echo \$(FileInfo --help 2>&1) | sed 's/^.*Version: //; s/-.*\$//' | sed 's/ -*//; s/ .*\$//')
        END_VERSIONS
        """
}
