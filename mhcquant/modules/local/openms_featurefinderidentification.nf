process OPENMS_FEATUREFINDERIDENTIFICATION  {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/openms:2.8.0--h7ca0330_2' :
        'quay.io/biocontainers/openms:2.8.0--h7ca0330_2' }"
    input:
    tuple val(meta), path(id_quant_int), path(mzml), path(id_quant)
    output:
        tuple val(meta), path("*.featureXML"), emit: featurexml
        path "versions.yml"                  , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.prefix ?: "${meta.sample}_${meta.id}"
        def arguments        = params.quantification_fdr ? "-id $id_quant_int -id_ext $id_quant -svm:min_prob ${params.quantification_min_prob}" : "-id $id_quant"
        """
        FeatureFinderIdentification -in $mzml \\
            -out ${prefix}.featureXML \\
            -threads $task.cpus \\
            ${arguments}
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            openms: \$(echo \$(FileInfo --help 2>&1) | sed 's/^.*Version: //; s/-.*\$//' | sed 's/ -*//; s/ .*\$//')
        END_VERSIONS
        """
}
