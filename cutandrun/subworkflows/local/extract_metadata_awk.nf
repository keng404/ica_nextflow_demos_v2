/*
 * Generate table-based metadata from a summary report using AWK 
 */
include { AWK_SCRIPT } from '../../modules/local/linux/awk_script'
include { AWK }        from '../../modules/local/linux/awk'
workflow EXTRACT_METADATA_AWK {
    take:
    report
    script
    script_mode // bool
    main:
    ch_versions = Channel.empty()
    ch_metadata = Channel.empty()
    // Can run awk in script mode with a file from assets or with a setup of command line args
    if(script_mode) {
        AWK_SCRIPT ( report, script )
        ch_metadata = AWK_SCRIPT.out.file
        ch_versions = ch_versions.mix(AWK_SCRIPT.out.versions)
    }
    else {
        AWK ( report )
        ch_metadata = AWK.out.file
        ch_versions = ch_versions.mix(AWK.out.versions)
    }
    emit:
    metadata   = ch_metadata // channel: [ val(meta), [ metdatafile ] ]
    versions   = ch_versions // channel: [ versions.yml ]
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
