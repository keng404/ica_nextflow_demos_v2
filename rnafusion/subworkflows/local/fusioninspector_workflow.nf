include { FUSIONINSPECTOR     }                           from '../../modules/local/fusioninspector/main'
include { FUSIONINSPECTOR_DEV }                           from '../../modules/local/fusioninspector_dev/main'
workflow FUSIONINSPECTOR_WORKFLOW {
    take:
        reads
        fusion_list
        fusion_list_filtered
    main:
        ch_versions = Channel.empty()
        index ="${params.starfusion_ref}"
        ch_fusion_list = params.fusioninspector_filter ? fusion_list_filtered : fusion_list
        reads_fusion = reads.join(ch_fusion_list )
        if (params.fusioninspector_limitSjdbInsertNsj != 1000000) {
            FUSIONINSPECTOR_DEV( reads_fusion, index)
            ch_versions = ch_versions.mix(FUSIONINSPECTOR_DEV.out.versions)
        }
        else {
            FUSIONINSPECTOR( reads_fusion, index)
            ch_versions = ch_versions.mix(FUSIONINSPECTOR.out.versions)
        }
    emit:
        versions        = ch_versions.ifEmpty(null)
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
