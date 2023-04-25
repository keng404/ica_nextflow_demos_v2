process PLOT_MOSDEPTH_REGIONS {
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0' :
        'quay.io/biocontainers/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0' }"
    input:
    path beds
    output:
    path '*coverage.pdf', emit: coverage_pdf
    path '*coverage.tsv', emit: coverage_tsv
    path '*heatmap.pdf' , optional:true, emit: heatmap_pdf
    path '*heatmap.tsv' , optional:true, emit: heatmap_tsv
    path "versions.yml" , emit: versions
    when:
    task.ext.when == null || task.ext.when
    script: // This script is bundled with the pipeline, in nf-core/viralrecon/bin/
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "mosdepth"
    """
    Rscript ${workflow.launchDir}/bin/plot_mosdepth_regions.r \\
        --input_files ${beds.join(',')} \\
        --output_dir ./ \\
        --output_suffix $prefix \\
        $args
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
    END_VERSIONS
    """
}
