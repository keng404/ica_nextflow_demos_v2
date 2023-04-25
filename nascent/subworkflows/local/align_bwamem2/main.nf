//
// Alignment with BWAMEM2
//
include { BWAMEM2_MEM       } from '../../../modules/nf-core/bwamem2/mem/main'
include { BAM_SORT_STATS_SAMTOOLS } from '../../nf-core/bam_sort_stats_samtools/main'
workflow ALIGN_BWAMEM2 {
    take:
    reads // channel: [ val(meta), [ reads ] ]
    index //    file: /path/to/bwa/index/
    main:
    ch_versions = Channel.empty()
    //
    // Map reads with BWAMEM2
    //
    BWAMEM2_MEM ( reads, index, false )
    ch_versions = ch_versions.mix(BWAMEM2_MEM.out.versions.first())
    //
    // Sort, index BAM file and run samtools stats, flagstat and idxstats
    //
    BAM_SORT_STATS_SAMTOOLS ( BWAMEM2_MEM.out.bam, [] )
    ch_versions = ch_versions.mix(BAM_SORT_STATS_SAMTOOLS.out.versions)
    emit:
    orig_bam         = BWAMEM2_MEM.out.bam            // channel: [ val(meta), bam ]
    bam              = BAM_SORT_STATS_SAMTOOLS.out.bam      // channel: [ val(meta), [ bam ] ]
    bai              = BAM_SORT_STATS_SAMTOOLS.out.bai      // channel: [ val(meta), [ bai ] ]
    stats            = BAM_SORT_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), [ stats ] ]
    flagstat         = BAM_SORT_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    idxstats         = BAM_SORT_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), [ idxstats ] ]
    versions       = ch_versions                      // channel: [ versions.yml ]
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
