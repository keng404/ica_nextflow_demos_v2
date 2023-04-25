process DRAGMAP_HASHTABLE {
    tag "$fasta"
    label 'process_high'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dragmap:1.2.1--hd4ca14e_0':
        'quay.io/biocontainers/dragmap:1.2.1--hd4ca14e_0' }"
    input:
    path fasta
    output:
    path "dragmap"      , emit: hashmap
    path "versions.yml" , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    def args = task.ext.args ?: ''
    """
    mkdir dragmap
    dragen-os \\
        --build-hash-table true \\
        --ht-reference $fasta \\
        --output-directory dragmap \\
        $args \\
        --ht-num-threads $task.cpus
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dragmap: \$(echo \$(dragen-os --version 2>&1))
    END_VERSIONS
    """
}
