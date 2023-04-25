process OPENMS_FEATURELINKERUNLABELEDKD {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/openms-thirdparty:2.8.0--h9ee0642_2' :
        'quay.io/biocontainers/openms-thirdparty:2.8.0--h9ee0642_2' }"
    input:
        tuple val(meta), path(features)
    output:
        tuple val(meta), path("*.consensusXML"), emit: consensusxml
        path "versions.yml"                    , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.prefix ?: "${meta.id}_all_features_merged"
        """
        FeatureLinkerUnlabeledKD -in $features \\
            -out '${prefix}.consensusXML' \\
            -threads $task.cpus
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            openms-thirdparty: \$(echo \$(FileInfo --help 2>&1) | sed 's/^.*Version: //; s/-.*\$//' | sed 's/ -*//; s/ .*\$//')
        END_VERSIONS
        """
}
