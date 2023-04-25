//
// Run BCFTools tabix and stats commands
//
include { TABIX_TABIX    } from '../../modules/nf-core/modules/tabix/tabix/main'
include { BCFTOOLS_STATS } from '../../modules/nf-core/modules/bcftools/stats/main'
workflow VCF_TABIX_STATS {
    take:
    vcf // channel: [ val(meta), [ vcf ] ]
    main:
    ch_versions = Channel.empty()
    TABIX_TABIX (
        vcf
    )
    ch_versions = ch_versions.mix(TABIX_TABIX.out.versions.first())
    BCFTOOLS_STATS (
        vcf
    )
    ch_versions = ch_versions.mix(BCFTOOLS_STATS.out.versions.first())
    emit:
    tbi      = TABIX_TABIX.out.tbi      // channel: [ val(meta), [ tbi ] ]
    stats    = BCFTOOLS_STATS.out.stats // channel: [ val(meta), [ txt ] ]
    versions = ch_versions              // channel: [ versions.yml ]
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
