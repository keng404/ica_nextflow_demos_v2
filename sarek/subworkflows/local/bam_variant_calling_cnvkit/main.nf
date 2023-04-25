//
// CNVKit calling
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run
include { CNVKIT_BATCH } from '../../../modules/nf-core/cnvkit/batch/main'
workflow BAM_VARIANT_CALLING_CNVKIT {
    take:
        cram_recalibrated   // channel: [mandatory] cram
        fasta               // channel: [mandatory] fasta
        fasta_fai           // channel: [optional]  fasta_fai
        targets             // channel: [mandatory] bed
        reference           // channel: [] cnn
    main:
        ch_versions = Channel.empty()
        CNVKIT_BATCH(cram_recalibrated, fasta, fasta_fai, targets, reference)
        ch_versions = ch_versions.mix(CNVKIT_BATCH.out.versions)
    emit:
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
