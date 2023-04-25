process AMPLIFIED_INTERVALS {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-6eefa51f13933d65b4f8155ca2f8cd81dea474ba:baa777f7c4e89a2ec4d1eab7d424a1f46503bac7-0':
        'quay.io/biocontainers/mulled-v2-6eefa51f13933d65b4f8155ca2f8cd81dea474ba:baa777f7c4e89a2ec4d1eab7d424a1f46503bac7-0' }"
    input:
    tuple val(meta), path(bed), path(bam), path(bai)
    output:
    tuple val(meta), path("*CNV_SEEDS.bed"), emit: bed
    path "versions.yml"           , emit: versions
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cngain = params.aa_cngain
    def ref = params.reference_build
    """
    export AA_DATA_REPO=${params.aa_data_repo}
    export MOSEKLM_LICENSE_FILE=${params.mosek_license_dir}
    REF=${params.reference_build}
    python ${workflow.launchDir}/bin/amplified_intervals.py \\
        $args \\
        --bed $bed \\
        --out ${prefix}_AA_CNV_SEEDS \\
        --bam $bam \\
        --gain $cngain \\
        --ref $ref
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: echo \$(python --version 2<&1 | sed 's/Python //g')
    END_VERSIONS
    """
    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cngain = params.aa_cngain
    def ref = params.reference_build
    """
    export AA_DATA_REPO=${params.aa_data_repo}
    export MOSEKLM_LICENSE_FILE=${params.mosek_license_dir}
    REF=${params.reference_build}
    touch ${prefix}_AA_CNV_SEEDS.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: echo \$(python --version 2<&1 | sed 's/Python //g')
    END_VERSIONS
    """
}
