process CUSTOM_DUMPSOFTWAREVERSIONS {
    label 'process_single'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.17--pyhdfd78af_0' :
        'ghcr.io/dhslab/docker-python3:240110' }"
    input:
    path versions
    output:
    path "software_versions.yml"    , emit: yml
    path "software_versions_mqc.yml", emit: mqc_yml
    path "versions.yml"             , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    def args = task.ext.args ?: ''
	 template 'dumpsoftwareversions.py'
}
