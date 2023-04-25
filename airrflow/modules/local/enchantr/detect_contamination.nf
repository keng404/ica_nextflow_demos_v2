process DETECT_CONTAMINATION {
    tag "multi_repertoire"
    label 'immcantation'
    label 'enchantr'

    cache  'lenient'

    // TODO: update container
    container "immcantation/suite:devel"

    input:
    path(tabs)
    val(input_id)

    output:
    tuple val(meta), path("*cont-flag.tsv"), emit: tab // sequence tsv in AIRR format
    path("*_command_log.txt"), emit: logs //process logs
    path "*_report" //, emit: contamination_report
    path "versions.yml" , emit: versions

    script:
    meta=[]
    """
    echo "${tabs.join('\n')}" > tabs.txt
    Rscript -e "enchantr::enchantr_report('contamination', report_params=list('input'='tabs.txt','input_id'='${input_id}','outdir'=getwd(), 'outname'='cont-flag', 'log'='all_reps_contamination_command_log'))"
    echo "${task.process}": > versions.yml
    Rscript -e "cat(paste0('  enchantr: ',packageVersion('enchantr'),'\n'))" >> versions.yml
    mv enchantr al_reps_cont_report
    """
}
