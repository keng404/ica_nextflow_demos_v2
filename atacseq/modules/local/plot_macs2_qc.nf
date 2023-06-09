process PLOT_MACS2_QC {
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0':
        'quay.io/biocontainers/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0' }"
    input:
    path peaks
    val is_narrow_peak
    output:
    path '*.txt'       , emit: txt
    path '*.pdf'       , emit: pdf
    path "versions.yml", emit: versions
    when:
    task.ext.when == null || task.ext.when
    script: // This script is bundled with the pipeline, in nf-core/atacseq/bin/
    def args      = task.ext.args ?: ''
    def peak_type = is_narrow_peak ? 'narrowPeak' : 'broadPeak'
    """
    Rscript ${workflow.launchDir}/bin/plot_macs2_qc.r \\
        -i ${peaks.join(',')} \\
        -s ${peaks.join(',').replaceAll("_peaks.${peak_type}","")} \\
        $args
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
    END_VERSIONS
    """
}
