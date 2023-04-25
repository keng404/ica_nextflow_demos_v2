//
// Quantify mirna with bowtie and mirtop
//
include { MIRTRACE_RUN } from '../../modules/local/mirtrace'
workflow MIRTRACE {
    take:
    reads      // channel: [ val(meta), [ reads ] ]
    main:
    reads
    | MIRTRACE_RUN
    emit:
    results    = MIRTRACE_RUN.out.mirtrace
    versions   = MIRTRACE_RUN.out.versions
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
