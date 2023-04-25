//
// CHANNEL_VARIANT_CALLING_CREATE_CSV
//
workflow CHANNEL_VARIANT_CALLING_CREATE_CSV {
    take:
        vcf_to_annotate // channel: [mandatory] meta, vcf
    main:
        // Creating csv files to restart from this step
        vcf_to_annotate.collectFile(keepHeader: true, skip: 1,sort: true, storeDir: "${params.outdir}/csv"){ meta, vcf ->
            patient       = meta.patient
            sample        = meta.id
            variantcaller = meta.variantcaller
            vcf = "${params.outdir}/variant_calling/${variantcaller}/${meta.id}/${vcf.getName()}"
            ["variantcalled.csv", "patient,sample,variantcaller,vcf\n${patient},${sample},${variantcaller},${vcf}\n"]
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
