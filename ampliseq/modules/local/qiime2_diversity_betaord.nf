process QIIME2_DIVERSITY_BETAORD {
    tag "${core.baseName}"
    label 'process_low'
    container "quay.io/qiime2/core:2022.8"
    input:
    tuple path(metadata), path(core)
    output:
    path("beta_diversity/*"), emit: beta
    path "versions.yml"     , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    """
    export XDG_CONFIG_HOME="\${PWD}/HOME"
    mkdir beta_diversity
    qiime emperor plot \\
        --i-pcoa ${core} \\
        --m-metadata-file ${metadata} \\
        --o-visualization ${core.baseName}-vis.qzv
    qiime tools export \\
        --input-path ${core.baseName}-vis.qzv \
        --output-path beta_diversity/${core.baseName}-PCoA
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS
    """
}
