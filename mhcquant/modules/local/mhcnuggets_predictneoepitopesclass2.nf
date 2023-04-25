process MHCNUGGETS_PREDICTNEOEPITOPESCLASS2 {
    tag "$meta"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-c3f301504f7fa2e7bf81c3783de19a9990ea3001:12b1b9f040fd92a80629d58f8a558dde4820eb15-0' :
        'quay.io/biocontainers/mulled-v2-c3f301504f7fa2e7bf81c3783de19a9990ea3001:12b1b9f040fd92a80629d58f8a558dde4820eb15-0' }"
    input:
        tuple val(meta), path(neoepitopes), val(alleles)
    output:
        tuple val(meta), path("*.csv"), emit: csv
        path "versions.yml"           , emit: versions
    when:
        task.ext.when == null || task.ext.when
    script:
        def prefix           = task.ext.prefix ?: "${meta}_predicted_neoepitopes_class_2"
        """
    python ${workflow.launchDir}/bin/mhcnuggets_predict_peptides.py --peptides $neoepitopes \\
            --alleles '$alleles' \\
            --output ${prefix}.csv
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            mhcnuggets: \$(echo \$(python -c "import pkg_resources; print('mhcnuggets' + pkg_resources.get_distribution('mhcnuggets').version)" | sed 's/^mhcnuggets//; s/ .*\$//' ))
        END_VERSIONS
        """
}
