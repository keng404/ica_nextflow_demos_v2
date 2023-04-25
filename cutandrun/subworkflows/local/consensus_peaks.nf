/*
 * Create group-level consensus peaks
 */
include { SORT                 } from '../../modules/local/linux/sort'
include { BEDTOOLS_MERGE       } from '../../modules/nf-core/bedtools/merge/main'
include { AWK                  } from '../../modules/local/linux/awk'
workflow CONSENSUS_PEAKS {
    take:
    bed //  channel: [ val(meta), [ bed ], count]
    main:
    ch_versions = Channel.empty()
    // Sort bed files
    SORT ( bed )
    ch_versions = ch_versions.mix(SORT.out.versions)
    // Merge peaks
    BEDTOOLS_MERGE ( SORT.out.file )
    ch_versions = ch_versions.mix(BEDTOOLS_MERGE.out.versions)
    // Filter peaks on minimum replicate consensus
    AWK ( BEDTOOLS_MERGE.out.bed )
    ch_versions = ch_versions.mix(AWK.out.versions)
    emit:
    merged_bed   = BEDTOOLS_MERGE.out.bed  // channel: [ val(meta), [ bed ] ]
    filtered_bed = AWK.out.file            // channel: [ val(meta), [ bed ] ]
    versions     = ch_versions             // channel: [ versions.yml       ]
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
