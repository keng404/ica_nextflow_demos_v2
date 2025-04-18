/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { DEMULTIPLEX                 } from '../subworkflows/local/demultiplex'
include { DRAGEN_ALIGN                } from '../modules/local/dragen_align'
include { DRAGEN_JOINT_CNV            } from '../modules/local/dragen_joint_cnv'
include { DRAGEN_JOINT_SMALL_VARIANTS } from '../modules/local/dragen_joint_small_variants'
include { PARSE_QC_METRICS            } from '../modules/local/parse_qc_metrics'
include { BCFTOOLS_SPLIT_VCF          } from '../modules/local/bcftools_split_vcf'
include { TRANSFER_DATA_AWS           } from '../modules/local/transfer_data_aws'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CREATE CHANNELS FOR INPUT PARAMETERS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Original input file -has not gone through XLSX -> CSV conversion
if (params.input) {
    ch_input_file = Channel.fromPath(params.input).collect()
} else {
    ch_input_file = Channel.empty()
}
// Illumina run directory
if (params.illumina_rundir) {
    ch_illumina_run_dir = Channel.fromPath(params.illumina_rundir, type: 'dir', checkIfExists: true).collect()
} else {
    ch_illumina_run_dir = Channel.empty()
}
// Sample information
if (params.sample_info) {
    ch_sample_information = Channel.fromPath(params.sample_info, checkIfExists: true).collect()
} else {
    ch_sample_information = Channel.empty()
}
// DRAGEN reference directory
if (params.refdir) {
    ch_reference_dir = Channel.fromPath(params.refdir, type: 'dir', checkIfExists: true).collect()
} else {
    ch_reference_dir = []
}
// DRAGEN dbSNP annotation VCF
if (params.dbsnp) {
    ch_dbsnp_file = Channel.fromPath(params.dbsnp, checkIfExists: true).collect()
} else {
    ch_dbsnp_file = []
}
// DRAGEN adapter sequences for read 1
if (params.adapter1) {
    ch_adapter1_file = Channel.fromPath(params.adapter1, checkIfExists: true).collect()
} else {
    ch_adapter1_file = []
}
// DRAGEN adapter sequences for read 2
if (params.adapter2) {
    ch_adapter2_file = Channel.fromPath(params.adapter2, checkIfExists: true).collect()
} else {
    ch_adapter2_file = []
}
// DRAGEN intermediate directory
if (params.intermediate_dir) {
    ch_intermediate_dir = Channel.fromPath(params.intermediate_dir).collect()
} else {
    ch_intermediate_dir = []
}
// DRAGEN QC coverage over custom region
if (params.qc_coverage_region) {
    ch_qc_coverage_region = Channel.fromPath(params.qc_coverage_region).collect()
} else {
    ch_qc_coverage_region = []
}
// DRAGEN QC cross-sample contamination
if (params.qc_cross_contamination) {
    ch_qc_cross_contamination = Channel.fromPath(params.qc_cross_contamination).collect()
} else {
    ch_qc_cross_contamination = []
}

