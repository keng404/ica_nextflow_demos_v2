/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { CONVERT_XLSX_TO_CSV } from '../../modules/local/convert_xlsx_to_csv'
/*
========================================================================================
    SUBWORKFLOW TO CHECK INPUTS
========================================================================================
*/
workflow INPUT_CHECK {
    take:
    mgi_samplesheet //  string: Path to input MGI samplesheet
    ch_fastq_list   //  string: Path to input fastq_list.csv
    main:
    ch_versions = Channel.empty()
    /*
    ================================================================================
                        Process input MGI samplesheet
    ================================================================================
    */
    if (mgi_samplesheet) {
        // Verify MGI samplesheet has a file extension in [xlsx,csv,tsv]
        if (hasExtension(mgi_samplesheet, 'xlsx')) {
            CONVERT_XLSX_TO_CSV (
                Channel.fromPath(mgi_samplesheet, checkIfExists: true)
            )
            ch_versions = ch_versions.mix(CONVERT_XLSX_TO_CSV.out.versions)
            ch_mgi_samplesheet = CONVERT_XLSX_TO_CSV.out.csv
        } else if (hasExtension(mgi_samplesheet, 'csv') || hasExtension(mgi_samplesheet, 'tsv')) {
            ch_mgi_samplesheet = Channel.fromPath(mgi_samplesheet, checkIfExists: true)
        } else {
            error("MGI samplesheet input does not end in `.{xlsx,csv,tsv}`!")
        }
    } else {
        ch_mgi_samplesheet = Channel.empty()
    }
    /*
    ================================================================================
                        Process input FastQ list
    ================================================================================
    */
    if (ch_fastq_list) {
        // Set separator for input FastQ list
        if (ch_fastq_list.map{ hasExtension(it, 'csv') }) {
            fastq_list_separator=','
        } else if (ch_fastq_list.map{ hasExtension(it, 'tsv') }) {
            fastq_list_separator='\t'
        } else {
            error("Input for `--fastq_list` does not end in `.{csv,tsv}`!")
        }
        // Parse FastQ list and verify columns
        ch_samples = ch_fastq_list
                        .splitCsv( header: true, sep: fastq_list_separator )
                        .map{
                            row ->
                                if (row.size() >= 6) {
                                    def RGID = row.RGID ?: error("Missing 'RGID' column!")
                                    def RGSM = row.RGSM ?: error("Missing 'RGSM' column!")
                                    def RGLB = row.RGLB ?: error("Missing 'RGLB' column!")
                                    def LANE = row.Lane ?: error("Missing 'Lane' column!")
                                    def R1   = row.Read1File ? file(row.Read1File, checkIfExists: true) : error("Missing or invalid 'Read1File' file!")
                                    def R2   = row.Read2File ? file(row.Read2File, checkIfExists: true) : error("Missing or invalid 'Read2File' file!")
                                    def regexPattern = /\w\d{2}-\d+/
                                    def meta = [:]
                                    meta['id'] = row.RGSM
                                    meta['acc'] = row.RGSM.findAll(regexPattern)[0] ?: row.RGSM
                                    [ meta ]
                                } else {
                                    error("Input for `--fastq_list` requires at least 6 columns but received ${row.size()}.")
                                }
                        }
                        .unique()
                        .combine(ch_fastq_list)
    } else {
        ch_samples = Channel.empty()
    }
    emit:
    samples         = ch_samples         // channel: [ val(sample_info), path(fastq_list) ]
    mgi_samplesheet = ch_mgi_samplesheet // channel: [ path(file) ]
    versions        = ch_versions        // channel: [ path(file) ]
}
/*
========================================================================================
    FUNCTIONS
========================================================================================
*/
// Get file extension
def hasExtension(it, extension) {
    it.toString().toLowerCase().endsWith(extension.toLowerCase())
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
