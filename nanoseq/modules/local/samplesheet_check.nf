process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"
    input:
    path samplesheet
    val input_path
    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions
    script: // This script is bundled with the pipeline, in nf-core/nanoseq/bin/
    updated_path = workflow.profile.contains('test_nobc_nodx_rnamod') ? "$input_path" : "not_changed"
    """
    python ${workflow.launchDir}/bin/check_samplesheet.py \\
        $samplesheet \\
        $updated_path \\
        samplesheet.valid.csv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}