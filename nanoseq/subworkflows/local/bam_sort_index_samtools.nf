/*
 * Sort, index BAM file and run samtools stats, flagstat and idxstats
 */
include { SAMTOOLS_VIEW_BAM  } from '../../modules/local/samtools_view_bam'
include { SAMTOOLS_SORT      } from '../../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_INDEX     } from '../../modules/nf-core/modules/samtools/index/main'
include { SAMTOOLS_SORT_INDEX } from '../../modules/local/samtools_sort_index'
include { BAM_STATS_SAMTOOLS } from '../../subworkflows/nf-core/bam_stats_samtools'
workflow BAM_SORT_INDEX_SAMTOOLS {
    take:
    ch_sam // channel: [ val(meta), [ bam ] ]
    call_variants
    ch_fasta
    main:
    /*
     * Sam to bam conversion
     */
    SAMTOOLS_VIEW_BAM  ( ch_sam )
    if ( call_variants ) {
        SAMTOOLS_SORT_INDEX ( SAMTOOLS_VIEW_BAM.out.bam )
        ch_sam
            .join( SAMTOOLS_SORT_INDEX.out.bam_bai )
            .map { it -> [ it[0], it[1], it[2], it[4], it[5] ] }
            .set { sortbam }
        BAM_STATS_SAMTOOLS ( SAMTOOLS_SORT_INDEX.out.bam_bai, ch_fasta )
    } else {
        SAMTOOLS_SORT      ( SAMTOOLS_VIEW_BAM.out.bam )
        SAMTOOLS_INDEX     ( SAMTOOLS_SORT.out.bam )
        ch_sam
            .join( SAMTOOLS_SORT.out.bam )
            .join( SAMTOOLS_INDEX.out.bai )
            .map { it -> [ it[0], it[1], it[2], it[4], it[5] ] }
            .set { sortbam }
        BAM_STATS_SAMTOOLS ( SAMTOOLS_SORT.out.bam.join(SAMTOOLS_INDEX.out.bai, by: [0]), ch_fasta )
    }
    /*
     * SUBWORKFLOW: Create stats using samtools
     */
    BAM_STATS_SAMTOOLS.out.stats
        .join ( BAM_STATS_SAMTOOLS.out.idxstats )
        .join ( BAM_STATS_SAMTOOLS.out.flagstat )
        .map  { it -> [ it[1], it[2], it[3] ] }
        .set  { sortbam_stats_multiqc }
    samtools_versions = BAM_STATS_SAMTOOLS.out.versions
    emit:
    sortbam
    sortbam_stats_multiqc
    samtools_versions
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
