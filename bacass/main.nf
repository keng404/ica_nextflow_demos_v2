#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/bacass
========================================================================================
    Github : https://github.com/nf-core/bacass
    Website: https://nf-co.re/bacass
    Slack  : https://nfcore.slack.com/channels/bacass
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
include { BACASS } from './workflows/bacass'
//
// WORKFLOW: Run main nf-core/bacass analysis pipeline
//
workflow NFCORE_BACASS {
    BACASS ()
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
    NFCORE_BACASS ()
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
