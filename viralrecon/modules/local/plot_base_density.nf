process PLOT_BASE_DENSITY {
    tag "$fasta"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0' :
        'quay.io/biocontainers/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0' }"
    input:
    tuple val(meta), path(fasta)
    output:
    tuple val(meta), path('*.pdf'), emit: pdf
    tuple val(meta), path('*.tsv'), emit: tsv
    path "versions.yml"           , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script: // This script is bundled with the pipeline, in nf-core/viralrecon/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    Rscript ${workflow.launchDir}/bin/plot_base_density.r \\
        --fasta_files $fasta \\
        --prefixes $prefix \\
        --output_dir ./
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
    END_VERSIONS
    """
}
