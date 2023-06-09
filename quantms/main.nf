#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/quantms
========================================================================================
    Github : https://github.com/nf-core/quantms
    Website: https://nf-co.re/quantms
    Slack  : https://nfcore.slack.com/channels/quantms
----------------------------------------------------------------------------------------
*/
nextflow.enable.dsl = 2
/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/
WorkflowMain.initialise(workflow, params, log)
/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/
include { QUANTMS } from './workflows/quantms'
//
// WORKFLOW: Run main nf-core/quantms analysis pipeline
//
workflow NFCORE_QUANTMS {
    QUANTMS ()
}
/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/
//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_QUANTMS ()
}
/*
========================================================================================
    THE END
========================================================================================
*/
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
