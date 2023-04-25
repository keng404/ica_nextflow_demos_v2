//
// Check input sdrf and get read channels
//
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
workflow INPUT_CHECK {
    take:
    input_file // file: /path/to/input_file
    main:
    if (input_file.toString().toLowerCase().contains("sdrf")) {
        is_sdrf = true
    } else {
        is_sdrf = false
        if (!params.labelling_type || !params.acquisition_method)
        {
            log.error "If no SDRF was given, specifying --labelling_type and --acquisition_method is mandatory."
            exit 1
        }
    }
    SAMPLESHEET_CHECK ( input_file, is_sdrf )
    emit:
    ch_input_file   = SAMPLESHEET_CHECK.out.checked_file
    is_sdrf         = is_sdrf
    versions	    = SAMPLESHEET_CHECK.out.versions
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
