process CREATE_DEMULTIPLEX_SAMPLESHEET {
    tag "${task.ext.prefix.id}"
    label 'process_low'
    container "ghcr.io/dhslab/docker-python3:231224"
    input:
    path(samplesheet)
    path(illumina_run_dir)
    output:
    path("*demux_samplesheet.csv"), emit: samplesheet
    path("*runinfo.csv")          , emit: runinfo
    path("versions.yml")          , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    """
    python ${workflow.launchDir}/bin/prepare_dragen_demux.py \\
        -r ${illumina_run_dir} \\
        -s ${samplesheet}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | awk '{print \$2}')
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix
    """
    touch \\
        ${prefix.id}.demux_samplesheet.csv \\
        ${prefix.id}.runinfo.csv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | awk '{print \$2}')
    END_VERSIONS
    """
}
