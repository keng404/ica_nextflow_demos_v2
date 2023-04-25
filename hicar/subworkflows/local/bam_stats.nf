/*
 * Createing Stats for mapping results
 */
include { SAMTOOLS_SORT                } from '../../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_INDEX               } from '../../modules/nf-core/modules/samtools/index/main'
include { SAMTOOLS_STATS               } from '../../modules/nf-core/modules/samtools/stats/main'
include { SAMTOOLS_IDXSTATS            } from '../../modules/nf-core/modules/samtools/idxstats/main'
include { SAMTOOLS_FLAGSTAT            } from '../../modules/nf-core/modules/samtools/flagstat/main'
workflow BAM_STAT {
    take:
    bam          // channel: [ val(meta), path(bam) ]
    main:
    ch_version = SAMTOOLS_SORT(bam).versions
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
    ch_bam_bai = SAMTOOLS_SORT.out.bam.join(SAMTOOLS_INDEX.out.bai, by: [0])
    SAMTOOLS_STATS(ch_bam_bai, [])
    SAMTOOLS_FLAGSTAT(ch_bam_bai)
    SAMTOOLS_IDXSTATS(ch_bam_bai)
    emit:
    stats    = SAMTOOLS_STATS.out.stats           // channel: [ val(meta), [ stats ] ]
    flagstat = SAMTOOLS_FLAGSTAT.out.flagstat     // channel: [ val(meta), [ flagstat ] ]
    idxstats = SAMTOOLS_IDXSTATS.out.idxstats     // channel: [ val(meta), [ idxstats ] ]
    versions = ch_version                         // channel: [ path(version) ]
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
