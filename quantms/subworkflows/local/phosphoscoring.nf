//
// Phospho modification site localisation and scoring.
//
include { IDSCORESWITCHER as IDSCORESWITCHERFORLUCIPHOR } from '../../modules/local/openms/idscoreswitcher/main'
include { LUCIPHORADAPTER } from '../../modules/local/openms/thirdparty/luciphoradapter/main'
workflow PHOSPHOSCORING {
    take:
    mzml_files
    id_files
    main:
    ch_version = Channel.empty()
    IDSCORESWITCHERFORLUCIPHOR(id_files.combine(Channel.value("\"Posterior Error Probability_score\"")))
    ch_version = ch_version.mix(IDSCORESWITCHERFORLUCIPHOR.out.version)
    LUCIPHORADAPTER(mzml_files.join(IDSCORESWITCHERFORLUCIPHOR.out.id_score_switcher))
    ch_version = ch_version.mix(LUCIPHORADAPTER.out.version)
    emit:
    id_luciphor = LUCIPHORADAPTER.out.ptm_in_id_luciphor
    version = ch_version
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
