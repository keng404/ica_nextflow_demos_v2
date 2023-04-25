process STARFUSION_DOWNLOAD {
    tag 'star-fusion'
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "docker.io/trinityctat/starfusion:1.10.1"
    } else {
        container "docker.io/trinityctat/starfusion:1.10.1"
    }
    output:
    path "ctat_genome_lib_build_dir/*"            , emit: reference
    path "ctat_genome_lib_build_dir/ref_annot.gtf", emit: chrgtf
    script:
    """
    wget https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/__genome_libs_StarFv1.10/GRCh38_gencode_v37_CTAT_lib_Mar012021.plug-n-play.tar.gz --no-check-certificate
    tar xvf GRCh38_gencode_v37_CTAT_lib_Mar012021.plug-n-play.tar.gz
    rm GRCh38_gencode_v37_CTAT_lib_Mar012021.plug-n-play.tar.gz
    mv */ctat_genome_lib_build_dir .
    """
}
