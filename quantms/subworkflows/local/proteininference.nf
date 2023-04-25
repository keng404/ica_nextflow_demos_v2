//
// ProteinInference
//
include { EPIFANY } from '../../modules/local/openms/epifany/main'
include { PROTEININFERENCE as PROTEININFERENCER} from '../../modules/local/openms/proteininference/main'
include { IDFILTER } from '../../modules/local/openms/idfilter/main'
workflow PROTEININFERENCE {
    take:
    consus_file
    main:
    ch_version = Channel.empty()
    if (params.protein_inference_method == "bayesian") {
        EPIFANY(consus_file)
        ch_version = ch_version.mix(EPIFANY.out.version)
        ch_inference = EPIFANY.out.epi_inference
    } else {
        PROTEININFERENCER(consus_file)
        ch_version = ch_version.mix(PROTEININFERENCER.out.version)
        ch_inference = PROTEININFERENCER.out.protein_inference
    }
    IDFILTER(ch_inference)
    ch_version = ch_version.mix(IDFILTER.out.version)
    IDFILTER.out.id_filtered
        .multiMap{ it ->
            meta: it[0]
            results: it[1]
            }
        .set{ epi_results }
    emit:
    epi_idfilter    = epi_results.results
    version         = ch_version
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
