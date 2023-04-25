/*
 * Check input samplesheet and get read channels
 */
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.tsv
    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .tsv
        .splitCsv ( header:true, sep:'\t' )
        .map { create_fastq_channels(it) }
        .set { reads }
    emit:
    reads                                     // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
// Function to map
def create_fastq_channels(LinkedHashMap col) {
    def meta = [:]
    meta.id           = col.sample_id
    meta.subject      = col.subject_id
    meta.locus        = col.pcr_target_locus
    meta.species      = col.species
    def array = []
    if (!file(col.filename_R1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${col.filename_R1}"
    }
    if (!file(col.filename_R2).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${col.filename_R2}"
    }
    if (col.filename_I1) {
        if (!file(col.filename_I1).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Index read FastQ file does not exist!\n${col.filename_I1}"
        }
        array = [ meta, [ file(col.filename_R1), file(col.filename_R2), file(col.filename_I1) ] ]
    } else {
        array = [ meta, [ file(col.filename_R1), file(col.filename_R2) ] ]
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
