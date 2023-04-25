//
// Run VEP to annotate VCF files
//
include { ENSEMBLVEP } from '../../modules/nf-core/modules/ensemblvep/main'
include { TABIX_BGZIPTABIX } from '../../modules/nf-core/modules/tabix/bgziptabix/main'
workflow ENSEMBLVEP_ANNOTATE {
    take:
    vcf               // channel: [ val(meta), vcf, tbi ]
    vep_genome        //   value: which genome
    vep_species       //   value: which species
    vep_cache_version //   value: which cache version
    vep_cache         //    path: path_to_vep_cache (optionnal)
    main:
    ch_versions = Channel.empty()
    ENSEMBLVEP (
        vcf,
        vep_genome,
        vep_species,
        vep_cache_version,
        vep_cache
    )
    ch_versions = ch_versions.mix(ENSEMBLVEP.out.versions.first())
    TABIX_BGZIPTABIX (
        ENSEMBLVEP.out.vcf
    )
    ch_versions = ch_versions.mix(TABIX_BGZIPTABIX.out.versions.first())
    emit:
    vcf_tbi     = TABIX_BGZIPTABIX.out.gz_tbi    // channel: [ val(meta), vcf, tbi ]
    reports     = ENSEMBLVEP.out.report          // path: *.html
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
