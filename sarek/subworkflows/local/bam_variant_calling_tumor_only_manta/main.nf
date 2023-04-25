include { GATK4_MERGEVCFS as MERGE_MANTA_SMALL_INDELS      } from '../../../modules/nf-core/gatk4/mergevcfs/main'
include { GATK4_MERGEVCFS as MERGE_MANTA_SV                } from '../../../modules/nf-core/gatk4/mergevcfs/main'
include { GATK4_MERGEVCFS as MERGE_MANTA_TUMOR             } from '../../../modules/nf-core/gatk4/mergevcfs/main'
include { MANTA_TUMORONLY                                  } from '../../../modules/nf-core/manta/tumoronly/main'
// Seems to be the consensus on upstream modules implementation too
workflow BAM_VARIANT_CALLING_TUMOR_ONLY_MANTA {
    take:
    cram                     // channel: [mandatory] [meta, cram, crai, interval.bed.gz, interval.bed.gz.tbi]
    dict                     // channel: [optional]
    fasta                    // channel: [mandatory]
    fasta_fai                // channel: [mandatory]
    main:
    ch_versions = Channel.empty()
    MANTA_TUMORONLY(cram, fasta, fasta_fai)
    // Figure out if using intervals or no_intervals
    MANTA_TUMORONLY.out.candidate_small_indels_vcf.branch{
            intervals:    it[0].num_intervals > 1
            no_intervals: it[0].num_intervals <= 1
        }.set{manta_small_indels_vcf}
    MANTA_TUMORONLY.out.candidate_sv_vcf.branch{
            intervals:    it[0].num_intervals > 1
            no_intervals: it[0].num_intervals <= 1
        }.set{manta_candidate_sv_vcf}
    MANTA_TUMORONLY.out.tumor_sv_vcf.branch{
            intervals:    it[0].num_intervals > 1
            no_intervals: it[0].num_intervals <= 1
        }.set{manta_tumor_sv_vcf}
    //Only when using intervals
    MERGE_MANTA_SMALL_INDELS(
        manta_small_indels_vcf.intervals.map{ meta, vcf ->
                [groupKey([
                            id:             meta.sample,
                            num_intervals:  meta.num_intervals,
                            patient:        meta.patient,
                            sample:         meta.sample,
                            sex:            meta.sex,
                            status:         meta.status,
                        ],
                        meta.num_intervals),
                vcf]
            }.groupTuple(),
        dict)
    MERGE_MANTA_SV(
        manta_candidate_sv_vcf.intervals.map{ meta, vcf ->
                [groupKey([
                            id:             meta.sample,
                            num_intervals:  meta.num_intervals,
                            patient:        meta.patient,
                            sample:         meta.sample,
                            sex:            meta.sex,
                            status:         meta.status
                        ],
                        meta.num_intervals),
                vcf]
            }.groupTuple(),
        dict)
    MERGE_MANTA_TUMOR(
        manta_tumor_sv_vcf.intervals.map{ meta, vcf ->
                [groupKey( [
                            id:             meta.sample,
                            num_intervals:  meta.num_intervals,
                            patient:        meta.patient,
                            sample:         meta.sample,
                            sex:            meta.sex,
                            status:         meta.status,
                        ],
                        meta.num_intervals),
                vcf]
            }.groupTuple(),
        dict)
    // Mix output channels for "no intervals" and "with intervals" results
    // Only tumor sv should get annotated
    manta_vcf = Channel.empty().mix(
        MERGE_MANTA_TUMOR.out.vcf,
        manta_tumor_sv_vcf.no_intervals
    ).map{ meta, vcf ->
        [[
            id:             meta.sample,
            num_intervals:  meta.num_intervals,
            patient:        meta.patient,
            sample:         meta.sample,
            sex:            meta.sex,
            status:         meta.status,
            variantcaller:  "manta"
        ],
        vcf]
    }
    ch_versions = ch_versions.mix(MERGE_MANTA_SV.out.versions)
    ch_versions = ch_versions.mix(MERGE_MANTA_SMALL_INDELS.out.versions)
    ch_versions = ch_versions.mix(MERGE_MANTA_TUMOR.out.versions)
    ch_versions = ch_versions.mix(MANTA_TUMORONLY.out.versions)
    emit:
    manta_vcf
    versions = ch_versions
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
