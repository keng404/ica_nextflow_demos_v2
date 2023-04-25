//
// CHANNEL_ALIGN_CREATE_CSV
//
workflow CHANNEL_ALIGN_CREATE_CSV {
    take:
        bam_indexed         // channel: [mandatory] meta, bam, bai
    main:
        // Creating csv files to restart from this step
        bam_indexed.collectFile(keepHeader: true, skip: 1, sort: true, storeDir: "${params.outdir}/csv") { meta, bam, bai ->
            patient = meta.patient
            sample  = meta.sample
            sex     = meta.sex
            status  = meta.status
            bam   = "${params.outdir}/preprocessing/mapped/${sample}/${bam.name}"
            bai   = "${params.outdir}/preprocessing/mapped/${sample}/${bai.name}"
            type = params.save_output_as_bam ? "bam" : "cram"
            type_index = params.save_output_as_bam ? "bai" : "crai"
            ["mapped.csv", "patient,sex,status,sample,${type},${type_index}\n${patient},${sex},${status},${sample},${bam},${bai}\n"]
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
