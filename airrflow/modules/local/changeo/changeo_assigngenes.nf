process CHANGEO_ASSIGNGENES {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-7d8e418eb73acc6a80daea8e111c94cf19a4ecfd:e7f88c6f7da46a5407f261ca406c050d5bd12dea-0' :
        'quay.io/biocontainers/mulled-v2-7d8e418eb73acc6a80daea8e111c94cf19a4ecfd:e7f88c6f7da46a5407f261ca406c050d5bd12dea-0' }"
    input:
    tuple val(meta), path(reads) // reads in fasta format
    path(igblast) // igblast fasta
    output:
    path("*igblast.fmt7"), emit: blast
    tuple val(meta), path("$reads"), emit: fasta
    path "versions.yml" , emit: versions
    script:
    def args = task.ext.args ?: ''
    """
    AssignGenes.py igblast -s $reads -b $igblast --organism $meta.species --loci ${meta.locus.toLowerCase()} $args --nproc $task.cpus --outname "$meta.id"
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        igblastn: \$( igblastn -version | grep -o "igblast[0-9\\. ]\\+" | grep -o "[0-9\\. ]\\+" )
        changeo: \$( AssignGenes.py --version | awk -F' '  '{print \$2}' )
    END_VERSIONS
    """
}