// workaround to stage FASTQs appropriately
if(params.fastqs){
    ch_reads =  Channel.fromPath(params.fastqs).collect{it.toString()} // Group files into a list
} else{
    ch_reads = []
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow DRAGEN_CGS {
    take:
    ch_mgi_samplesheet    // channel: [ path(file) ]
    ch_input_samples      // channel: [ val(meta), path(file) ]
    main:
    ch_versions           = Channel.empty()
    ch_dragen_usage       = Channel.empty()
    ch_joint_vcf_files    = Channel.empty()
    ch_joint_metric_files = Channel.empty()
    //
    // SUBWORKFLOW: Demultiplex samples
    //
    if (params.input && params.illumina_rundir) {
        DEMULTIPLEX (
            ch_mgi_samplesheet,
            ch_illumina_run_dir
        )
        ch_samples  = DEMULTIPLEX.out.samples
        ch_versions = ch_versions.mix(DEMULTIPLEX.out.versions)
        // Merge demultiplex samples and samples parsed from `--fastq_list` parameter (if exists)
        ch_merged_samples    = ch_samples.mix(ch_input_samples)
                                                .map{ meta, file -> meta }
                                                .unique()
        ch_merged_fastq_list = ch_samples.mix(ch_input_samples)
                                                .map{ meta, file -> file }
                                                .splitText()
                                                .unique()
                                                .flatten()
                                                .collectFile(
                                                    name: "merged_fastq_list.csv",
                                                    sort: 'index'
                                                )
        ch_samples = ch_merged_samples.combine(ch_merged_fastq_list)
    } else {
        ch_samples = ch_input_samples
    }
    // Fetch gender for samples
    if (params.sample_info) {
        ch_align_samples = ch_samples.map{
                                meta, fastq_list ->
                                    [ meta['acc'], meta['id'] ]
                            }
                            .join(
                                ch_sample_information
                                    .splitCsv( header: true )
                                    .map{ row -> [ row.Accession, row.gender ] },
                                remainder: true
                            )
                            .map{
                                acc, id, gender ->
                                    if (id) {
                                        def meta = [:]
                                        meta['id'] = id
                                        meta['acc'] = acc
                                        gender = gender ? gender.toLowerCase() : ""
                                        meta['sex'] = gender in ["male", "female"] ? gender :
                                                        (gender == "m") ? "male" :
                                                        (gender == "f") ? "female" : ""
                                        [ meta ]
                                    }
                            }
                            .combine(ch_samples.map{ meta, fastq_list -> fastq_list }.first())
    } else {
        ch_align_samples = ch_samples
    }
    //
    // MODULE: DRAGEN alignment
    //
    DRAGEN_ALIGN (
        ch_align_samples,
        ch_qc_cross_contamination,
        ch_qc_coverage_region,
        ch_intermediate_dir,
        ch_reference_dir,
        ch_adapter1_file,
        ch_adapter2_file,
        ch_dbsnp_file,
        ch_reads
    )
    ch_versions     = ch_versions.mix(DRAGEN_ALIGN.out.versions)
    ch_dragen_usage = ch_dragen_usage.mix(DRAGEN_ALIGN.out.usage)
    //
    // MODULE: Batch joint genotype CNV
    //
    if (params.joint_genotype_cnv) {
        DRAGEN_JOINT_CNV (
            DRAGEN_ALIGN.out.tangent_normalized_counts.collect(),
            ch_reference_dir
        )
        ch_versions        = ch_versions.mix(DRAGEN_JOINT_CNV.out.versions)
        ch_dragen_usage    = ch_dragen_usage.mix(DRAGEN_JOINT_CNV.mix.usage)
        ch_joint_vcf_files = ch_joint_vcf_files.mix(DRAGEN_JOINT_CNV.out.joint_cnv)
        // Replace lines in '<sample name>.cnv_metrics.csv' file
        // with values from joint called metrics
        ch_cnv_metrics = DRAGEN_JOINT_CNV.out.metrics.collect()
                            .combine(DRAGEN_ALIGN.out.metrics.flatten().filter( ~/.*cnv_metrics.csv/ ))
                            .map{
                                joint, sample ->
                                    joint_lines = joint.readLines()
                                    sample_lines = sample.readLines()
                                    joint_lines.each{
                                        def pattern = it.split(',')[0..2].join(',')
                                        sample_lines.toString().replaceAll(("${pattern}.+"), (it)) as List
                                    }
                                    [ sample.getSimpleName(), sample_lines.join('\n') ]
                            }
                            .collectFile{
                                sample, output ->
                                    def outdir = file("${params.outdir}/DRAGEN_output/${sample}")
                                    outdir.mkdirs()
                                    [ "${outdir}/${sample}.cnv_metrics.csv", output ]
                            }
        ch_joint_metric_files = ch_joint_metric_files.mix(ch_cnv_metrics)
    }
    //
    // MODULE: Batch joint genotype SNV/InDel
    //
    if (params.joint_genotype_small_variants) {
        DRAGEN_JOINT_SMALL_VARIANTS (
            DRAGEN_ALIGN.out.hard_filtered_gvcf.collect(),
            ch_reference_dir
        )
        ch_versions        = ch_versions.mix(DRAGEN_JOINT_SMALL_VARIANTS.out.versions)
        ch_dragen_usage    = ch_dragen_usage.mix(DRAGEN_JOINT_SMALL_VARIANTS.out.usage)
        ch_joint_vcf_files = ch_joint_vcf_files.mix(DRAGEN_JOINT_SMALL_VARIANTS.out.joint_small_variants)
        ch_joint_vcf_files = ch_joint_vcf_files.mix(DRAGEN_JOINT_SMALL_VARIANTS.out.joint_small_variants_filtered)
        // Get values from single sample and joint called '*.vc_metrics.csv' files
        // and get all lines with sample name from joint called '*.vc_metrics.csv' file
        // and save to <sample name>.vc_metrics.csv file
        ch_small_variant_metrics = DRAGEN_JOINT_SMALL_VARIANTS.out.metrics.collect()
                                    .combine(DRAGEN_ALIGN.out.metrics.flatten().filter( ~/.*vc_metrics.csv/ ))
                                    .map{
                                        joint, sample ->
                                            def sample_name = sample.getSimpleName()
                                            def joint_sample_lines = joint.text.findAll(".+${sample_name}.+")
                                            // Find values in joint vc_metrics.csv file
                                            def number_samples = joint.text.findAll("VARIANT CALLER SUMMARY,,Number of samples,.+")
                                            def indels_list = joint_sample_lines.findAll{
                                                                                    it.contains("Insertions") ||
                                                                                    it.contains("Deletions") ||
                                                                                    it.contains("Indels")
                                                                                }
                                            // Calculate number of indels
                                            def indel_count = 0
                                            def indel_percent = 0.0
                                            indels_list.each{
                                                indel_count += it.split(',')[3].toInteger()
                                                indel_percent += it.split(',')[4].toFloat()
                                            }
                                            def number_of_indels = ["JOINT CALLER POSTFILTER,${sample_name},Number of Indels,${indel_count},${indel_percent.round(2)}"]
                                            // Find values in single sample vc_metrics.csv file
                                            def reads_processed = sample.text.findAll("VARIANT CALLER SUMMARY,,Reads Processed,.+")
                                            def child_sample = sample.text.findAll("VARIANT CALLER SUMMARY,,Child Sample,.+")
                                            def autosome_callability = sample.text.findAll("VARIANT CALLER POSTFILTER,.+,Percent Autosome Callability,.+")[0]
                                            // Replace autosome callability in joint_sample_lines and create output
                                            def updated_lines = joint_sample_lines.collect{ it.replaceAll(/.+,Percent Autosome Callability,.+/, autosome_callability) }
                                            // Create output and return values
                                            def output = number_samples + reads_processed + child_sample + updated_lines + number_of_indels
                                            [ sample_name, output.join('\n') ]
                                    }
                                    .collectFile{
                                        sample, output ->
                                            def outdir = file("${params.outdir}/DRAGEN_output/${sample}")
                                            outdir.mkdirs()
                                            [ "${outdir}/${sample}.vc_metrics.csv", output ]
                                    }
        ch_joint_metric_files = ch_joint_metric_files.mix(ch_small_variant_metrics)
    }
    //
    // MODULE: Batch joint genotype SV
    //
    if (params.joint_genotype_sv) {
        DRAGEN_JOINT_SV (
            DRAGEN_ALIGN.out.bam.collect(),
            ch_reference_dir
        )
        ch_versions        = ch_versions.mix(DRAGEN_JOINT_SV.out.versions)
        ch_dragen_usage    = ch_dragen_usage.mix(DRAGEN_JOINT_SV.out.usage)
        ch_joint_vcf_files = ch_joint_vcf_files.mix(DRAGEN_JOINT_SV.out.joint_sv)
        // Parse metrics for each sample
        // from joint called '*.sv_metrics.csv' file
        ch_sv_metrics = DRAGEN_JOINT_SV.out.metrics
                            .splitText(elem: 0)
                            .collectFile{
                                def sample = it.split(",")[1]
                                def outdir = file("${params.outdir}/${sample}")
                                outdir.mkdirs()
                                [ "${outdir}/${sample}.sv_metrics.csv", it ]
                            }
        ch_joint_metric_files = ch_joint_metric_files.mix(ch_sv_metrics)
    }
    //
    // MODULE: Parse QC metrics
    //
    PARSE_QC_METRICS (
        ch_input_file.ifEmpty([]),
        DRAGEN_ALIGN.out.metrics.collect(),
        ch_joint_metric_files.collect().ifEmpty([])
    )
    ch_versions = ch_versions.mix(PARSE_QC_METRICS.out.versions)
    //
    // MODULE: Split joint genotyped VCF files by sample
    //
    BCFTOOLS_SPLIT_VCF (
        ch_joint_vcf_files
            .combine( ch_samples.map{ meta, file -> meta } )
            .map{
                vcf_meta, vcf, sample_meta ->
                    new_meta = sample_meta.clone()
                    new_meta['batch'] = vcf_meta['id']
                    [ new_meta, vcf ]
            }
    )
    ch_versions = ch_versions.mix(BCFTOOLS_SPLIT_VCF.out.versions)
    //
    // MODULE: Transfer data to AWS bucket
    //
    if (params.transfer_data) {
        ch_dragen_files = DRAGEN_ALIGN.out.dragen_output
                            .map{
                                meta, files ->
                                    def extensions = [".bw", ".bam", ".gff3", ".json", ".vcf", ".csv", ".bed"]
                                    def aws_files = files.findAll{
                                        file ->
                                            extensions.any{ file.toString().contains(it) }
                                    }
                                return aws_files
                            }
        TRANSFER_DATA_AWS (
            ch_dragen_files.collect(),
            BCFTOOLS_SPLIT_VCF.out.split_vcf.map{ meta, file -> file }.collect().ifEmpty([]),
            ch_joint_metric_files.collect().ifEmpty([]),
            PARSE_QC_METRICS.out.qc_metrics.collect()
        )
        ch_versions = ch_versions.mix(TRANSFER_DATA_AWS.out.versions)
    }
    // Output DRAGEN usage information
    ch_dragen_usage.map{
                        def meta = it.getSimpleName().split("_usage")[0]
                        def data = it.text.split("\\: ").join('\t')
                        return "Accession\tLicense Type\tUsage\n${meta}\t${data}"
                    }
                    .collectFile(
                        name      : "DRAGEN_usage.tsv",
                        keepHeader: true,
                        storeDir  : "${params.outdir}/pipeline_info"
                    )
    emit:
    versions = ch_versions
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow.onError{ 
// copy intermediate files + directories
println("Getting intermediate files from ICA")
['cp','-r',"${workflow.workDir}","${workflow.launchDir}/out"].execute()
// return trace files
println("Returning workflow run-metric reports from ICA")
['find','/ces','-type','f','-name','\"*.ica\"','2>','/dev/null', '|', 'grep','"report"' ,'|','xargs','-i','cp','-r','{}',"${workflow.launchDir}/out"].execute()
}
workflow.onComplete{ 
if(workflow.success){
	println("Pipeline Completed Successfully")
	System.exit(0)
}
else{
	println("Pipeline Completed with Errors")
	System.exit(1)
}
}
