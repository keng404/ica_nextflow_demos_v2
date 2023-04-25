/*
 * Get tables and group together the ones from the same subject
 */
include { MERGE_TABLES } from '../../modules/local/merge_tables'
workflow MERGE_TABLES_WF {
    take:
    ch_tables
    ch_samplesheet
    main:
    ch_tables
        .dump()
        .map{it -> [ it[0].subject+'_'+it[0].locus, it[0].id, it[0].locus, it[0].subject, it[0].species, it[1] ]}
        .groupTuple()
        .dump()
        .map{ get_meta_tabs(it) }
        .dump()
        .set{ch_merge_tables}
    MERGE_TABLES(
        ch_merge_tables,
        ch_samplesheet.collect()
    )
    emit:
    tab = MERGE_TABLES.out.tab // channel: [ val(meta), tab ]
}
// Function to map
def get_meta_tabs(arr) {
    def meta = [:]
    meta.id           = arr[0]
    meta.samples      = arr[1]
    meta.locus        = arr[2].unique().join("")
    meta.subject      = arr[3].unique().join("")
    meta.species      = arr[4].unique().join("")
    def array = []
        array = [ meta, arr[5].flatten() ]
    return array
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
