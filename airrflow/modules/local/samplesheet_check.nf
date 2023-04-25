process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_single'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.1.5' :
        'quay.io/biocontainers/pandas:1.1.5' }"
    input:
    path samplesheet
    output:
    path '*.tsv', emit: tsv
    path "versions.yml", emit: versions
    script: // This script is bundled with the pipeline, in nf-core/airrflow/bin/
    """
    python ${workflow.launchDir}/bin/check_samplesheet.py $samplesheet
    cp $samplesheet samplesheet.valid.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( echo \$(python --version | grep -o "[0-9\\. ]\\+") )
        pandas: \$(echo \$(python -c "import pkg_resources; print(pkg_resources.get_distribution('pandas').version)"))
    END_VERSIONS
    """
}
