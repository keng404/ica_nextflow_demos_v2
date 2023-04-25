//
// Uncompress and prepare reference genome files
//
include { GTF2BED } from '../../modules/local/gtf2bed'
include { GTF_GENE_FILTER } from '../../modules/local/gtf_gene_filter'
include {
    GUNZIP as GUNZIP_FASTA
    GUNZIP as GUNZIP_GTF
    GUNZIP as GUNZIP_GFF
    GUNZIP as GUNZIP_GENE_BED } from '../../modules/nf-core/gunzip/main'
include { UNTAR as UNTAR_BWA_INDEX
          UNTAR as UNTAR_DRAGMAP } from '../../modules/nf-core/untar/main'
include { SAMTOOLS_FAIDX } from '../../modules/nf-core/samtools/faidx/main'
include { GFFREAD } from '../../modules/nf-core/gffread/main'
include { BWA_INDEX } from '../../modules/nf-core/bwa/index/main'
include { BWAMEM2_INDEX } from '../../modules/nf-core/bwamem2/index/main'
include { DRAGMAP_HASHTABLE } from '../../modules/nf-core/dragmap/hashtable/main'
include { CUSTOM_GETCHROMSIZES } from '../../modules/nf-core/custom/getchromsizes/main'
workflow PREPARE_GENOME {
    take:
    prepare_tool_indices
    main:
    ch_versions = Channel.empty()
    //
    // Uncompress genome fasta file if required
    //
    if (params.fasta.endsWith('.gz')) {
        ch_fasta = GUNZIP_FASTA ( [ [:], params.fasta ] ).gunzip.map { it[1] }
        ch_versions = ch_versions.mix(GUNZIP_FASTA.out.versions)
    } else {
        ch_fasta = file(params.fasta)
    }
    // Create Fai file
    ch_fai = SAMTOOLS_FAIDX( [ [:], ch_fasta ] ).fai.map { it[1] }
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)
    //
    // Uncompress GTF annotation file or create from GFF3 if required
    //
    if (params.gtf) {
        if (params.gtf.endsWith('.gz')) {
            ch_gtf = GUNZIP_GTF ( [ [:], params.gtf ] ).gunzip.map { it[1] }
            ch_versions = ch_versions.mix(GUNZIP_GTF.out.versions)
        } else {
            ch_gtf = file(params.gtf)
        }
    } else if (params.gff) {
        if (params.gff.endsWith('.gz')) {
            ch_gff = GUNZIP_GFF ( [ [:], params.gff ] ).gunzip.map { it[1] }
            ch_versions = ch_versions.mix(GUNZIP_GFF.out.versions)
        } else {
            ch_gff = file(params.gff)
        }
        ch_gtf = GFFREAD ( ch_gff ).gtf
        ch_versions = ch_versions.mix(GFFREAD.out.versions)
    }
    //
    // Uncompress gene BED annotation file or create from GTF if required
    //
    if (params.gene_bed) {
        if (params.gene_bed.endsWith('.gz')) {
            ch_gene_bed = GUNZIP_GENE_BED ( [ [:], params.gene_bed ] ).gunzip.map { it[1] }
            ch_versions = ch_versions.mix(GUNZIP_GENE_BED.out.versions)
        } else {
            ch_gene_bed = file(params.gene_bed)
        }
    } else {
        ch_gene_bed = GTF2BED ( ch_gtf ).bed
        ch_versions = ch_versions.mix(GTF2BED.out.versions)
    }
    //
    // Create chromosome sizes file
    //
    ch_chrom_sizes = CUSTOM_GETCHROMSIZES ( [ [:], ch_fasta ] ).sizes
    ch_versions = ch_versions.mix(CUSTOM_GETCHROMSIZES.out.versions)
    //
    // Uncompress BWA index or generate from scratch if required
    //
    ch_bwa_index = Channel.empty()
    ch_dragmap = Channel.empty()
    if ('bwa' in prepare_tool_indices) {
        if (params.bwa_index) {
            if (params.bwa_index.endsWith('.tar.gz')) {
                ch_bwa_index = UNTAR_BWA_INDEX ( params.bwa_index ).untar
                ch_versions = ch_versions.mix(UNTAR_BWA_INDEX.out.versions)
            } else {
                ch_bwa_index = file(params.bwa_index)
            }
        } else {
            ch_bwa_index = BWA_INDEX ( ch_fasta ).index
            ch_versions = ch_versions.mix(BWA_INDEX.out.versions)
        }
    } else if ('bwamem2' in prepare_tool_indices) {
        if (params.bwamem2_index) {
            if (params.bwamem2_index.endsWith('.tar.gz') || params.bwamem2_index.endsWith('.tgz')) {
                ch_bwa_index = UNTAR_BWA_INDEX ( [ [:], params.bwamem2_index ] ).untar
                ch_versions = ch_versions.mix(UNTAR_BWA_INDEX.out.versions)
            } else {
                ch_bwa_index = file(params.bwamem2_index)
            }
        } else {
            ch_bwa_index = BWAMEM2_INDEX ( [ [:], ch_fasta ] ).index
            ch_versions = ch_versions.mix(BWAMEM2_INDEX.out.versions)
        }
    } else if ('dragmap' in prepare_tool_indices) {
        if (params.dragmap) {
            if (params.dragmap.endsWith('.tar.gz')) {
                ch_bwa_index = UNTAR_DRAGMAP_INDEX ( params.dragmap ).untar
                ch_versions = ch_versions.mix(UNTAR_DRAGMAP_INDEX.out.versions)
            } else {
                ch_bwa_index = file(params.dragmap)
            }
        } else {
            ch_dragmap = DRAGMAP_HASHTABLE( ch_fasta ).hashmap
            ch_versions = ch_versions.mix(DRAGMAP_HASHTABLE.out.versions)
        }
    }
    emit:
    fasta = ch_fasta
    fai = ch_fai
    gtf = ch_gtf
    gene_bed = ch_gene_bed
    chrom_sizes = ch_chrom_sizes
    bwa_index = ch_bwa_index
    dragmap = ch_dragmap
    versions = ch_versions.ifEmpty(null)
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
