process BIN_SUMMARY {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.1.5' :
        'quay.io/biocontainers/pandas:1.1.5' }"
    input:
    path(bin_depths)
    path(busco_sum)
    path(quast_sum)
    path(gtdbtk_sum)
    output:
    path("bin_summary.tsv"), emit: summary
    path "versions.yml"    , emit: versions
    script:
    def busco_summary  = busco_sum.sort().size() > 0 ?  "--busco_summary ${busco_sum}" : ""
    def quast_summary  = quast_sum.sort().size() > 0 ?  "--quast_summary ${quast_sum}" : ""
    def gtdbtk_summary = gtdbtk_sum.sort().size() > 0 ? "--gtdbtk_summary ${gtdbtk_sum}" : ""
    """
    python ${workflow.launchDir}/bin/combine_tables.py --depths_summary ${bin_depths} \
                    $busco_summary \
                    $quast_summary \
                    $gtdbtk_summary \
                    --out bin_summary.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        pandas: \$(python -c "import pkg_resources; print(pkg_resources.get_distribution('pandas').version)")
    END_VERSIONS
    """
}
