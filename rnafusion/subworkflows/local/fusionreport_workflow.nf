include { FUSIONREPORT      }     from '../../modules/local/fusionreport/detect/main'
include { GET_META          }     from '../../modules/local/getmeta/main'
workflow FUSIONREPORT_WORKFLOW {
    take:
        reads
        fusionreport_ref
        arriba_fusions
        pizzly_fusions
        squid_fusions
        starfusion_fusions
        fusioncatcher_fusions
    main:
        ch_versions = Channel.empty()
        if (!params.fusioninspector_only) {
            reads_fusions = reads
            .join(arriba_fusions, remainder: true)
            .join(pizzly_fusions, remainder: true)
            .join(squid_fusions, remainder: true)
            .join(starfusion_fusions, remainder: true)
            .join(fusioncatcher_fusions, remainder: true)
            FUSIONREPORT(reads_fusions, fusionreport_ref)
            ch_fusion_list = FUSIONREPORT.out.fusion_list
            ch_fusion_list_filtered = FUSIONREPORT.out.fusion_list_filtered
            ch_versions = ch_versions.mix(FUSIONREPORT.out.versions)
        } else {
            ch_fusion_list = GET_META(reads, params.fusioninspector_fusions)
            ch_fusion_list_filtered  = ch_fusion_list
        }
    emit:
        versions                 = ch_versions.ifEmpty(null)
        fusion_list              = ch_fusion_list
        fusion_list_filtered     = ch_fusion_list_filtered
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
