process ALAKAZAM_LINEAGE {
    tag "$meta.id"
    label 'process_high'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-adaea5efbfa2a35669a6db7ddb1e1c8d5e60ef6e:031d6ccffe3e78cd908a83c2387b67eb856da7dd-0' :
        'quay.io/biocontainers/mulled-v2-adaea5efbfa2a35669a6db7ddb1e1c8d5e60ef6e:031d6ccffe3e78cd908a83c2387b67eb856da7dd-0' }"
    input:
    tuple val(meta), path(tab) // sequence tsv table in AIRR format
    output:
    tuple val(meta), path("${tab}"), emit: tab
    path "versions.yml" , emit: versions
    path("*.tsv")
    path("Clone_tree_plots/*.pdf"), emit: graph_plots optional true
    path("Graphml_trees/*.graphml"), emit: graph_export optional true
    script:
    def args = task.ext.args ?: ''
    """
    which dnapars > dnapars_exec.txt
    Rscript ${workflow.launchDir}/bin/lineage_reconstruction.R --repertoire ${tab} $args
    bash ${workflow.launchDir}/bin/merge_graphs.sh
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(echo \$(R --version 2>&1) | awk -F' '  '{print \$3}')
        alakazam: \$(Rscript -e "library(alakazam); cat(paste(packageVersion('alakazam'), collapse='.'))")
        changeo: \$( AssignGenes.py --version | awk -F' '  '{print \$2}' )
        pyhlip: 3.697
    END_VERSIONS
    """
}
