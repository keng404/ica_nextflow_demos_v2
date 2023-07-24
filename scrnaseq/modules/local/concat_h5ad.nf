process CONCAT_H5AD {
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/scanpy:1.7.2--pyhdfd78af_0' :
        'keng404/scanpy:0.0.1' }"
    input:
    path h5ad
    path samplesheet
    output:
    path "*.h5ad", emit: h5ad
    when:
    task.ext.when == null || task.ext.when
    script:
    """
    python ${workflow.launchDir}/bin/concat_h5ad.py \\
        --input $samplesheet \\
        --out combined_matrix.h5ad \\
        --suffix "_matrix.h5ad"
    """
    stub:
    """
    touch combined_matrix.h5ad
    """
}
