//
// Count number of samples in sampleSheet and create channel
//
workflow SET_CHUNK_NUM_CHANNEL {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    chunk       // value: integer (number of chunk to create)
    main:
    int n_samples = -1
    file(samplesheet)
        .readLines()
        .each { n_samples++ }
    Channel // Prepare the pbccs chunk_num channel
        .from((1..chunk).step(1).toList()*n_samples)
        .set { chunk_num }
    emit:
    chunk_num
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
