process CIGAR_PARSER {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-61c59287265e27f2c4589cfc90013ef6c2c6acf1:fb3e48060a8c0e5108b1b60a2ad7e090cfb9eee5-0' :
        'quay.io/biocontainers/mulled-v2-61c59287265e27f2c4589cfc90013ef6c2c6acf1:fb3e48060a8c0e5108b1b60a2ad7e090cfb9eee5-0' }"
    input:
    tuple val(meta), path(reads), path(index), path(reference), val(protospacer), path(template), path(template_bam), path(reference_template), path(summary)
    output:
    tuple val(meta), path("*indels.csv"), path("*_subs-perc.csv"), emit: indels
    tuple val(meta), path("*.html"), path("*edits.csv")          , emit: edition
    tuple val(meta), path("*cutSite.json")                       , emit: cutsite
    path "versions.yml"                                          , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def template_bool = "${meta.template}" == "true" ? "--template_bool" : ""
    """
    Rscript ${workflow.launchDir}/bin/cigar_parser.R \\
        $args \\
        --input=$reads \\
        --output=$prefix \\
        --reference=$reference \\
        --gRNA_sequence=$protospacer \\
        --sample_name=$prefix \\
        --reference_template=$reference_template\\
        --template_bam=$template_bam\\
        --template=$template \\
        --summary_file=$summary \\
        $template_bool
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version)
    END_VERSIONS
    """
}
