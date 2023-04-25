process UCSC_BED12TOBIGBED {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-bedtobigbed:377--h446ed27_1' :
        'quay.io/biocontainers/ucsc-bedtobigbed:377--h446ed27_1' }"
    when:
    !params.skip_alignment && !params.skip_bigbed && (params.protocol == 'directRNA' || params.protocol == 'cDNA')
    input:
    tuple val(meta), path(sizes),  path(bed12)
    output:
    tuple val(meta), path(sizes),  path("*.bigBed"), emit: bigbed
    path "versions.yml"                            , emit: versions
    script:
    def VERSION = '377'
    """
    bedToBigBed \\
        $bed12 \\
        $sizes \\
        ${meta.id}.bigBed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc_bed12tobigbed: \$(echo $VERSION)
    END_VERSIONS
    """
}
