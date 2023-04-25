// Import generic module functions
include { saveFiles } from './functions'
params.options = [:]
process GET_SOFTWARE_VERSIONS {
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'pipeline_info', meta:[:], publish_by_meta:[]) }
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }
    cache false
    input:
    path versions
    output:
    path "software_versions.tsv"     , emit: tsv
    path 'software_versions_mqc.yaml', emit: yaml
    script: // This script is bundled with the pipeline, in nf-core/bacass/bin/
    """
    echo $workflow.manifest.version > pipeline.version.txt
    echo $workflow.nextflow.version > nextflow.version.txt
    python ${workflow.launchDir}/bin/scrape_software_versions.py &> software_versions_mqc.yaml
    """
}
