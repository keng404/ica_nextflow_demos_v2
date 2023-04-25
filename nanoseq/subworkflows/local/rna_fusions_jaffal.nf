/*
 * RNA FUSION DETECTION WITH JAFFAL
 */
include { GET_JAFFAL_REF } from '../../modules/local/get_jaffal_ref'
include { UNTAR          } from '../../modules/nf-core/modules/untar/main'
include { JAFFAL         } from '../../modules/local/jaffal'
workflow RNA_FUSIONS_JAFFAL {
    take:
    ch_sample
    jaffal_ref_dir
    main:
    if (jaffal_ref_dir) {
        ch_jaffal_ref_dir = file(params.jaffal_ref_dir, checkIfExists: true)
    } else {
        /*
         * Get jaffel reference
         */
        GET_JAFFAL_REF()
        /*
         * Untar jaffel reference
         */
        UNTAR( GET_JAFFAL_REF.out.ch_jaffal_ref )
        ch_jaffal_ref_dir = UNTAR.out.untar
    }
    ch_sample
        .map { it -> [ it[0], it[6] ]}
        .set { ch_jaffal_input }
    /*
    * Align current signals to reference with jaffel
    */
    JAFFAL( ch_jaffal_input, ch_jaffal_ref_dir )
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
