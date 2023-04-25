//
// CHANNEL_APPLYBQSR_CREATE_CSV
//
workflow CHANNEL_APPLYBQSR_CREATE_CSV {
    take:
        cram_recalibrated_index // channel: [mandatory] meta, cram, crai
    main:
        // Creating csv files to restart from this step
        cram_recalibrated_index.collectFile(keepHeader: true, skip: 1, sort: true, storeDir: "${params.outdir}/csv") { meta, file, index ->
            patient = meta.patient
            sample  = meta.sample
            sex     = meta.sex
            status  = meta.status
            file = "${params.outdir}/preprocessing/recalibrated/${sample}/${file.name}"
            index = "${params.outdir}/preprocessing/recalibrated/${sample}/${index.name}"
            type = params.save_output_as_bam ? "bam" : "cram"
            type_index = params.save_output_as_bam ? "bai" : "crai"
            ["recalibrated.csv", "patient,sex,status,sample,${type},${type_index}\n${patient},${sex},${status},${sample},${file},${index}\n"]
        }
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
