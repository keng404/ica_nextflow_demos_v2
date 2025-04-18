process TRANSFER_DATA_AWS {
    label 'process_low'
    label 'gnx_aws'
    container "docker.io/gregorysprenger/aws-cli:v2.15.39"
    input:
    path(dragen_align_files), stageAs: "dragen_align_files/*"
    path(joint_vcf_files)   , stageAs: "joint_called_files/*"
    path(joint_metric_files), stageAs: "joint_called_files/*"
    path(qc_metrics)
    output:
    path("aws_log.txt") , emit: aws_log
    path("versions.yml"), emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
    def prefix = task.ext.prefix
    """
    export AWS_ACCESS_KEY_ID=\${GNX_ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=\${GNX_SECRET_KEY}
    # Organize files for upload
    for file in \$(find -L dragen_align_files/ -type f -name "*.bam"); do
        base=\$(basename "\${file%%.*}")
        target_dir="${prefix.id}/\${base}"
        mkdir -p "\$target_dir"
        for dir in dragen_align_files joint_called_files; do
            [ -d "\$dir" ] && \\
            find \\
                -L \\
                "\$dir" \\
                -type f \\
                -name "\${base}*" \\
                -exec mv -f {} "\$target_dir" \\;
        done
    done
    # Move Genoox excel spreadsheet
    find -L \$PWD \\
        -type f \\
        -name "*Genoox.xlsx" \\
        -exec mv -f "{}" "${prefix.id}" \\;
    # Sync files with the following extensions
    aws s3 sync \\
        "${prefix.id}" \\
        "s3://\${GNX_BUCKET}/\${GNX_DATA}/${prefix.id}/" \\
        --exclude "*" \\
        --include "*.bw*" \\
        --include "*.csv" \\
        --include "*.bam*" \\
        --include "*.json" \\
        --include "*.xlsx" \\
        --include "*.gff3*" \\
        --include "*.vcf.gz*" \\
        --include "*.bed.gz*" \\
        --include "*_usage.txt" \\
        --only-show-errors \\
        &> aws_log.txt
    if [ \$? -eq 0 ]; then
        echo "AWS sync completed successfully." >> aws_log.txt
    else
        error "AWS sync failed. Check 'aws_log.txt' for details."
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aws: \$(aws --version 2>&1 | awk '{print \$1}' | cut -d '/' -f2)
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix
    """
    export AWS_ACCESS_KEY_ID=\${GNX_ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=\${GNX_SECRET_KEY}
    # Organize files for upload
    for file in \$(find -L dragen_align_files/ -type f -name "*.bam"); do
        base=\$(basename "\${file%%.*}")
        target_dir="${prefix.id}/\${base}"
        mkdir -p "\$target_dir"
        for dir in dragen_align_files joint_called_files; do
            [ -d "\$dir" ] && \\
            find \\
                -L \\
                "\$dir" \\
                -type f \\
                -name "\${base}*" \\
                -exec mv -f {} "\$target_dir" \\;
        done
    done
    # Move Genoox excel spreadsheet
    find -L \$PWD \\
        -type f \\
        -name "*Genoox.xlsx" \\
        -exec mv -f "{}" "${prefix.id}" \\;
    # Sync files with the following extensions
    aws s3 sync \\
        "${prefix.id}" \\
        "s3://\${GNX_BUCKET}/\${GNX_DATA}/${prefix.id}/" \\
        --exclude "*" \\
        --include "*.bw*" \\
        --include "*.csv" \\
        --include "*.bam*" \\
        --include "*.json" \\
        --include "*.xlsx" \\
        --include "*.gff3*" \\
        --include "*.vcf.gz*" \\
        --include "*.bed.gz*" \\
        --include "*_usage.txt" \\
        --only-show-errors \\
        --dryrun \\
        &> aws_log.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aws: \$(aws --version 2>&1 | awk '{print \$1}' | cut -d '/' -f2)
    END_VERSIONS
    """
}
