//
// PREPARE_REFERENCE_CNVKIT
//
// Initialize channels based on params or indices that were just built
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run
include { CNVKIT_ANTITARGET } from '../../../modules/nf-core/cnvkit/antitarget/main'
include { CNVKIT_REFERENCE  } from '../../../modules/nf-core/cnvkit/reference/main'
workflow PREPARE_REFERENCE_CNVKIT {
    take:
        fasta                    // channel: [mandatory] fasta
        intervals_bed_combined   // channel: []
    main:
    ch_versions = Channel.empty()
    // prepare a antitarget reference files for tumor_only mode of cnvkit
    CNVKIT_ANTITARGET(intervals_bed_combined.flatten().map{ it -> [[id:it[0].baseName], it] })
    CNVKIT_REFERENCE(fasta, intervals_bed_combined, CNVKIT_ANTITARGET.out.bed.map{ meta, bed -> [bed]} )
    ch_versions = ch_versions.mix(CNVKIT_ANTITARGET.out.versions)
    ch_versions = ch_versions.mix(CNVKIT_REFERENCE.out.versions)
    emit:
    versions            = ch_versions
    cnvkit_reference    = CNVKIT_REFERENCE.out.cnn.collect()
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
