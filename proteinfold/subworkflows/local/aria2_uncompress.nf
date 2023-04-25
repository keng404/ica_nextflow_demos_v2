//
// Download with aria2 and uncompress the data if needed
//
include { UNTAR  } from '../../modules/nf-core/untar/main'
include { GUNZIP } from '../../modules/nf-core/gunzip/main'
include { ARIA2  } from '../../modules/nf-core/aria2/main'
workflow ARIA2_UNCOMPRESS {
    take:
    source_url // url
    main:
    ARIA2 (
        source_url
    )
    ch_db = Channel.empty()
    if (source_url.toString().endsWith('.tar') || source_url.toString().endsWith('.tar.gz')) {
        ch_db = UNTAR ( ARIA2.out.downloaded_file.flatten().map{ [ [:], it ] } ).untar.map{ it[1] }
    } else if (source_url.toString().endsWith('.gz')) {
        ch_db = GUNZIP ( ARIA2.out.downloaded_file.flatten().map{ [ [:], it ] } ).gunzip.map { it[1] }
    }
    emit:
    db       = ch_db              // channel: [ db ]
    versions = ARIA2.out.versions // channel: [ versions.yml ]
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
