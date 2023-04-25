process COLABFOLD_BATCH {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://nfcore/proteinfold_colabfold:1.0.0' :
        'nfcore/proteinfold_colabfold:1.0.0' }"

    input:
    tuple val(meta), path(fasta)
    val   colabfold_model_preset
    path  ('params/*')
    path  ('colabfold_db/*')
    path  ('uniref30/*')
    val   numRec

    output:
    path ("*")         , emit: pdb
    path ("*_mqc.png") , emit: multiqc
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def VERSION = '1.2.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    ln -r -s params/alphafold_params_*/* params/
    colabfold_batch \\
        $args \\
        --num-recycle ${numRec} \\
        --data \$PWD \\
        --model-type ${colabfold_model_preset} \\
        ${fasta} \\
        \$PWD
    for i in `find *_relaxed_rank_1*.pdb`; do cp \$i `echo \$i | sed "s|_relaxed_rank_|\t|g" | cut -f1`"_colabfold.pdb"; done
    for i in `find *.png -maxdepth 0`; do cp \$i \${i%'.png'}_mqc.png; done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        colabfold_batch: $VERSION
    END_VERSIONS
    """

    stub:
    def VERSION = '1.2.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    touch ./"${fasta.baseName}"_colabfold.pdb
    touch ./"${fasta.baseName}"_mqc.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        colabfold_batch: $VERSION
    END_VERSIONS
    """
}
