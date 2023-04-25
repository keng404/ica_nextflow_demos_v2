process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_single'
    container "quay.io/biocontainers/python:3.8.3"
    input:
    path samplesheet
    output:
    path '*.csv'        , emit: csv
    path  "versions.yml", emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    """
    python ${workflow.launchDir}/bin/check_samplesheet.py $samplesheet samplesheet.valid.csv $params.use_control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | grep -E -o \"([0-9]{1,}\\.)+[0-9]{1,}\")
    END_VERSIONS
    """
}
