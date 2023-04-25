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
        .splitCsv ( header:true, sep:',' )
        .multiMap {
            reads:       create_fastq_channel(it)
            reference:   create_reference_channel(it)
            template:    create_template_channel(it)
            protospacer: create_protospacer_channel(it)
        }
        .set { inputs }
    emit:
    reads = inputs.reads                      // channel: [ val(meta), [ reads ] ]
    reference = inputs.reference              // channel: [ val(meta), reference ]
    template = inputs.template                // channel: [ val(meta), template ]
    protospacer = inputs.protospacer          // channel: [ val(meta), protospacer ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
// Function to generate meta map
def create_meta(LinkedHashMap row) {
    // Create meta map with sample ID
    def meta = [:]
    meta.id = row.sample
    // Add single end boolean
    if (row.fastq_2 && file(row.fastq_2).exists()) {
        meta.single_end = false
    } else {
        meta.single_end = true
    }
    // Add self reference boolean
    if (row.reference.length() <= 0) {
        meta.self_reference = true
    } else {
        meta.self_reference = false
    }
    // Add template boolean
    if (!row.template) {
        meta.template = false
    } else if (!file(row.template).exists()) {
        meta.template = true
    } else {
        meta.template = true
    }
    return meta
}
// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = create_meta(row)
    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (!row.fastq_2 || !file(row.fastq_2).exists()) {
        fastq_meta = [ meta, [ file(row.fastq_1) ] ]
    } else {
        fastq_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return fastq_meta
}
// Function to get a list of [ meta, reference ]
def create_reference_channel(LinkedHashMap row) {
    // create meta map
    def meta = create_meta(row)
    // add reference sequence to meta
    def reference_meta = []
    if (row.reference.length() <= 0) {
        reference_meta = [ meta, null ]
    } else {
        reference_meta = [ meta, row.reference ]
    }
    return reference_meta
}
// Function to  get a list of [ meta, template ]
def create_template_channel(LinkedHashMap row) {
    // create meta map
    def meta = create_meta(row)
    // add template sequence/path to meta
    def template_meta = []
    if (!row.template) {
        template_meta = [ meta, null ]
    } else if (!file(row.template).exists()) {
        template_meta = [ meta, row.template ]
    } else {
        template_meta = [ meta, file(row.template) ]
    }
    return template_meta
}
// Function to get a list of [ meta, protospacer ]
def create_protospacer_channel(LinkedHashMap row) {
    // create meta map
    def meta = create_meta(row)
    // add protospacer sequence to meta
    def protospacer_meta = []
    if (row.protospacer.length() <= 0) {
        exit 1, "ERROR: Please check input samplesheet -> Protospacer sequence is not provided!\n"
    } else {
        protospacer_meta = [ meta, row.protospacer ]
    }
    return protospacer_meta
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
