process GENERATE_DIANN_CFG {
    label 'process_low'
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/sdrf-pipelines:0.0.21--pyhdfd78af_0"
    } else {
        container "quay.io/biocontainers/sdrf-pipelines:0.0.21--pyhdfd78af_0"
    }
    input:
    val(meta)
    output:
    path "diann_config.cfg", emit: search_cfg
    path "library_config.cfg", emit: library_config
    path "versions.yml", emit: version
    path "*.log"
    script:
    def args = task.ext.args ?: ''
    """
    python ${workflow.launchDir}/bin/prepare_diann_parameters.py generate \\
        --enzyme "${meta.enzyme}" \\
        --fix_mod "${meta.fixedmodifications}" \\
        --var_mod "${meta.variablemodifications}" \\
        --precursor_tolerence ${meta.precursormasstolerance} \\
        --precursor_tolerence_unit ${meta.precursormasstoleranceunit} \\
        --fragment_tolerence ${meta.fragmentmasstolerance} \\
        --fragment_tolerence_unit ${meta.fragmentmasstoleranceunit} \\
        |& tee GENERATE_DIANN_CFG.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sdrf-pipelines: \$(echo "0.0.21")
    END_VERSIONS
    """
}
