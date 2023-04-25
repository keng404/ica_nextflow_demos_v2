process MHCFLURRY_PREDICTNEOEPITOPESCLASS1 {
    tag "$meta"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-c3f301504f7fa2e7bf81c3783de19a9990ea3001:12b1b9f040fd92a80629d58f8a558dde4820eb15-0' :
        'quay.io/biocontainers/mulled-v2-c3f301504f7fa2e7bf81c3783de19a9990ea3001:12b1b9f040fd92a80629d58f8a558dde4820eb15-0' }"
    input:
        tuple val(meta), val(allotypes), path(neoepitopes)
    output:
        tuple val(meta), path("*.csv"), emit: csv
        path "versions.yml"           , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.suffix ?: "${neoepitopes}_${meta}_predicted_neoepitopes_class_1"
        """
        mhcflurry-downloads --quiet fetch models_class1
    python ${workflow.launchDir}/bin/mhcflurry_neoepitope_binding_prediction.py $allotypes ${prefix}.csv
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            mhcflurry: \$(echo \$(mhcflurry-predict --version 2>&1 | sed 's/^mhcflurry //; s/ .*\$//') )
        END_VERSIONS
        """
}
