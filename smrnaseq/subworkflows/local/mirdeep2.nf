//
// Quantify mirna with bowtie and mirtop
//
include { MIRDEEP2_PIGZ   } from '../../modules/local/mirdeep2_prepare'
include { MIRDEEP2_MAPPER } from '../../modules/local/mirdeep2_mapper'
include { MIRDEEP2_RUN    } from '../../modules/local/mirdeep2_run'
workflow MIRDEEP2 {
    take:
    reads        // channel: [ val(meta), [ reads ] ]
    fasta
    index
    hairpin
    mature
    main:
    ch_versions = Channel.empty()
    MIRDEEP2_PIGZ ( reads )
    ch_versions = ch_versions.mix(MIRDEEP2_PIGZ.out.versions.first())
    MIRDEEP2_MAPPER ( MIRDEEP2_PIGZ.out.reads, index )
    ch_versions = ch_versions.mix(MIRDEEP2_MAPPER.out.versions.first())
    MIRDEEP2_RUN ( fasta, MIRDEEP2_MAPPER.out.mirdeep2_inputs, hairpin, mature )
    ch_versions = ch_versions.mix(MIRDEEP2_RUN.out.versions.first())
    emit:
    versions = ch_versions // channel: [ versions.yml ]
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
