//
// Read QC, UMI extraction and trimming
//
include { FASTQC           } from '../../modules/nf-core/fastqc/main'
include { TRIMGALORE       } from '../../modules/local/trimgalore'
workflow FASTQC_TRIMGALORE {
    take:
    reads         // channel: [ val(meta), [ reads ] ]
    skip_fastqc   // boolean: true/false
    skip_trimming // boolean: true/false
    main:
    ch_versions = Channel.empty()
    fastqc_html = Channel.empty()
    fastqc_zip  = Channel.empty()
    if (!skip_fastqc) {
        FASTQC ( reads ).html.set { fastqc_html }
        fastqc_zip  = FASTQC.out.zip
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    }
    trim_reads = reads
    trim_html  = Channel.empty()
    trim_zip   = Channel.empty()
    trim_log   = Channel.empty()
    trimgalore_versions = Channel.empty()
    if (!skip_trimming) {
        TRIMGALORE ( reads ).reads.set { trim_reads }
        trim_html   = TRIMGALORE.out.html
        trim_zip    = TRIMGALORE.out.zip
        trim_log    = TRIMGALORE.out.log
        ch_versions = ch_versions.mix(TRIMGALORE.out.versions.first())
    }
    emit:
    reads = trim_reads     // channel: [ val(meta), [ reads ] ]
    fastqc_html            // channel: [ val(meta), [ html ] ]
    fastqc_zip             // channel: [ val(meta), [ zip ] ]
    trim_html              // channel: [ val(meta), [ html ] ]
    trim_zip               // channel: [ val(meta), [ zip ] ]
    trim_log               // channel: [ val(meta), [ txt ] ]
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
