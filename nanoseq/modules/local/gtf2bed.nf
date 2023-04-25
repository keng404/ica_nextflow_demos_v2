process GTF2BED {
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"
    input:
    tuple path(gtf), val(name)
    output:
    tuple path('*.bed'), val(name) , emit: gtf_bed
    path "versions.yml", emit: versions
    script: // This script is bundled with the pipeline, in nf-core/chipseq/bin/
    """
    perl ${workflow.launchDir}/bin/gtf2bed $gtf > ${gtf.baseName}.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(echo \$(perl --version 2>&1) | sed 's/.*v\\(.*\\)) built.*/\\1/')
    END_VERSIONS
    """
}
