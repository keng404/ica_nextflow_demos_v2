#!/usr/bin/env nextflow
/*
========================================================================================
                         nf-core/coproid
========================================================================================
 nf-core/coproid Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/nf-core/coproid
----------------------------------------------------------------------------------------
*/
def helpMessage() {
    log.info nfcoreHeader()
    log.info"""
     coproID: Coprolite Identification
     Homepage: https://github.com/nf-core/coproid
     Author: Maxime Borry <borry@shh.mpg.de>
     Version ${workflow.manifest.version}
    =========================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run maxibor/coproid -profile docker --genome1 'GRCh37' --genome2 'CanFam3.1' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
    Mandatory arguments:
      --reads                       Path to input data (must be surrounded with quotes)
      --name1                       Name of candidate 1. Example: "Homo_sapiens"
      --fasta1                      Path to human genome fasta file (must be surrounded with quotes). Must be provided if --genome1 is not provided
      --genome1                     Name of iGenomes reference for Homo_sapiens. Must be provided if --fasta1 is not provided
      --name2                       Name of candidate 2. Example: "Canis_familiaris"
      --fasta2                      Path to canidate organism 2 genome fasta file (must be surrounded with quotes). Must be provided if --genome2 is not provided
      --genome2                     Name of iGenomes reference for candidate organism 2. Must be provided if --fasta2 is not provided
      --krakendb                    Path to MiniKraken2_v2_8GB Database
    Settings:
      --adna                        Specified if data is modern (false) or ancient DNA (true). Default = ${params.adna}
      --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to ${params.phred}
      --single_end                  Specified if reads are single-end. Default = ${params.single_end}
      --collapse                    Specifies if AdapterRemoval should merge the paired-end sequences or not (true | false). Default = ${params.collapse}
      --identity                    Identity threshold to retain read alignment. Default = ${params.identity}
      --pmdscore                    Minimum PMDscore to retain read alignment. Default = ${params.pmdscore}
      --library                     DNA preparation library type ( 'classic' | 'UDGhalf'). Default = ${params.library}
      --bowtie                      Bowtie settings for sensivity ('very-fast' | 'very-sensitive'). Default = ${params.bowtie}
      --minKraken                   Minimum number of Kraken hits per Taxonomy ID to report. Default = ${params.minKraken}
      --endo1                       Proportion of Endogenous DNA in organism 1 target microbiome. Default = ${params.endo1}
      --endo2                       Proportion of Endogenous DNA in organism 2 target microbiome. Default = ${params.endo1}
      --endo3                       Proportion of Endogenous DNA in organism 3 target microbiome. Default = ${params.endo1}
      --sp_norm                     Sourcepredict normalization method.  One of 'rle', 'gmpr', 'subsample'. Default = ${params.sp_norm}
      --sp_embed                    SourcePredict embedding algorithm. One of 'mds', 'tsne', 'umap'. Default = ${params.sp_embed}    
      --sp_neighbors                Sourcepredict numbers of neighbors for KNN ML. Integer or 'all'. Default = ${params.sp_neighbors}
      
    Options:
      --name3                       Name of candidate 1. Example: "Sus_scrofa"
      --fasta3                      Path to canidate organism 3 genome fasta file (must be surrounded with quotes). Must be provided if --genome3 is not provided
      --genome3                     Name of iGenomes reference for candidate organism 3. Must be provided if --fasta3 is not provided
      --index1                      Path to Bowtie2 index of genome candidate 1, in the form of "/path/to/bowtie_index/basename"
      --index2                      Path to Bowtie2 index genome candidate 2 Coprolite maker's genome, in the form of "/path/to/bowtie_index/basename"
      --index3                      Path to Bowtie2 index genome candidate 3 Coprolite maker's genome, in the form of "/path/to/bowtie_index/basename"
     Other options:
      --outdir                      The output directory where the results will be saved. Defaults to ${params.outdir}
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      --maxMultiqcEmailFileSize     Theshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, it will not be attached (Default: 25MB)
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.
      --help  --h                   Shows this help page
    AWSBatch options:
      --awsqueue [str]                The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion [str]               The AWS Region for your AWS Batch job to run on
      --awscli [str]                  Path to the AWS CLI tool
    """.stripIndent()
}
/****************************
DEFAULT VARIABLE VALUES SETUP
*****************************/
// Default variable configuration
bowtie_setting = ''
collapse_setting = ''
report_template = "$baseDir/templates/coproID_report.ipynb"
coproid_logo = file("$baseDir/assets/img/coproid_logo.png")
// Show help message
if (params.help){
    helpMessage()
    exit 0
}
// Message for empty run
if ( (!params.reads && !params.readPaths) || !params.name1 || !params.name2 || !params.krakendb || (!params.genome1 && !params.fasta1) || (!params.genome2 && !params.fasta2)){
    log.info"""
    CoproID was launched with missing mandatory arguments.
    Please check your command line and retry.
    To get the help menu, please run:
    nextflow run maxibor/coproid --help
    The complete documentation is available at https://github.com/nf-core/coproid
    """
    exit 0
}
/****************************************
SETTING UP REFERENCE GENOMES AND IGENOMES
*****************************************/
// Check if genome(s) exists in the config file
if (params.genomes && params.genome1 && !params.genomes.containsKey(params.genome1)) {
    exit 1, "The provided genome '${params.genome1}' is not available in the iGenomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
}
if (params.genomes && params.genome2 && !params.genomes.containsKey(params.genome2)) {
    exit 1, "The provided genome '${params.genome2}' is not available in the iGenomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
}
if (params.genomes && params.genome3 && !params.genomes.containsKey(params.genome3)) {
    exit 1, "The provided genome '${params.genome3}' is not available in the iGenomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
}
// Genome 1
fasta1 = params.genome1 ? params.genomes[ params.genome1 ].fasta ?: false : false
bt1 = params.genome1 ? params.genomes[ params.genome1 ].bowtie2 ?: false : false
if ( params.fasta1 ){
    fasta1 = file(params.fasta1)
} else if (fasta1) {
    fasta1 = file(params.genomes[ params.genome1 ].fasta, checkIfExists: true)
}
if( !fasta1.exists() ) exit 1, "Fasta1 file not found: ${params.fasta2}"
if (params.index1) {
    bt1 = params.index1
}
if (bt1) {
    lastPath = bt1.lastIndexOf(File.separator)
    bt1_dir = bt1.substring(0, lastPath+1)
    bt1_index = bt1.substring(lastPath+1)
    Channel
        .fromPath(bt1_dir+"/*.bt2")
        .ifEmpty {exit 1, "Cannot find any index matching : ${bt1}\n"}
        .collect()
        .set {bt1_ch}
} else {
    bt1_index = params.name1
}
// Genome 2
fasta2 = params.genome2 ? params.genomes[ params.genome2 ].fasta ?: false : false
bt2 = params.genome2 ? params.genomes[ params.genome2 ].bowtie2 ?: false : false
if ( params.fasta2 ){
    fasta2 = file(params.fasta2)
} else if (fasta2) {
    fasta2 = file(params.genomes[ params.genome2 ].fasta, checkIfExists: true)
}
if( !fasta2.exists() ) exit 1, "Fasta2 file not found: ${params.fasta2}"
if (params.index2) {
    bt2 = params.index2
}
if (bt2) {
    lastPath = bt2.lastIndexOf(File.separator)
    bt2_dir = bt2.substring(0, lastPath+1)
    bt2_index = bt2.substring(lastPath+1)
    Channel
        .fromPath(bt2_dir+"/*.bt2")
        .ifEmpty {exit 1, "Cannot find any index matching : ${params.bt2}\n"}
        .collect()
        .set {bt2_ch}
} else {
    bt2_index = params.name2
}
// Genome 3
if (params.name3) {
    fasta3 = params.genome3 ? params.genomes[ params.genome3 ].fasta ?: false : false
    bt3 = params.genome3 ? params.genomes[ params.genome3 ].bowtie2 ?: false : false
    if ( params.fasta3 ){
        fasta3 = file(params.fasta3)
    } else if (fasta3) {
        fasta3 = file(params.genomes[ params.genome3 ].fasta, checkIfExists: true)
    }
    if( !fasta3.exists() ) exit 1, "Fasta3 file not found: ${params.fasta3}"
    if (params.index3) {
        bt3 = params.index3
    }
    if (bt3) {
        lastPath = bt3.lastIndexOf(File.separator)
        bt3_dir = bt3.substring(0, lastPath+1)
        bt3_index = bt3.substring(lastPath+1)
        Channel
            .fromPath(bt3_dir+"/*.bt2")
            .ifEmpty {exit 1, "Cannot find any index matching : ${params.bt3}\n"}
            .collect()
            .set {bt3_ch}
    } else {
        bt3_index = params.name3
    }
    
}
// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
}
// Stage config files
ch_multiqc_config = file(params.multiqc_config, checkIfExists: true)
ch_output_docs = file("$baseDir/docs/output.md", checkIfExists: true)
// Report template channel
report_template_ch = file(report_template)
/*************
SETTINGS CHECK
**************/
// Bowtie setting check
if (params.bowtie == 'very-fast'){
    bowtie_setting = '--very-fast'
} else if (params.bowtie == 'very-sensitive'){
    bowtie_setting = '--very-sensitive -N 1'
} else {
    println "Problem with --bowtie. Make sure to choose between 'very-fast' or 'very-sensitive'"
    exit(1)
}
// single_end or paired_end Check
if (params.single_end == false) {
    paired_end = true
} else if (params.single_end == true) {
    paired_end = false
}
//Library setting check
if ((params.library != 'classic' && params.library != 'UDGhalf' ) && (params.h == false || params.help == false) ){
    println 'ERROR: You did not specify --library'
    exit(1)
}
if (params.library == 'classic'){
    library = ''
} else {
    library = '--UDGhalf'
}
if( ! nextflow.version.matches(workflow.manifest.nextflowVersion) ){
    println "Your version of Nextflow is too old, please use Nextflow "+workflow.manifest.nextflowVersion.toString()
    exit(1)
}
// Check sourcepredict parameters
if (params.sp_embed != 'mds' && params.sp_embed != 'tsne' && params.sp_embed != 'umap'){
    println "${params.sp_embed} is not a valid method for SourcePredict embedding (--sp_embed)"
    println """Available methods are: 'mds', 'tsne', 'umap' """
    exit(1)
}
if (params.sp_norm != 'rle' && params.sp_norm != 'gmpr' && params.sp_norm != 'subsample'){
    println "${params.sp_norm} is not a valid method for SourcePredict normalization method (--sp_norm)"
    println """Available methods are: 'rle', 'gmpr', 'subsample' """
    exit(1)
}
/****************
AWSBATCH SETTINGS
*****************/
if( workflow.profile == 'awsbatch') {
  // AWSBatch sanity checking
  if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
  // Check outdir paths to be S3 buckets if running on AWSBatch
  // related: https://github.com/nextflow-io/nextflow/issues/813
  if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
  // Prevent trace files to be stored on S3 since S3 does not support rolling files.
  if (workflow.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}
/*********************
READS CHANNEL CREATION
**********************/
// Creating reads channel
if(params.readPaths){
    if(params.single_end){
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [ file(row[1][0], checkIfExists: true) ] ] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { ch_read_files_fastqc; ch_read_files_trimming }
    } else {
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [ file(row[1][0], checkIfExists: true), file(row[1][1], checkIfExists: true) ] ] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { ch_read_files_fastqc; ch_read_files_trimming }
    }
} else {
    Channel
        .fromFilePairs(params.reads, size: params.single_end ? 1 : 2)
        .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nIf this is single-end data, please specify --single_end on the command line." }
        .into { ch_read_files_fastqc; ch_read_files_trimming }
}
/****************
KRAKEN DB CHANNEL
*****************/
if (params.krakendb.endsWith(".tar.gz")){
    comp_kraken = file(params.krakendb)
    process decomp_kraken {
        input:
            file(ckdb) from comp_kraken
        output:
            file("kraken") into krakendb_ch
        script:
            """
            tar xvzf $ckdb
            """
    }
} else {
    krakendb_ch = file(params.krakendb)
}
/*******************************
SOURCEPREDICT SOURCES AND LABELS
********************************/
sp_labels = file(params.sp_labels, checkIfExists: true)
sp_sources = file(params.sp_sources, checkIfExists: true)
/*******************
Logging parameters
********************/
log.info nfcoreHeader()
log.info " coproID: Coprolite Identification"
log.info " Homepage / Documentation: https://github.com/nf-core/coproid"
log.info " Author: Maxime Borry <borry@shh.mpg.de>"
log.info "================================================================"
def summary = [:]
if (workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name']         = custom_runName ?: workflow.runName
if (params.reads) {
    summary['Reads'] = params.reads
} else {
    summary['Read Path'] = params.readPaths
}
summary['phred quality'] = params.phred
summary['identity threshold'] = params.identity
summary['collapse'] = params.collapse
summary['Ancient DNA'] = params.adna
summary['single_end'] = params.single_end
summary['bowtie setting'] = params.bowtie
if (params.genome1) summary['Genome1'] = params.genome1
if (params.index1) summary["Genome1 BT2 index"] = params.index1
if (params.genome2) summary['Genome2'] = params.genome2
if (params.index2) summary["Genome2 BT2 index"] = params.index2
if (params.genome3) summary['Genome3'] = params.genome3
if (params.index3) summary["Genome3 BT3 index"] = params.index3
summary['Kraken DB'] = params.krakendb
summary['Min Kraken Hits to report Clade'] = params.minKraken
summary['Organism 1'] = params.name1
summary['Organism 2'] = params.name2
if (params.name3) summary['Organism 3'] = params.name3
summary['Sourcepredict sources'] = params.sp_sources
summary['Sourcepredict labels'] = params.sp_labels
summary['PMD Score'] = params.pmdscore
summary['Library type'] = params.library
summary["Result directory"] = params.outdir
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if(workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName
if (workflow.profile.contains('awsbatch')) {
    summary['AWS Region']   = params.awsregion
    summary['AWS Queue']    = params.awsqueue
    summary['AWS CLI']      = params.awscli
}
summary['Config Profile'] = workflow.profile
if (params.config_profile_description) summary['Config Description'] = params.config_profile_description
if (params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if (params.config_profile_url)         summary['Config URL']         = params.config_profile_url
if (params.email || params.email_on_fail) {
    summary['E-mail Address']    = params.email
    summary['E-mail on failure'] = params.email_on_fail
    summary['MultiQC maxsize']   = params.max_multiqc_email_size
}
log.info summary.collect { k,v -> "${k.padRight(25)}: $v" }.join("\n")
log.info "\033[2m----------------------------------------------------\033[0m"
// 0: FASTQC
process fastqc {
    tag "$name"
    input:
        set val(name), file(reads) from ch_read_files_fastqc
    output:
        file '*_fastqc.{zip,html}' into fastqc_results
    script:
        """
        fastqc -q $reads
        """
}
// 0.1    Rename reference genome fasta files
process renameGenome1 {
    input:
        file (genome) from fasta1
    output:
        file (params.name1+".fa") into (genome1Fasta, genome1Size, genome1damageprofiler)
    script:
        outname = params.name1+".fa"
        """
        mv $genome $outname
        """
}
process renameGenome2 {
    input:
        file (genome) from fasta2
    output:
        file (params.name2+".fa") into (genome2Fasta, genome2Size, genome2damageprofiler)
    script:
        outname = params.name2+".fa"
        """
        mv $genome $outname
        """
}
if (params.name3){
    process renameGenome3 {
        input:
            file (genome) from fasta3
        output:
            file (params.name3+".fa") into (genome3Fasta, genome3Size, genome3damageprofiler)
        script:
            outname = params.name3+".fa"
            """
            mv $genome $outname
            """
    }
}
// 1.1:   AdapterRemoval: Adapter trimming, quality filtering, and read merging
if (params.collapse == true && params.single_end == false){
    process AdapterRemovalCollapse {
        tag "$name"
        label 'process_low'
        input:
            set val(name), file(reads) from ch_read_files_trimming
        output:
            set val(name), file('*.trimmed.fastq') into trimmed_reads_genome1, trimmed_reads_genome2, trimmed_reads_genome3, trimmed_reads_kraken
            file("*.settings") into adapter_removal_results
        script:
            out1 = name+".pair1.discarded.fastq"
            out2 = name+".pair2.discarded.fastq"
            col_out = name+".trimmed.fastq"
            settings = name+".settings"
            """
            AdapterRemoval --basename $name \\
                           --file1 ${reads[0]} \\
                           --file2 ${reads[1]} \\
                           --trimns \\
                           --trimqualities \\
                           --collapse \\
                           --minquality 20 \\
                           --minlength 30 \\
                           --output1 $out1 \\
                           --output2 $out2 \\
                           --outputcollapsed $col_out \\
                           --threads ${task.cpus} \\
                           --qualitybase ${params.phred} \\
                           --settings $settings
            """
    }
} else if (params.collapse == false || params.single_end == true) {
    process AdapterRemovalNoCollapse {
        tag "$name"
        label 'process_low'
        input:
            set val(name), file(reads) from ch_read_files_trimming
        output:
            set val(name), file('*.trimmed.fastq') into trimmed_reads_genome1, trimmed_reads_genome2, trimmed_reads_genome3
            file("*.settings") into adapter_removal_results
        script:
            out1 = name+".pair1.trimmed.fastq"
            out2 = name+".pair2.trimmed.fastq"
            se_out = name+".trimmed.fastq"
            settings = name+".settings"
            if (params.single_end == false) {
                """
                AdapterRemoval --basename $name \\
                               --file1 ${reads[0]} \\
                               --file2 ${reads[1]} \\
                               --trimns \\
                               --trimqualities \\
                               --minquality 20 \\
                               --minlength 30 \\
                               --output1 $out1 \\
                               --output2 $out2 \\
                               --threads ${task.cpus} \\
                               --qualitybase ${params.phred} \\
                               --settings $settings
                """
            } else {
                """
                AdapterRemoval --basename $name \\
                               --file1 ${reads[0]} \\
                               --trimns \\
                               --trimqualities \\
                               --minquality 20 \\
                               --minlength 30 \\
                               --output1 $se_out \\
                               --threads ${task.cpus} \\
                               --qualitybase ${params.phred} \\
                               --settings $settings
                """
            }
            
    }
} else {
    println "Problem with --collapse. If --single_end is set to true, you have to set --collapse to false"
    exit(1)
}
if (!params.index1){
    // 1.2:   Bowtie Indexing of Genome1
    process BowtieIndexGenome1 {
        tag "${params.name1}"
        label 'process_medium'
        input:
            file(fasta) from genome1Fasta
        output:
            file("*.bt2") into bt1_ch
        script:
            """
            bowtie2-build $fasta ${bt1_index}
            """
    }
}
// 2.1:   Reads alignment on Genome1
process AlignToGenome1 {
    tag "$name"
    label 'process_medium'
    publishDir "${params.outdir}/alignments/${params.name1}", mode: 'copy', pattern: '*.sorted.bam'
    input:
        set val(name), file(reads) from trimmed_reads_genome1
        file(index) from bt1_ch
    output:
        set val(name), file("*.aligned.sorted.bam") into alignment_genome1, alignment_genome1_pmd
        set val(name), file("*.unaligned.sorted.bam") into unaligned_genome1
        set val(name), file("*.stats.txt") into align1_multiqc
    script:
        samfile = "aligned_"+params.name1+".sam"
        fstat = name+"_"+params.name1+".stats.txt"
        outfile = name+"_"+params.name1+".aligned.sorted.bam"
        outfile_unalign = name+"_"+params.name1+".unaligned.sorted.bam"
        if (params.collapse == true || params.single_end == true) {
            """
            bowtie2 -x $bt1_index -U ${reads[0]} $bowtie_setting --threads ${task.cpus} > $samfile 2> $fstat
            samtools view -S -b -F 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile
            samtools view -S -b -f 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile_unalign
            """
        } else if (params.collapse == false){
            """
            bowtie2 -x $bt1_index -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} > $samfile 2> $fstat
            samtools view -S -b -F 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile
            samtools view -S -b -f 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile_unalign
            """
        }            
}
process bam2fq {
    tag "$name"
    label 'process_medium'
    input:
        set val(name), file(bam) from unaligned_genome1
    output:
        set val(name), file("*.fastq") into unmapped_humans_reads
    script:
        if (paired_end && params.collapse == false){
            out1 = name+"_"+params.name1+".unaligned_R1.fastq"
            out2 = name+"_"+params.name1+".unaligned_R2.fastq"
            """
            samtools fastq -1 $out1 -2 $out2 -0 /dev/null -s /dev/null -n -F 0x900 $bam
            """
        } else {
            out = name+"_"+params.name1+".unaligned.fastq"
            """
            samtools fastq $bam > $out
            """
        }
}   
// 1.3:   Bowtie Indexing of Genome2
if (!params.index2){
    process BowtieIndexGenome2 {
        tag "${params.name2}"
        label 'process_medium'
        input:
            file(fasta) from genome2Fasta
        output:
            file("*.bt2") into bt2_ch
        script:
            """
            bowtie2-build $fasta ${bt2_index}
            """
    }
}
// 1.3:   Bowtie Indexing of Genome2
if (params.name3 && !params.index3) {
    process BowtieIndexGenome3 {
        tag "${params.name2}"
        label 'process_medium'
        input:
            file(fasta) from genome3Fasta
        output:
            file("*.bt2") into bt3_ch
        script:
            """
            bowtie2-build $fasta ${bt3_index}
            """
    }
}
// 2.2:   Reads alignment on Genome2
process AlignToGenome2 {
    tag "$name"
    label 'process_medium'
    publishDir "${params.outdir}/alignments/${params.name2}", mode: 'copy', pattern: '*.sorted.bam'
    input:
        set val(name), file(reads) from trimmed_reads_genome2
        file(index) from bt2_ch
    output:
        set val(name), file("*.aligned.sorted.bam") into alignment_genome2, alignment_genome2_pmd
        set val(name), file("*.unaligned.sorted.bam") into unaligned_genome2
        set val(name), file("*.stats.txt") into align2_multiqc
    script:
        samfile = "aligned_"+params.name2+".sam"
        fstat = name+"_"+params.name2+".stats.txt"
        outfile = name+"_"+params.name2+".aligned.sorted.bam"
        outfile_unalign = name+"_"+params.name2+".unaligned.sorted.bam"
        if (params.collapse == true || params.single_end == true) {
            """
            bowtie2 -x $bt2_index -U ${reads[0]} $bowtie_setting --threads ${task.cpus} > $samfile 2> $fstat
            samtools view -S -b -F 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile
            samtools view -S -b -f 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile_unalign
            """
        } else if (params.collapse == false){
            """
            bowtie2 -x $bt2_index -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} > $samfile 2> $fstat
            samtools view -S -b -F 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile
            samtools view -S -b -f 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile_unalign
            """
        }            
}
// 2.2:   Reads alignment on Genome3
if (params.name3) {
    process AlignToGenome3 {
        tag "$name"
        label 'process_medium'
        publishDir "${params.outdir}/alignments/${params.name1}", mode: 'copy', pattern: '*.sorted.bam'
        input:
            set val(name), file(reads) from trimmed_reads_genome3
            file(index) from bt3_ch
        output:
            set val(name), file("*.aligned.sorted.bam") into alignment_genome3, alignment_genome3_pmd
            set val(name), file("*.unaligned.sorted.bam") into unaligned_genome3
            set val(name), file("*.stats.txt") into align3_multiqc
        script:
            samfile = "aligned_"+params.name3+".sam"
            fstat = name+"_"+params.name3+".stats.txt"
            outfile = name+"_"+params.name3+".aligned.sorted.bam"
            outfile_unalign = name+"_"+params.name3+".unaligned.sorted.bam"
            if (params.collapse == true || params.single_end == true) {
                """
                bowtie2 -x $bt3_index -U ${reads[0]} $bowtie_setting --threads ${task.cpus} > $samfile 2> $fstat
                samtools view -S -b -F 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile
                samtools view -S -b -f 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile_unalign
                """
            } else if (params.collapse == false){
                """
                bowtie2 -x $bt3_index -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} > $samfile 2> $fstat
                samtools view -S -b -F 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile
                samtools view -S -b -f 4 -@ ${task.cpus} $samfile | samtools sort -@ ${task.cpus} -o $outfile_unalign
                """
            }            
    }
}
// 3:     Checking for read PMD with PMDtools
if (params.adna){
    process pmdtoolsgenome1 {
    tag "$name"
    publishDir "${params.outdir}/pmdtools/${params.name1}", mode: 'copy', pattern: '*.pmd_filtered.bam'
    input:
        set val(name), file(bam1) from alignment_genome1_pmd
    output:
        set val(name), file("*.pmd_filtered.bam") into pmd_aligned1
    script:
        outfile = name+"_"+params.name1+".pmd_filtered.bam"
        """
        samtools view -h -F 4 $bam1 | pmdtools -t ${params.pmdscore} --header $library | samtools view -Sb - > $outfile
        """
    }
    process pmdtoolsgenome2 {
        tag "$name"
        publishDir "${params.outdir}/pmdtools/${params.name2}", mode: 'copy', pattern: '*.pmd_filtered.bam'
        input:
            set val(name), file(bam2) from alignment_genome2_pmd
        output:
            set val(name), file("*.pmd_filtered.bam") into pmd_aligned2
        script:
            outfile = name+"_"+params.name2+".pmd_filtered.bam"
            """
            samtools view -h -F 4 $bam2 | pmdtools -t ${params.pmdscore} --header $library | samtools view -Sb - > $outfile
            """
    }
    if (params.name3 != ''){
        process pmdtoolsgenome3 {
        tag "$name"
        publishDir "${params.outdir}/pmdtools/${params.name3}", mode: 'copy', pattern: '*.pmd_filtered.bam'
        input:
            set val(name), file(bam3) from alignment_genome3_pmd
        output:
            set val(name), file("*.pmd_filtered.bam") into pmd_aligned3
        script:
            outfile = name+"_"+params.name3+".pmd_filtered.bam"
            """
            samtools view -h -F 4 $bam3 | pmdtools -t ${params.pmdscore} --header $library | samtools view -Sb - > $outfile
            """
        }
    }   
}
process kraken2 {
    tag "$name"
    label 'process_medium'
    input:
        set val(name), file(reads) from unmapped_humans_reads
        file(krakendb) from krakendb_ch
    output:
        set val(name), file('*.kraken.out') into kraken_out
        set val(name), file('*.kreport') into kraken_report
    script:
        out = name+".kraken.out"
        kreport = name+".kreport"
        if (paired_end && params.collapse == false){
            """
            kraken2 --db ${krakendb} \\
                    --threads ${task.cpus} \\
                    --output $out \\
                    --report $kreport \\
                    --paired ${reads[0]} ${reads[1]}
            """    
        } else {
            """
            kraken2 --db ${krakendb} \\
                    --threads ${task.cpus} \\
                    --output $out \\
                    --report $kreport ${reads[0]}
            """
        }
        
}
process kraken_parse {
    tag "$name"
    input:
        set val(name), file(kraken_r) from kraken_report
    output:
        file('*.kraken_parsed.csv') into kraken_parsed
    script:
        out = name+".kraken_parsed.csv"
        """
    python ${workflow.launchDir}/bin/kraken_parse.py -c ${params.minKraken} $kraken_r
        """    
}
process kraken_merge {
    publishDir "${params.outdir}/kraken", mode: 'copy'
    input:
        file(csv_count) from kraken_parsed.collect()
    output:
        file('kraken_merged.csv') into kraken_merged
    script:
        out = "kraken_merged.csv"
        """
    python ${workflow.launchDir}/bin/merge_kraken_res.py -o $out
        """    
}
process sourcepredict {
    label 'process_high'
    input:
        file(otu_table) from kraken_merged
        file(sp_sources) from sp_sources
        file(sp_labels) from sp_labels
    output:
        file('*.sourcepredict.csv') into sourcepredict_out
        file('*_embedding.csv') into sourcepredict_embed_out
    script:
        outfile = "prediction.sourcepredict.csv"
        embed_out = "sourcepredict_embedding.csv"
        """
        sourcepredict -di ${params.sp_dim} \\
                      -kne ${params.sp_neighbors} \\
                      -me ${params.sp_embed} \\
                      -n ${params.sp_norm} \\
                      -l ${sp_labels} \\
                      -s ${sp_sources} \\
                      -t ${task.cpus} \\
                      -o $outfile \\
                      -e $embed_out $otu_table 
        """
}
// 4:   Count aligned bp on each genome and compute ratio
if (params.name3 == ''){
    process countBp2genomes{
    tag "$name"
    label 'process_low'
    input:
        set val(name), file(abam1), file(abam2), file(bam1), file(bam2) from ( (params.adna ? pmd_aligned1.join(pmd_aligned2) : alignment_genome1_pmd.join(alignment_genome2_pmd)).join(alignment_genome1).join(alignment_genome2))
        file(genome1) from genome1Size
        file(genome2) from genome2Size
    output:
        set val(name), file("*.bpc.csv") into bp_count
        set val(name), file("*"+params.name1+".ancient.filtered.bam") optional true into ancient_filtered_bam1
        set val(name), file("*"+params.name2+".ancient.filtered.bam") optional true into ancient_filtered_bam2
    script:
        outfile = name+".bpc.csv"
        organame1 = params.name1
        organame2 = params.name2
        obam1 = name+"_"+organame1+".filtered.bam"
        obam2 = name+"_"+organame2+".filtered.bam"
        if (params.adna) {
            aobam1 = name+"_"+organame1+".ancient.filtered.bam"
            aobam2 = name+"_"+organame2+".ancient.filtered.bam" 
            """
            samtools index $bam1
            samtools index $bam2
            samtools index $abam1
            samtools index $abam2
    python3 ${workflow.launchDir}/bin/normalizedReadCount -n $name \\
                                -b1 $bam1 \\
                                -ab1 $abam1 \\
                                -b2 $bam2 \\
                                -ab2 $abam2 \\
                                -g1 $genome1 \\
                                -g2 $genome2 \\
                                -r1 $organame1 \\
                                -r2 $organame2 \\
                                -i ${params.identity} \\
                                -o $outfile \\
                                -ob1 $obam1 \\
                                -aob1 $aobam1 \\
                                -ob2 $obam2 \\
                                -aob2 $aobam2 \\
                                -ed1 ${params.endo1} \\
                                -ed2 ${params.endo2} \\
                                -p ${task.cpus}
            """
        }
        else {
            """
            samtools index $bam1
            samtools index $bam2
    python3 ${workflow.launchDir}/bin/normalizedReadCount -n $name \\
                                -b1 $bam1 \\
                                -b2 $bam2 \\
                                -g1 $genome1 \\
                                -g2 $genome2 \\
                                -r1 $organame1 \\
                                -r2 $organame2 \\
                                -i ${params.identity} \\
                                -o $outfile \\
                                -ob1 $obam1 \\
                                -ob2 $obam2 \\
                                -ed1 ${params.endo1} \\
                                -ed2 ${params.endo2} \\
                                -p ${task.cpus}
            """
        }
        
    }
} else {
    process countBp3genomes{
    tag "$name"
    label 'process_low'
    echo true
    input:
        set val(name), file(abam1), file(abam2), file(abam3), file(bam1), file(bam2), file(bam3) from ( (params.adna ? pmd_aligned1.join(pmd_aligned2).join(pmd_aligned3) : alignment_genome1_pmd.join(alignment_genome2_pmd).join(alignment_genome3_pmd)).join(alignment_genome1).join(alignment_genome2).join(alignment_genome3))
        file(genome1) from genome1Size
        file(genome2) from genome2Size
        file(genome3) from genome3Size
    output:
        set val(name), file("*.bpc.csv") into bp_count
        set val(name), file("*"+params.name1+".ancient.filtered.bam") optional true into ancient_filtered_bam1
        set val(name), file("*"+params.name2+".ancient.filtered.bam") optional true into ancient_filtered_bam2
        set val(name), file("*"+params.name3+".ancient.filtered.bam") optional true into ancient_filtered_bam3
    script:
        outfile = name+".bpc.csv"
        organame1 = params.name1
        organame2 = params.name2
        organame3 = params.name3
        obam1 = name+"_"+organame1+".filtered.bam"
        obam2 = name+"_"+organame2+".filtered.bam"
        obam3 = name+"_"+organame3+".filtered.bam"
        if (params.adna) {
            aobam1 = name+"_"+organame1+".ancient.filtered.bam"
            aobam2 = name+"_"+organame2+".ancient.filtered.bam"
            aobam3 = name+"_"+organame3+".ancient.filtered.bam"
            """
            samtools index $bam1
            samtools index $bam2
            samtools index $bam3
            samtools index $abam1
            samtools index $abam2
            samtools index $abam3
    python3 ${workflow.launchDir}/bin/normalizedReadCount -n $name \\
                                -b1 $bam1 \\
                                -ab1 $abam1 \\
                                -b2 $bam2 \\
                                -ab2 $abam2 \\
                                -b3 $bam3 \\
                                -ab3 $abam3 \\
                                -g1 $genome1 \\
                                -g2 $genome2 \\
                                -g3 $genome3 \\
                                -r1 $organame1 \\
                                -r2 $organame2 \\
                                -r3 $organame3 \\
                                -i ${params.identity} \\
                                -o $outfile \\
                                -ob1 $obam1 \\
                                -aob1 $aobam1 \\
                                -ob2 $obam2 \\
                                -aob2 $aobam2 \\
                                -ob3 $obam3 \\
                                -aob3 $aobam3 \\
                                -ed1 ${params.endo1} \\
                                -ed2 ${params.endo2} \\
                                -ed3 ${params.endo3} \\
                                -p ${task.cpus}
            """
        } else {
            """
            samtools index $bam1
            samtools index $bam2
            samtools index $bam3
    python3 ${workflow.launchDir}/bin/normalizedReadCount -n $name \\
                                -b1 $bam1 \\
                                -b2 $bam2 \\
                                -b3 $bam3 \\
                                -g1 $genome1 \\
                                -g2 $genome2 \\
                                -g3 $genome3 \\
                                -r1 $organame1 \\
                                -r2 $organame2 \\
                                -r3 $organame3 \\
                                -i ${params.identity} \\
                                -o $outfile \\
                                -ob1 $obam1 \\
                                -ob2 $obam2 \\
                                -ob3 $obam3 \\
                                -ed1 ${params.endo1} \\
                                -ed2 ${params.endo2} \\
                                -ed3 ${params.endo3} \\
                                -p ${task.cpus}
            """
        }
    }
}
// 5:     damageprofiler
if (params.adna){
    process damageprofilerGenome1 {
    tag "$name"
    publishDir "${params.outdir}/damageprofiler/${params.name1}", mode: 'copy'
    input:
        set val(name), file(align) from ancient_filtered_bam1
        file(fasta) from genome1damageprofiler
    output:
        file("*_freq.txt") into damage_result_genome1
        file("*dmgprof.json") into dmgProf1_ch
    script:
        fwd_name = name+"_otu_"+params.name1+".5pCtoT_freq.txt"
        rev_name = name+"_otu_"+params.name1+".3pGtoA_freq.txt"
        bam_name = "${name}_${params.name1}.bam"
        smp_name = "${name}_${params.name1}"
        """
        mv $align $bam_name
        damageprofiler -i $bam_name -r $fasta -o tmp
        mv tmp/${smp_name}/5pCtoT_freq.txt $fwd_name
        mv tmp/${smp_name}/3pGtoA_freq.txt $rev_name
        mv tmp/${smp_name}/dmgprof.json ${smp_name}.dmgprof.json
        """
    }
    process damageprofilerGenome2 {
        tag "$name"
        publishDir "${params.outdir}/damageprofiler/${params.name2}", mode: 'copy'
        input:
            set val(name), file(align) from ancient_filtered_bam2
            file(fasta) from genome2damageprofiler
        output:
            file("*_freq.txt") into damage_result_genome2
            file("*dmgprof.json") into dmgProf2_ch
        script:
            fwd_name = name+"_otu_"+params.name2+".5pCtoT_freq.txt"
            rev_name = name+"_otu_"+params.name2+".3pGtoA_freq.txt"
            bam_name = "${name}_${params.name2}.bam"
            smp_name = "${name}_${params.name2}"
            """
            mv $align $bam_name
            damageprofiler -i $bam_name -r $fasta -o tmp
            mv tmp/${smp_name}/5pCtoT_freq.txt $fwd_name
            mv tmp/${smp_name}/3pGtoA_freq.txt $rev_name
            mv tmp/${smp_name}/dmgprof.json ${smp_name}.dmgprof.json
            """
    }
    if (params.name3 != ""){
        process damageprofilerGenome3 {
        tag "$name"
        publishDir "${params.outdir}/damageprofiler/${params.name3}", mode: 'copy'
        input:
            set val(name), file(align) from ancient_filtered_bam3
            file(fasta) from genome3damageprofiler
        output:
            file("*_freq.txt") into damage_result_genome3
            file("*dmgprof.json") into dmgProf3_ch
        script:
            fwd_name = name+"_otu_"+params.name3+".5pCtoT_freq.txt"
            rev_name = name+"_otu_"+params.name3+".3pGtoA_freq.txt"
            bam_name = "${name}_${params.name3}.bam"
            smp_name = "${name}_${params.name3}"
            """
            mv $align $bam_name
            damageprofiler -i $bam_name -r $fasta -o tmp
            mv tmp/${smp_name}/5pCtoT_freq.txt $fwd_name
            mv tmp/${smp_name}/3pGtoA_freq.txt $rev_name
            mv tmp/${smp_name}/dmgprof.json ${smp_name}.dmgprof.json
            """
        }
    }
}
// 6: concatenate read ratios
process concatenateRatios {
    publishDir "${params.outdir}", mode: 'copy', pattern: '*.csv'
    input:
        file(count) from bp_count.collect()
        file(sp) from sourcepredict_out
    output:
        file("coproID_result.csv") into coproid_res
        file("coproID_bp.csv") into coproid_bp_count
    script:
        outfile = "coproID_result.csv"
        """
        ls -1 *.bpc.csv | head -1 | xargs head -1 > coproID_bp.csv
        tail -q -n +2 *.bpc.csv >> coproID_bp.csv
    python ${workflow.launchDir}/bin/merge_bp_sp.py -c coproID_bp.csv -s $sp -o $outfile
        """
}
// Make report
if (params.adna) {
    if (params.name3) {
        process generate_report_adna_3_genomes {
            publishDir "${params.outdir}", mode: 'copy'
            input:
                file(copro_csv) from coproid_res
                file(thelogo) from  
                file(dplot1) from damage_result_genome1.collect().ifEmpty([])
                file(dplot1) from damage_result_genome2.collect().ifEmpty([])
                file(dplot3) from damage_result_genome3.collect().ifEmpty([])
                file(umap) from  sourcepredict_embed_out
                file(report) from report_template_ch
            output:
                file("*.html") into coproid_report
            script:
                """
                echo ${workflow.manifest.version} > version.txt
                jupyter nbconvert \\
                        --TagRemovePreprocessor.remove_input_tags='{"remove_cell"}' \\
                        --TagRemovePreprocessor.remove_all_outputs_tags='{"remove_output"}' \\
                        --TemplateExporter.exclude_input_prompt=True \\
                        --TemplateExporter.exclude_output_prompt=True \\
                        --ExecutePreprocessor.timeout=200 \\
                        --execute \\
                        --to html_embed $report
                """
        }
    } else {
        process generate_report_adna_2_genomes {
            publishDir "${params.outdir}", mode: 'copy'
            input:
                file(copro_csv) from coproid_res
                file(thelogo) from coproid_logo
                file(dplot1) from damage_result_genome1.collect().ifEmpty([])
                file(dplot1) from damage_result_genome2.collect().ifEmpty([])
                file(umap) from  sourcepredict_embed_out
                file(report) from report_template_ch
            output:
                file("*.html") into coproid_report
            script:
                """
                echo ${workflow.manifest.version} > version.txt
                jupyter nbconvert \\
                        --TagRemovePreprocessor.remove_input_tags='{"remove_cell"}' \\
                        --TagRemovePreprocessor.remove_all_outputs_tags='{"remove_output"}' \\
                        --TemplateExporter.exclude_input_prompt=True \\
                        --TemplateExporter.exclude_output_prompt=True \\
                        --ExecutePreprocessor.timeout=200 \\
                        --execute \\
                        --to html_embed $report
                """
        }
    }
} else {
    process generate_report {
        publishDir "${params.outdir}", mode: 'copy', pattern: '*.html'
        input:
            file(copro_csv) from coproid_res
            file(umap) from  sourcepredict_embed_out
            file(report) from report_template_ch
        output:
            file("*.html") into coproid_report
        script:
            """
            echo ${workflow.manifest.version} > version.txt
            jupyter nbconvert \\
                    --TagRemovePreprocessor.remove_input_tags='{"remove_cell"}' \\
                    --TagRemovePreprocessor.remove_all_outputs_tags='{"remove_output"}' \\
                    --TemplateExporter.exclude_input_prompt=True \\
                    --TemplateExporter.exclude_output_prompt=True \\
                    --ExecutePreprocessor.timeout=200 \\
                    --execute \\
                    --to html_embed $report
            """
    }
} 
/*
 * Parse software version numbers
 */
process get_software_versions {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy',
        saveAs: { filename ->
                      if (filename.indexOf(".csv") > 0) filename
                      else null
                }
    output:
    file 'software_versions_mqc.yaml' into ch_software_versions_yaml
    file "software_versions.csv"
    script:
    """
    echo $workflow.manifest.version > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    fastqc --version > v_fastqc.txt
    multiqc --version > v_multiqc.txt
    sourcepredict -h  > v_sourcepredict.txt
    samtools --version > v_samtools.txt
    kraken2 --version > v_kraken2.txt
    bowtie2 --version > v_bowtie2.txt
    python --version > v_python.txt
    AdapterRemoval --version 2> v_adapterremoval.txt
    python ${workflow.launchDir}/bin/scrape_software_versions.py &> software_versions_mqc.yaml
    """
}
// 9:     MultiQC
process multiqc {
    publishDir "${params.outdir}", mode: 'copy'
    input:
        file (ar:'adapter_removal/*') from adapter_removal_results.collect()
        file (al1: 'alignment/*') from align1_multiqc.collect()
        file ('fastqc/*') from fastqc_results.collect()
        file ('DamageProfiler/*') from dmgProf1_ch.collect()
        file ('DamageProfiler/*') from dmgProf2_ch.collect()
        file ('software_versions/*') from ch_software_versions_yaml.collect()
        file(multiqc_conf) from ch_multiqc_config
        file logo from coproid_logo
    output:
        file 'multiqc_report.html' into multiqc_report
    script:
        """
        multiqc -f -d adapter_removal alignment fastqc DamageProfiler software_versions software_versions -c $multiqc_conf
        """
}
// Check the hostnames against configured profiles
checkHostname()
def create_workflow_summary(summary) {
    def yaml_file = workDir.resolve('workflow_summary_mqc.yaml')
    yaml_file.text  = """
    id: 'nf-core-coproid-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'nf-core/coproid Workflow Summary'
    section_href: 'https://github.com/nf-core/coproid'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
        </dl>
    """.stripIndent()
   return yaml_file
}
/*
 * STEP 3 - Output Description HTML
 */
process output_documentation {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'
    input:
    file output_docs from ch_output_docs
    output:
    file "results_description.html"
    script:
    """
    python ${workflow.launchDir}/bin/markdown_to_html.py $output_docs -o results_description.html
    """
}
/*
 * Completion e-mail notification
 */
// workflow.onComplete {
//     // Set up the e-mail variables
//     def subject = "[nf-core/coproid] Successful: $workflow.runName"
//     if (!workflow.success) {
//         subject = "[nf-core/coproid] FAILED: $workflow.runName"
//     }
//     def email_fields = [:]
//     email_fields['version'] = workflow.manifest.version
//     email_fields['runName'] = custom_runName ?: workflow.runName
//     email_fields['success'] = workflow.success
//     email_fields['dateComplete'] = workflow.complete
//     email_fields['duration'] = workflow.duration
//     email_fields['exitStatus'] = workflow.exitStatus
//     email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
//     email_fields['errorReport'] = (workflow.errorReport ?: 'None')
//     email_fields['commandLine'] = workflow.commandLine
//     email_fields['projectDir'] = workflow.projectDir
//     email_fields['summary'] = summary
//     email_fields['summary']['Date Started'] = workflow.start
//     email_fields['summary']['Date Completed'] = workflow.complete
//     email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
//     email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
//     if (workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
//     if (workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
//     if (workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
//     email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
//     email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
//     email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp
//     // On success try attach the multiqc report
//     def mqc_report = null
//     try {
//         if (workflow.success) {
//             mqc_report = ch_multiqc_report.getVal()
//             if (mqc_report.getClass() == ArrayList) {
//                 log.warn "[nf-core/coproid] Found multiple reports from process 'multiqc', will use only one"
//                 mqc_report = mqc_report[0]
//             }
//         }
//     } catch (all) {
//         log.warn "[nf-core/coproid] Could not attach MultiQC report to summary email"
//     }
//     // Check if we are only sending emails on failure
//     email_address = params.email
//     if (!params.email && params.email_on_fail && !workflow.success) {
//         email_address = params.email_on_fail
//     }
//     // Render the TXT template
//     def engine = new groovy.text.GStringTemplateEngine()
//     def tf = new File("$baseDir/assets/email_template.txt")
//     def txt_template = engine.createTemplate(tf).make(email_fields)
//     def email_txt = txt_template.toString()
//     // Render the HTML template
//     def hf = new File("$baseDir/assets/email_template.html")
//     def html_template = engine.createTemplate(hf).make(email_fields)
//     def email_html = html_template.toString()
//     // Render the sendmail template
//     def smail_fields = [ email: email_address, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.max_multiqc_email_size.toBytes() ]
//     def sf = new File("$baseDir/assets/sendmail_template.txt")
//     def sendmail_template = engine.createTemplate(sf).make(smail_fields)
//     def sendmail_html = sendmail_template.toString()
//     // Send the HTML e-mail
//     if (email_address) {
//         try {
//             if (params.plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }
//             // Try to send HTML e-mail using sendmail
//             [ 'sendmail', '-t' ].execute() << sendmail_html
//             log.info "[nf-core/coproid] Sent summary e-mail to $email_address (sendmail)"
//         } catch (all) {
//             // Catch failures and try with plaintext
//             [ 'mail', '-s', subject, email_address ].execute() << email_txt
//             log.info "[nf-core/coproid] Sent summary e-mail to $email_address (mail)"
//         }
//     }
//     // Write summary e-mail HTML to a file
//     def output_d = new File("${params.outdir}/pipeline_info/")
//     if (!output_d.exists()) {
//         output_d.mkdirs()
//     }
//     def output_hf = new File(output_d, "pipeline_report.html")
//     output_hf.withWriter { w -> w << email_html }
//     def output_tf = new File(output_d, "pipeline_report.txt")
//     output_tf.withWriter { w -> w << email_txt }
//     c_green = params.monochrome_logs ? '' : "\033[0;32m";
//     c_purple = params.monochrome_logs ? '' : "\033[0;35m";
//     c_red = params.monochrome_logs ? '' : "\033[0;31m";
//     c_reset = params.monochrome_logs ? '' : "\033[0m";
//     if (workflow.stats.ignoredCount > 0 && workflow.success) {
//         log.info "-${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}-"
//         log.info "-${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}-"
//         log.info "-${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}-"
//     }
//     if (workflow.success) {
//         log.info "-${c_purple}[nf-core/coproid]${c_green} Pipeline completed successfully${c_reset}-"
//     } else {
//         checkHostname()
//         log.info "-${c_purple}[nf-core/coproid]${c_red} Pipeline completed with errors${c_reset}-"
//     }
// }
def nfcoreHeader() {
    // Log colors ANSI codes
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";
    return """    -${c_dim}--------------------------------------------------${c_reset}-
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  nf-core/coproid v${workflow.manifest.version}${c_reset}
    -${c_dim}--------------------------------------------------${c_reset}-
    """.stripIndent()
}
def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}
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
