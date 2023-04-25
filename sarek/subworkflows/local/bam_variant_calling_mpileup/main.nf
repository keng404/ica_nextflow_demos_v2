include { CAT_CAT as CAT_MPILEUP         } from '../../../modules/nf-core/cat/cat/main'
include { SAMTOOLS_MPILEUP               } from '../../../modules/nf-core/samtools/mpileup/main'
workflow BAM_VARIANT_CALLING_MPILEUP {
    take:
        cram                    // channel: [mandatory] [meta, cram, interval]
        fasta                   // channel: [mandatory]
    main:
    ch_versions = Channel.empty()
    SAMTOOLS_MPILEUP(cram, fasta)
    mpileup = SAMTOOLS_MPILEUP.out.mpileup.branch{
            intervals:    it[0].num_intervals > 1
            no_intervals: it[0].num_intervals <= 1
        }
    //Merge mpileup only when intervals and natural order sort them
    CAT_MPILEUP(mpileup.intervals
        .map{ meta, pileup ->
            new_meta = meta.tumor_id ? [
                                            id:             meta.tumor_id + "_vs_" + meta.normal_id,
                                            normal_id:      meta.normal_id,
                                            num_intervals:  meta.num_intervals,
                                            patient:        meta.patient,
                                            sex:            meta.sex,
                                            tumor_id:       meta.tumor_id,
                                        ] // not annotated, so no variantcaller necessary
                                        : [
                                            id:             meta.sample,
                                            num_intervals:  meta.num_intervals,
                                            patient:        meta.patient,
                                            sample:         meta.sample,
                                            status:         meta.status,
                                            sex:            meta.sex,
                                        ]
            [groupKey(new_meta, meta.num_intervals), pileup]
            }
        .groupTuple(sort:true))
    ch_versions = ch_versions.mix(SAMTOOLS_MPILEUP.out.versions)
    ch_versions = ch_versions.mix(CAT_MPILEUP.out.versions)
    emit:
    versions = ch_versions
    mpileup = Channel.empty().mix(CAT_MPILEUP.out.file_out, mpileup.no_intervals)
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
