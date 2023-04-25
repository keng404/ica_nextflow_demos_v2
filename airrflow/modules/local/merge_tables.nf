process MERGE_TABLES {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-7da73314bcc47157b442d16c3dcfbe81e75a404f:9bb35f8114dffcd97b3afb5de8587355aca16b66-0' :
        'quay.io/biocontainers/mulled-v2-7da73314bcc47157b442d16c3dcfbe81e75a404f:9bb35f8114dffcd97b3afb5de8587355aca16b66-0' }"
    input:
    tuple val(meta), path(tab) // sequence tsv in AIRR format
    path samplesheet
    output:
    tuple val(meta), path("${meta.id}.tsv"), emit: tab // sequence tsv with metadata annotation in AIRR format
    script:
    """
    echo "${meta.id}"
    echo "${meta.samples}"
    echo "${tab}"
    echo "${tab.join('\n')}" > tab.list
    head -n 1 ${tab[0]} > ${meta.id}_preannotation.tsv
    tail -n +2 ${tab} >> ${meta.id}_preannotation.tsv
    # Remove line introduced by tail when merging multiple samples
    sed -i '/==>/d' ${meta.id}_preannotation.tsv
    Rscript ${workflow.launchDir}/bin/add_metadata.R --repertoire ${meta.id}_preannotation.tsv --samplesheet ${samplesheet} --outname "${meta.id}.tsv"
    """
}
