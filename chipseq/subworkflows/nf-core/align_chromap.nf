/*
 * Map reads, sort, index BAM file and run samtools stats, flagstat and idxstats
 */
include { CHROMAP_CHROMAP   } from '../../modules/nf-core/modules/chromap/chromap/main'
include { BAM_SORT_SAMTOOLS } from './bam_sort_samtools'
workflow ALIGN_CHROMAP {
    take:
    reads // channel: [ val(meta), [ reads ] ]
    index //    path: /path/to/index
    fasta //    path: /path/to/fasta
    main:
    ch_versions = Channel.empty()
    //
    // Map reads with CHROMAP
    //
    CHROMAP_CHROMAP(reads, fasta, index, [], [], [], [])
    ch_versions = ch_versions.mix(CHROMAP_CHROMAP.out.versions.first())
    //
    // Sort, index BAM file and run samtools stats, flagstat and idxstats
    //
    BAM_SORT_SAMTOOLS(CHROMAP_CHROMAP.out.bam)
    ch_versions = ch_versions.mix(BAM_SORT_SAMTOOLS.out.versions.first())
    emit:
    bam               = BAM_SORT_SAMTOOLS.out.bam               // channel: [ val(meta), [ bam ] ]
    bai               = BAM_SORT_SAMTOOLS.out.bai               // channel: [ val(meta), [ bai ] ]
    stats             = BAM_SORT_SAMTOOLS.out.stats             // channel: [ val(meta), [ stats ] ]
    flagstat          = BAM_SORT_SAMTOOLS.out.flagstat          // channel: [ val(meta), [ flagstat ] ]
    idxstats          = BAM_SORT_SAMTOOLS.out.idxstats          // channel: [ val(meta), [ idxstats ] ]
    versions          = ch_versions                             //    path: versions.yml
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
