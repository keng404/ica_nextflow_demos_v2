process SHAZAM_THRESHOLD {
    tag "$meta.id"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-db80433cc6df75bc43a5fd7bfa7529a7df8cfe15:f0e1329252bbc0f36a8656cfa655cf205da30e5b-0' :
        'quay.io/biocontainers/mulled-v2-db80433cc6df75bc43a5fd7bfa7529a7df8cfe15:f0e1329252bbc0f36a8656cfa655cf205da30e5b-0' }"
    input:
    tuple val(meta), path(tab) // tsv tab in AIRR format
    path(imgt_base) // igblast fasta
    output:
    tuple val(meta), path("${tab}"), emit: tab
    path("*threshold.txt"), emit: threshold
    path("versions.yml") , emit: versions
    path("*Hamming_distance_threshold.pdf") optional true
    script:
    def args = task.ext.args ?: ''
    """
    Rscript ${workflow.launchDir}/bin/shazam_threshold.R $tab $params.threshold_method
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        shazam: \$(Rscript -e "library(shazam); cat(paste(packageVersion('shazam'), collapse='.'))")
        R: \$(echo \$(R --version 2>&1) | awk -F' '  '{print \$3}')
    END_VERSIONS
    """
}
