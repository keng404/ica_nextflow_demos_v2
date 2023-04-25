/*
 * Alignment with BOWTIE2
 */
include { BOWTIE2_ALIGN                                  } from '../../modules/nf-core/bowtie2/align/main'
include { BOWTIE2_ALIGN as BOWTIE2_SPIKEIN_ALIGN         } from '../../modules/nf-core/bowtie2/align/main'
include { BAM_SORT_SAMTOOLS                              } from '../nf-core/bam_sort_samtools'
include { BAM_SORT_SAMTOOLS as BAM_SORT_SAMTOOLS_SPIKEIN } from '../nf-core/bam_sort_samtools'
workflow ALIGN_BOWTIE2 {
    take:
    reads         // channel: [ val(meta), [ reads ] ]
    index         // channel: /path/to/bowtie2/target/index/
    spikein_index // channel: /path/to/bowtie2/spikein/index/
    main:
    ch_versions = Channel.empty()
    /*
     * Map reads with BOWTIE2 to target genome
     */
    BOWTIE2_ALIGN ( reads, index, params.save_unaligned, false )
    ch_versions = ch_versions.mix(BOWTIE2_ALIGN.out.versions)
    /*
     * Map reads with BOWTIE2 to spike-in genome
     */
    BOWTIE2_SPIKEIN_ALIGN ( reads, spikein_index, params.save_unaligned, false )
    /*
     * Sort, index BAM file and run samtools stats, flagstat and idxstats
     */
    BAM_SORT_SAMTOOLS ( BOWTIE2_ALIGN.out.bam )
    ch_versions = ch_versions.mix(BAM_SORT_SAMTOOLS.out.versions)
    BAM_SORT_SAMTOOLS_SPIKEIN ( BOWTIE2_SPIKEIN_ALIGN.out.bam )
    emit:
    versions             = ch_versions                            // channel: [ versions.yml ]
    orig_bam             = BOWTIE2_ALIGN.out.bam                  // channel: [ val(meta), bam ]
    orig_spikein_bam     = BOWTIE2_SPIKEIN_ALIGN.out.bam          // channel: [ val(meta), bam ]
    bowtie2_log          = BOWTIE2_ALIGN.out.log                  // channel: [ val(meta), log_final ]
    bowtie2_spikein_log  = BOWTIE2_SPIKEIN_ALIGN.out.log          // channel: [ val(meta), log_final ]
    bam                  = BAM_SORT_SAMTOOLS.out.bam              // channel: [ val(meta), [ bam ] ]
    bai                  = BAM_SORT_SAMTOOLS.out.bai              // channel: [ val(meta), [ bai ] ]
    stats                = BAM_SORT_SAMTOOLS.out.stats            // channel: [ val(meta), [ stats ] ]
    flagstat             = BAM_SORT_SAMTOOLS.out.flagstat         // channel: [ val(meta), [ flagstat ] ]
    idxstats             = BAM_SORT_SAMTOOLS.out.idxstats         // channel: [ val(meta), [ idxstats ] ]
    spikein_bam          = BAM_SORT_SAMTOOLS_SPIKEIN.out.bam      // channel: [ val(meta), [ bam ] ]
    spikein_bai          = BAM_SORT_SAMTOOLS_SPIKEIN.out.bai      // channel: [ val(meta), [ bai ] ]
    spikein_stats        = BAM_SORT_SAMTOOLS_SPIKEIN.out.stats    // channel: [ val(meta), [ stats ] ]
    spikein_flagstat     = BAM_SORT_SAMTOOLS_SPIKEIN.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    spikein_idxstats     = BAM_SORT_SAMTOOLS_SPIKEIN.out.idxstats // channel: [ val(meta), [ idxstats ] ]
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
