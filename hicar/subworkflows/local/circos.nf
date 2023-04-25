/*
 * Call interaction peaks by MAPS
 */
include { CIRCOS_PREPARE            } from '../../modules/local/circos/circos_prepare'
include { CIRCOS                    } from '../../modules/local/circos/circos'
workflow RUN_CIRCOS {
    take:
    bedpe            // channel: [ path(bedpe) ]
    gtf              // channel: [ path(gtf) ]
    chromsize        // channel: [ path(chromsize) ]
    ucscname         // channel: [ val(ucscname) ]
    config           // channel: [ path(config) ]
    main:
    //create circos config
    //input=path(bedpe), val(ucscname), path(gtf), path(chromsize)
    ch_version = CIRCOS_PREPARE(bedpe.combine(ucscname).combine(gtf).combine(chromsize)).versions.first()
    //plot
    CIRCOS(CIRCOS_PREPARE.out.circos, config)
    ch_version = ch_version.mix(CIRCOS.out.versions)
    emit:
    circos       = CIRCOS.out.circos            // channel: [ path(png) ]
    versions     = ch_version                   // channel: [ path(version) ]
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
