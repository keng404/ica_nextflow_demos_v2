//
// iVar trim, sort, index BAM file and run samtools stats, flagstat and idxstats
//
include { IVAR_TRIM         } from '../../modules/nf-core/modules/ivar/trim/main'
include { BAM_SORT_SAMTOOLS } from './bam_sort_samtools'
workflow PRIMER_TRIM_IVAR {
    take:
    bam // channel: [ val(meta), [ bam ], [bai] ]
    bed // path   : bed
    main:
    ch_versions = Channel.empty()
    //
    // iVar trim primers
    //
    IVAR_TRIM (
        bam,
        bed
    )
    ch_versions = ch_versions.mix(IVAR_TRIM.out.versions.first())
    //
    // Sort, index BAM file and run samtools stats, flagstat and idxstats
    //
    BAM_SORT_SAMTOOLS (
        IVAR_TRIM.out.bam
    )
    ch_versions = ch_versions.mix(BAM_SORT_SAMTOOLS.out.versions)
    emit:
    bam_orig = IVAR_TRIM.out.bam              // channel: [ val(meta), bam   ]
    log_out  = IVAR_TRIM.out.log              // channel: [ val(meta), log   ]
    bam      = BAM_SORT_SAMTOOLS.out.bam      // channel: [ val(meta), [ bam ] ]
    bai      = BAM_SORT_SAMTOOLS.out.bai      // channel: [ val(meta), [ bai ] ]
    stats    = BAM_SORT_SAMTOOLS.out.stats    // channel: [ val(meta), [ stats ] ]
    flagstat = BAM_SORT_SAMTOOLS.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    idxstats = BAM_SORT_SAMTOOLS.out.idxstats // channel: [ val(meta), [ idxstats ] ]
    versions = ch_versions                    // channel: [ versions.yml ]
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
