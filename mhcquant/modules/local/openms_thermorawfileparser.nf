process OPENMS_THERMORAWFILEPARSER {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/thermorawfileparser:1.4.0--ha8f3691_0' :
        'quay.io/biocontainers/thermorawfileparser:1.4.0--ha8f3691_0' }"
    input:
        tuple val(meta), path(rawfile)
    output:
        tuple val(meta), path("*.mzML"), emit: mzml
        path "versions.yml"            , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.prefix ?: "${rawfile.baseName}"
        // The ThermoRawFileParser expects a input file which is transcribed to an indexed mzML (defined by '-f 2')
        """
        ThermoRawFileParser.sh \\
            -i $rawfile \\
            -f 2 \\
            -b ${prefix}.mzML
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            thermorawfileparser: \$(ThermoRawFileParser.sh --version)
        END_VERSIONS
        """
}
