//
// ProteinQuant
//
include { IDCONFLICTRESOLVER } from '../../modules/local/openms/idconflictresolver/main'
include { PROTEINQUANTIFIER } from '../../modules/local/openms/proteinquantifier/main'
include { MSSTATSCONVERTER } from '../../modules/local/openms/msstatsconverter/main'
workflow PROTEINQUANT {
    take:
    conflict_file
    expdesign_file
    main:
    ch_version = Channel.empty()
    IDCONFLICTRESOLVER(conflict_file)
    ch_version = ch_version.mix(IDCONFLICTRESOLVER.out.version)
    PROTEINQUANTIFIER(IDCONFLICTRESOLVER.out.pro_resconf, expdesign_file)
    ch_version = ch_version.mix(PROTEINQUANTIFIER.out.version)
    MSSTATSCONVERTER(IDCONFLICTRESOLVER.out.pro_resconf, expdesign_file, "ISO")
    ch_version = ch_version.mix(MSSTATSCONVERTER.out.version)
    emit:
    msstats_csv = MSSTATSCONVERTER.out.out_msstats
    out_mztab   = PROTEINQUANTIFIER.out.out_mztab
    version     = ch_version
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
