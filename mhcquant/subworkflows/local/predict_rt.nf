/*
 * Perform the Retention time prediction when the parameter --predict_RT is provided
 */
include { OPENMS_RTMODEL }                                                  from '../../modules/local/openms_rtmodel'
include {
    OPENMS_RTPREDICT as OPENMS_RTPREDICT_FOUND_PEPTIDES
    OPENMS_RTPREDICT as OPENMS_RTPREDICT_NEOEPITOPES}                       from '../../modules/local/openms_rtpredict'
workflow PREDICT_RT {
    take:
        filter_q_value
        ch_predicted_possible_neoepitopes
        ch_predicted_possible_neoepitopes_II
    main:
        ch_versions = Channel.empty()
        // Train Retention Times Predictor
        OPENMS_RTMODEL(filter_q_value)
        ch_versions = ch_versions.mix(OPENMS_RTMODEL.out.versions.first().ifEmpty(null))
        // Retention Times Predictor Found Peptides
        OPENMS_RTPREDICT_FOUND_PEPTIDES(filter_q_value.join(OPENMS_RTMODEL.out.complete, by:[0]))
        ch_versions = ch_versions.mix(OPENMS_RTPREDICT_FOUND_PEPTIDES.out.versions.first().ifEmpty(null))
        // Retention Times Predictor possible Neoepitopes
        OPENMS_RTPREDICT_NEOEPITOPES(ch_predicted_possible_neoepitopes.mix(ch_predicted_possible_neoepitopes_II).join(OPENMS_RTMODEL.out.complete, by:[0]))
        ch_versions = ch_versions.mix(OPENMS_RTPREDICT_FOUND_PEPTIDES.out.versions.first().ifEmpty(null))
    emit:
        // Define the information that is returned by this workflow
        versions = ch_versions
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
