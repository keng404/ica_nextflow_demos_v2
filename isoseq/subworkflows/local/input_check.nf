//
// Check input samplesheet and get read channels
//
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    chunk       // value: integer (number of chunk to create)
    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .flatMap { create_pbccs_channels(it, chunk) }
        .set { reads }
    emit:
    reads                                     // channel: [ val(meta), [ bam, pbi ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
// Function to get to create pbcss channel [ meta, [ bam, pbi ] ]
def create_pbccs_channels(LinkedHashMap row, chunk) {
    def meta = [:]
    meta.id         = row.sample
    meta.single_end = row.single_end.toBoolean()
    if (!file(row.bam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> BAM file does not exist!\n${row.bam}"
    }
    if (!file(row.pbi).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> PBI file does not exist!\n${row.pbi}"
    }
    def array = []
    for ( i = 1 ; i <= chunk ; i++ ) {
        array << [ meta, file(row.bam), file(row.pbi) ]
    }
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
