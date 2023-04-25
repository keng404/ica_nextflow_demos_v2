//
// Alignment with Bowtie2
//
include { BOWTIE2_ALIGN     } from '../../modules/nf-core/modules/bowtie2/align/main'
include { BAM_SORT_SAMTOOLS } from './bam_sort_samtools'
workflow ALIGN_BOWTIE2 {
    take:
    reads          // channel: [ val(meta), [ reads ] ]
    index          // channel: /path/to/bowtie2/index/
    save_unaligned //   value: boolean
    sort_bam       //   value: boolean
    main:
    ch_versions = Channel.empty()
    //
    // Map reads with Bowtie2
    //
    BOWTIE2_ALIGN (
        reads,
        index,
        save_unaligned,
        sort_bam
    )
    ch_versions = ch_versions.mix(BOWTIE2_ALIGN.out.versions.first())
    //
    // Sort, index BAM file and run samtools stats, flagstat and idxstats
    //
    BAM_SORT_SAMTOOLS (
        BOWTIE2_ALIGN.out.bam
    )
    ch_versions = ch_versions.mix(BAM_SORT_SAMTOOLS.out.versions)
    emit:
    bam_orig = BOWTIE2_ALIGN.out.bam          // channel: [ val(meta), bam   ]
    log_out  = BOWTIE2_ALIGN.out.log          // channel: [ val(meta), log   ]
    fastq    = BOWTIE2_ALIGN.out.fastq        // channel: [ val(meta), fastq ]
    bam      = BAM_SORT_SAMTOOLS.out.bam      // channel: [ val(meta), [ bam ] ]
    bai      = BAM_SORT_SAMTOOLS.out.bai      // channel: [ val(meta), [ bai ] ]
    csi      = BAM_SORT_SAMTOOLS.out.csi      // channel: [ val(meta), [ csi ] ]
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
