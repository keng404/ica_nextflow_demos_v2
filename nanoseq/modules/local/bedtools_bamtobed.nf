process BEDTOOLS_BAMBED {
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.29.2--hc088bd4_0' :
        'quay.io/biocontainers/bedtools:2.29.2--hc088bd4_0' }"
    when:
    !params.skip_alignment && !params.skip_bigbed && (params.protocol == 'directRNA' || params.protocol == 'cDNA')
    input:
    tuple val(meta), path(sizes), val(is_transcripts), path(bam), path(bai)
    output:
    tuple val(meta), path(sizes), path("*.bed12") , emit: bed12
    path "versions.yml"                           , emit: versions
    script:
    """
    bedtools \\
        bamtobed \\
        -bed12 \\
        -cigar \\
        -i ${bam[0]} \\
        | bedtools sort > ${meta.id}.bed12
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """
}
