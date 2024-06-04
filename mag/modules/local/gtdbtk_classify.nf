process GTDBTK_CLASSIFY {
    tag "${meta.assembler}-${meta.binner}-${meta.id}"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gtdbtk:1.5.0--pyhdfd78af_0' :
        'quay.io/biocontainers/gtdbtk:2.3.2--pyhdfd78af_0' }"
    pod annotation: 'volumes.illumina.com/scratchSize', value: '10TiB'
    errorStrategy 'ignore'
    input:
    tuple val(meta), path("bins/*")
    tuple val(db_name), path("out/database/*")
    output:
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.*.summary.tsv"        , emit: summary
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.*.classify.tree.gz"   , emit: tree
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.*.markers_summary.tsv", emit: markers
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.*.msa.fasta.gz"       , emit: msa
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.*.user_msa.fasta"     , emit: user_msa
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.*.filtered.tsv"       , emit: filtered
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.log"                  , emit: log
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.warnings.log"         , emit: warnings
    path "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.failed_genomes.tsv"   , emit: failed
    path "versions.yml"                                                            , emit: versions
    script:
    def args = task.ext.args ?: ''
    def pplacer_scratch =  "scratch_tmp"
    """
    find out/database
    export GTDBTK_DATA_PATH="out/database"
    if [ ${pplacer_scratch} != "" ] ; then
        mkdir pplacer_tmp
    fi
    gtdbtk classify_wf $args \
                    --genome_dir bins \
                    --prefix "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}" \
                    --out_dir "\${PWD}" \
                    --cpus ${task.cpus} \
                    --skip_ani_screen \
                    --pplacer_cpus ${params.gtdbtk_pplacer_cpus} \
                    --scratch_dir ${pplacer_scratch} \
                    --min_perc_aa ${params.gtdbtk_min_perc_aa} \
                    --min_af ${params.gtdbtk_min_af}

    count1=`ls -1 *.classify.tree 2>/dev/null | wc -l`
    count2=`ls -1 *.msa.fasta 2>/dev/null | wc -l`
    if [ count1 !=0 && count2 !=0 ] ; then
        gzip "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}".*.classify.tree "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}".*.msa.fasta
    fi
    mv gtdbtk.log "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.log"
    mv gtdbtk.warnings.log "gtdbtk.${meta.assembler}-${meta.binner}-${meta.id}.warnings.log"
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(gtdbtk --version | sed -n 1p | sed "s/gtdbtk: version //; s/ Copyright.*//")
    END_VERSIONS
    """
}
