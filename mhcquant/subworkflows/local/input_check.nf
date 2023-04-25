//
// Check input samplesheet and get read channels
//
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:'\t' )
        .map { create_ms_channel(it) }
        .set { reads }
    emit:
    reads                                     // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
// Function to get list of [ meta, filenames ]
def create_ms_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id        = row.ID
    meta.sample    = row.Sample
    meta.condition = row.Condition
    meta.ext       = row.Extension
    // add path(s) of the data file(s) to the meta map
    def ms_meta = []
    if (!file(row.ReplicateFileName).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> MS file does not exist!\n${row.ReplicateFileName}"
    } else {
        ms_meta = [ meta, [ file(row.ReplicateFileName) ] ]
    }
    return ms_meta
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
