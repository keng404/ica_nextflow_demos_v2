//
// Run snpEff to annotate VCF files
//
include { SNPEFF } from '../../modules/nf-core/modules/snpeff/main'
include { TABIX_BGZIPTABIX } from '../../modules/nf-core/modules/tabix/bgziptabix/main'
workflow SNPEFF_ANNOTATE {
    take:
    vcf            // channel: [ val(meta), vcf, tbi ]
    snpeff_db      // value: version of db to use
    snpeff_cache   // path: path_to_snpeff_cache (optionnal)
    main:
    ch_versions = Channel.empty()
    SNPEFF (
        vcf,
        snpeff_db,
        snpeff_cache
    )
    ch_versions = ch_versions.mix(SNPEFF.out.versions.first())
    TABIX_BGZIPTABIX (
        SNPEFF.out.vcf
    )
    ch_versions = ch_versions.mix(TABIX_BGZIPTABIX.out.versions.first())
    emit:
    vcf_tbi     = TABIX_BGZIPTABIX.out.gz_tbi    // channel: [ val(meta), vcf, tbi ]
    reports     = SNPEFF.out.report              // path: *.html
    versions    = ch_versions                    // channel: [versions.yml]
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
