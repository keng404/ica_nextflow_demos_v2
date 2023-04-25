process TEMPLATE_REFERENCE {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-a1551cc3e69024a9d829751175a0fe30dd5035e8:666109dfd8ca00d6bbfab5188ff2735bfcc400d7-0' :
        'quay.io/biocontainers/mulled-v2-a1551cc3e69024a9d829751175a0fe30dd5035e8:666109dfd8ca00d6bbfab5188ff2735bfcc400d7-0' }"
    input:
    tuple val(meta), path(reference), path(template)
    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    path "versions.yml"             , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    Rscript ${workflow.launchDir}/bin/template_reference.R \\
        $args \\
        --reference=$reference \\
        --template=$template \\
        --prefix=$prefix
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version)
    END_VERSIONS
    """
}
