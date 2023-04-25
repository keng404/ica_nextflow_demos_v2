process ADD_META_TO_TAB {
    tag "$meta.id"
    label 'immcantation'
    label 'single_cpu'
    // TODO: update container
    container "immcantation/suite:devel"
    cache 'deep' // Without 'deep' this process would run when using -resume
    input:
    tuple val(meta), path(tab) // sequence tsv in AIRR format
    path(validated_input)
    output:
    tuple val(meta), path("*meta-pass.tsv"), emit: tab // sequence tsv in AIRR format
    path("*_command_log.txt"), emit: logs //process logs
    script:
    """
    # TODO: remove not relevant fields
    Rscript ${workflow.launchDir}/bin/reveal_add_metadata.R --repertoire "${tab}" --metadata "${validated_input}" --input_id "${meta.id}" --outname "${meta.id}" > "${meta.id}_add-meta_command_log.txt"
    """
}
