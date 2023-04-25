include { TABIX_BGZIPTABIX as TABIX_BGZIP_TIDDIT_SV } from '../../../modules/nf-core/tabix/bgziptabix/main'
include { TIDDIT_SV                                 } from '../../../modules/nf-core/tiddit/sv/main'
workflow BAM_VARIANT_CALLING_SINGLE_TIDDIT {
    take:
        cram_recalibrated
        fasta
        bwa
    main:
    ch_versions = Channel.empty()
    TIDDIT_SV(
        cram_recalibrated,
        fasta,
        bwa
    )
    TABIX_BGZIP_TIDDIT_SV(TIDDIT_SV.out.vcf)
    tiddit_ploidy = TIDDIT_SV.out.ploidy
    tiddit_vcf_gz = TABIX_BGZIP_TIDDIT_SV.out.gz_tbi.map{ meta, gz, tbi ->
        new_meta = meta.tumor_id ? [
                                        id:             meta.tumor_id + "_vs_" + meta.normal_id,
                                        normal_id:      meta.normal_id,
                                        num_intervals:  meta.num_intervals,
                                        patient:        meta.patient,
                                        sex:            meta.sex,
                                        tumor_id:       meta.tumor_id,
                                        variantcaller:  'tiddit'
                                    ]
                                    : [
                                        id:             meta.sample,
                                        num_intervals:  meta.num_intervals,
                                        patient:        meta.patient,
                                        sample:         meta.sample,
                                        sex:            meta.sex,
                                        status:         meta.status,
                                        variantcaller:  'tiddit'
                                    ]
        [new_meta, gz]}
    ch_versions = ch_versions.mix(TABIX_BGZIP_TIDDIT_SV.out.versions)
    ch_versions = ch_versions.mix(TIDDIT_SV.out.versions)
    emit:
    versions = ch_versions
    tiddit_vcf = tiddit_vcf_gz
    tiddit_ploidy
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
