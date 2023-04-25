//
// Check input samplesheet and get read channels
//
include { GUNZIP } from '../../modules/nf-core/modules/gunzip/main'
workflow SET_VALUE_CHANNEL {
    take:
    infile // file: path to compressed or not fasta/gtf
    main:
    if (infile =~ /.gz$/) {
        GUNZIP([[], file(infile)])
            .gunzip
            .map { it[1] }
            .set { data }
    }
    else {
        Channel // Prepare value channel
            .value(file(infile))
            .set { data }
    }
    emit:
    data // channel: [ file(infile) ]
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
