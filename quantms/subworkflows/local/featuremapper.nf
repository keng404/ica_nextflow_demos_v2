//
// Assigns protein/peptide identifications to features or consensus features.
//
include { ISOBARICANALYZER } from '../../modules/local/openms/isobaricanalyzer/main'
include { IDMAPPER } from '../../modules/local/openms/idmapper/main'
workflow FEATUREMAPPER {
    take:
    mzml_files
    id_files
    main:
    ch_version = Channel.empty()
    ISOBARICANALYZER(mzml_files)
    ch_version = ch_version.mix(ISOBARICANALYZER.out.version)
    IDMAPPER(id_files.combine(ISOBARICANALYZER.out.id_files_consensusXML, by: 0))
    ch_version = ch_version.mix(IDMAPPER.out.version)
    emit:
    id_map  = IDMAPPER.out.id_map
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
