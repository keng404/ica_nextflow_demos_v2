include { KALLISTO_QUANT    }     from '../../modules/local/kallisto/quant/main'
include { PIZZLY            }     from '../../modules/local/pizzly/detect/main'
include { GET_META          }     from '../../modules/local/getmeta/main'
workflow PIZZLY_WORKFLOW {
    take:
        reads
        ch_gtf
        ch_transcript
    main:
        ch_versions = Channel.empty()
        ch_dummy_file = file("$baseDir/assets/dummy_file_pizzly.txt", checkIfExists: true)
        if ((params.pizzly || params.all) && !params.fusioninspector_only) {
            if (params.pizzly_fusions) {
                ch_pizzly_fusions = GET_META(reads, params.pizzly_fusions)
            } else {
                KALLISTO_QUANT(reads, params.pizzly_ref )
                ch_versions = ch_versions.mix(KALLISTO_QUANT.out.versions)
                PIZZLY( KALLISTO_QUANT.out.txt, ch_transcript, ch_gtf )
                ch_versions = ch_versions.mix(PIZZLY.out.versions)
                ch_pizzly_fusions = PIZZLY.out.fusions
            }
        }
        else  {
            ch_pizzly_fusions = GET_META(reads, ch_dummy_file)
        }
    emit:
        fusions             = ch_pizzly_fusions
        versions            = ch_versions.ifEmpty(null)
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
