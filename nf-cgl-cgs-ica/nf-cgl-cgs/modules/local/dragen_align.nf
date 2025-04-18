process DRAGEN_ALIGN {
    tag "${meta.id}"
    label 'dragen'

    //container "${ workflow.profile == 'dragenaws' ?
    //    'ghcr.io/dhslab/docker-dragen:el8.4.3.6' :
    //    'dockerreg01.accounts.ad.wustl.edu/cgl/dragen:v4.3.6' }"
    container "079623148045.dkr.ecr.us-east-1.amazonaws.com/cp-prod/c3add40b-1be2-431d-a322-29529f7d2866:latest"
    pod annotation: 'volumes.illumina.com/scratchSize', value: '1TiB'
    input:
    tuple val(meta), path(fastq_list)
    path(qc_cross_contamination_file)
    path(qc_coverage_region_file)
    path(intermediate_directory)
    path(reference_directory)
    path(adapter1_file)
    path(adapter2_file)
    path(dbsnp_file)
    path(fastq_files)

    output:
    tuple val(meta), path ("dragen/*")          , emit: dragen_output
    path("dragen/*.hard-filtered.gvcf.gz")      , emit: hard_filtered_gvcf       , optional: true
    path("dragen/${meta.id}_usage.txt")         , emit: usage                    , optional: true
    path("dragen/*_metrics.csv")                , emit: metrics
    path("dragen/*.tn.tsv.gz")                  , emit: tangent_normalized_counts, optional: true
    path("dragen/*.bam")                        , emit: bam
    path("versions.yml")                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def alignment_args = [
        task.ext.dragen_license_args                  ?: "",
        meta.sex?.toLowerCase() in ['male', 'female'] ? "--sample-sex ${meta.sex}"                             : "",
        dbsnp_file                                    ? "--dbsnp ${dbsnp_file}"                                : "",
        params.create_gvcf                            ? "--vc-emit-ref-confidence GVCF"                        : "",
        reference_directory                           ? "--ref-dir ${reference_directory}"                     : "",
        adapter1_file                                 ? "--trim-adapter-read1 ${adapter1_file}"                : "",
        adapter2_file                                 ? "--trim-adapter-read2 ${adapter2_file}"                : "",
        qc_cross_contamination_file                   ? "--qc-cross-cont-vcf ${params.qc_cross_contamination}"   : "",
        qc_coverage_region_file                       ? "--qc-coverage-region-1 ${qc_coverage_region_file}"    : "",
        intermediate_directory                        ? "--intermediate-results-dir ${intermediate_directory}" : "",
        adapter1_file                                 ? "--read-trimmers adapter" : ""
    ].join(' ').trim()
    """
    mkdir -p dragen
    /opt/edico/bin/dragen \\
        --fastq-list ${fastq_list} \\
        --fastq-list-sample-id ${meta.id} \\
        --output-file-prefix ${meta.id} \\
        --output-directory dragen \\
        --force \\
        ${alignment_args} \\
        --enable-sv true \\
        --enable-cnv true \\
        --enable-sort true \\
        --output-format BAM \\
        --enable-map-align true \\
        --gc-metrics-enable true \\
        --sv-output-contigs true \\
        --enable-bam-indexing true \\
        --enable-variant-caller true \\
        --enable-map-align-output true \\
        --enable-duplicate-marking true \\
        --qc-coverage-ignore-overlaps true \\
        --cnv-enable-self-normalization true \\
        --logging-to-output-dir true \\
        --lic-instance-id-location /opt/instance-identity \\
        --variant-annotation-assembly GRCh38

    # Create md5sum of files
    find dragen/ \\
        -type f \\
        \\( \\
        -name "*.gz*" -o \\
        -name "*.gff3" -o \\
        -name "*.bam*" \\
        \\) \\
        ! -name "*.md5sum" \\
        | xargs -I "{}" \\
            bash -c "md5sum {} | sed 's|dragen/||g' > {}.md5sum"

    # Copy and rename DRAGEN usage
    find dragen/ \\
        -type f \\
        -name "*_usage.txt" \\
        -exec mv "{}" "dragen/${meta.id}_usage.txt" \\;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dragen: \$(/opt/edico/bin/dragen --version | head -n 1 | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    def alignment_args = [
        task.ext.dragen_license_args                  ?: "",
        meta.sex?.toLowerCase() in ['male', 'female'] ? "--sample-sex ${meta.sex}"                             : "",
        dbsnp_file                                    ? "--dbsnp ${dbsnp_file}"                                : "",
        params.create_gvcf                            ? "--vc-emit-ref-confidence GVCF"                        : "",
        reference_directory                           ? "--ref-dir ${reference_directory}"                     : "",
        adapter1_file                                 ? "--trim-adapter-read1 ${adapter1_file}"                : "",
        adapter2_file                                 ? "--trim-adapter-read2 ${adapter2_file}"                : "",
        qc_cross_contamination_file                   ? "--qc-cross-cont-vcf ${params.qc_cross_contamination}"   : "",
        qc_coverage_region_file                       ? "--qc-coverage-region-1 ${qc_coverage_region_file}"    : "",
        intermediate_directory                        ? "--intermediate-results-dir ${intermediate_directory}" : ""
    ].join(' ').trim()
    """
    mkdir -p dragen

    touch \\
        "dragen/*.bam" \\
        "dragen/*.tn.tsv.gz" \\
        "dragen/*_metrics.csv" \\
        "dragen/${meta.id}_usage.txt" \\
        "dragen/*.hard-filtered.gvcf.gz"

    cat <<-END_CMDS > "dragen/${meta.id}.txt"
    /opt/edico/bin/dragen \\
        --fastq-list ${fastq_list} \\
        --fastq-list-sample-id ${meta.id} \\
        --output-file-prefix ${meta.id} \\
        --output-directory dragen \\
        --force \\
        ${alignment_args} \\
        --enable-sv true \\
        --enable-cnv true \\
        --enable-sort true \\
        --output-format BAM \\
        --enable-map-align true \\
        --read-trimmers adapter \\
        --gc-metrics-enable true \\
        --sv-output-contigs true \\
        --enable-bam-indexing true \\
        --enable-variant-caller true \\
        --enable-map-align-output true \\
        --enable-duplicate-marking true \\
        --qc-coverage-ignore-overlaps true \\
        --cnv-enable-self-normalization true \\
        --variant-annotation-assembly GRCh38
    END_CMDS

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dragen: ${dragen_version}
    END_VERSIONS
    """
}
