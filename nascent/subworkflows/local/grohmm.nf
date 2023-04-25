/*
 * Run parametertuning optionally, otherwise just run transcript calling
 */
include { GROHMM_TRANSCRIPTCALLING } from '../../modules/local/grohmm/transcriptcalling/main.nf'
include { GROHMM_PARAMETERTUNING } from '../../modules/local/grohmm/parametertuning/main.nf'
/*
 * Note meta refers to all merged files
 */
workflow GROHMM {
    take:
    bams
    gtf
    tuning_file
    main:
    ch_versions = Channel.empty()
    ch_tuning = []
    if(!params.skip_tuning) {
        GROHMM_PARAMETERTUNING (
            bams,
            gtf,
            tuning_file
        )
        ch_tuning = GROHMM_PARAMETERTUNING.out.tuning
        ch_versions = ch_versions.mix(GROHMM_PARAMETERTUNING.out.versions.first())
    }
    GROHMM_TRANSCRIPTCALLING (
        bams,
        gtf,
        ch_tuning
    )
    ch_versions = ch_versions.mix(GROHMM_TRANSCRIPTCALLING.out.versions.first())
    emit:
    transcripts = GROHMM_TRANSCRIPTCALLING.out.transcripts
    bed = GROHMM_TRANSCRIPTCALLING.out.transcripts_bed
    td_plot = GROHMM_TRANSCRIPTCALLING.out.td_plot
    versions = ch_versions
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
