include { REFORMAT }                    from '../../modules/local/reformat/main'
include { FASTQC as FASTQC_FOR_TRIM }   from '../../modules/nf-core/modules/fastqc/main'
workflow TRIM_WORKFLOW {
    take:
        reads
    main:
        ch_versions = Channel.empty()
        if (params.trim) {
            REFORMAT( reads )
            ch_versions = ch_versions.mix(REFORMAT.out.versions)
            ch_reads_out = REFORMAT.out.reads_out
            FASTQC_FOR_TRIM (ch_reads_out)
        }
        else {
            ch_reads_out = reads
        }
    emit:
        reads         = ch_reads_out
        versions      = ch_versions.ifEmpty(null)
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
