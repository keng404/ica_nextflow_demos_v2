/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)
// Validate input parameters
WorkflowColabfold.initialise(params, log)
// Check input path parameters to see if they exist
def checkPathParamList = [
    params.input,
    params.colabfold_db
]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input file not specified!' }
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK           } from '../subworkflows/local/input_check'
include { PREPARE_COLABFOLD_DBS } from '../subworkflows/local/prepare_colabfold_dbs'
//
// MODULE: Local to the pipeline
//
include { COLABFOLD_BATCH        } from '../modules/local/colabfold_batch'
include { MMSEQS_COLABFOLDSEARCH } from '../modules/local/mmseqs_colabfoldsearch'
include { MULTIFASTA_TO_CSV      } from '../modules/local/multifasta_to_csv'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Info required for completion email and summary
def multiqc_report = []
workflow COLABFOLD {
    ch_versions = Channel.empty()
    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    PREPARE_COLABFOLD_DBS ( )
    ch_versions = ch_versions.mix(PREPARE_COLABFOLD_DBS.out.versions)
    if (params.colabfold_server == 'webserver') {
        //
        // MODULE: Run colabfold
        //
        if (params.colabfold_model_preset != 'AlphaFold2-ptm') {
            MULTIFASTA_TO_CSV(
                INPUT_CHECK.out.fastas
            )
            ch_versions = ch_versions.mix(MULTIFASTA_TO_CSV.out.versions)
            COLABFOLD_BATCH(
                MULTIFASTA_TO_CSV.out.input_csv,
                params.colabfold_model_preset,
                PREPARE_COLABFOLD_DBS.out.params,
                [],
                [],
                params.num_recycle
            )
            ch_versions = ch_versions.mix(COLABFOLD_BATCH.out.versions)
        } else {
            COLABFOLD_BATCH(
                INPUT_CHECK.out.fastas,
                params.colabfold_model_preset,
                PREPARE_COLABFOLD_DBS.out.params,
                [],
                [],
                params.num_recycle
            )
            ch_versions = ch_versions.mix(COLABFOLD_BATCH.out.versions)
        }
    } else if (params.colabfold_server == 'local') {
        //
    // MODULE: Run mmseqs
        //
        if (params.colabfold_model_preset != 'AlphaFold2-ptm') {
            MULTIFASTA_TO_CSV(
                INPUT_CHECK.out.fastas
            )
            ch_versions = ch_versions.mix(MULTIFASTA_TO_CSV.out.versions)
            MMSEQS_COLABFOLDSEARCH (
                MULTIFASTA_TO_CSV.out.input_csv,
                PREPARE_COLABFOLD_DBS.out.params,
                PREPARE_COLABFOLD_DBS.out.colabfold_db,
                PREPARE_COLABFOLD_DBS.out.uniref30,
            )
            ch_versions = ch_versions.mix(MMSEQS_COLABFOLDSEARCH.out.versions)
        } else {
            MMSEQS_COLABFOLDSEARCH (
                INPUT_CHECK.out.fastas,
                PREPARE_COLABFOLD_DBS.out.params,
                PREPARE_COLABFOLD_DBS.out.colabfold_db,
                PREPARE_COLABFOLD_DBS.out.uniref30,
            )
            ch_versions = ch_versions.mix(MMSEQS_COLABFOLDSEARCH.out.versions)
        }
        //
        // MODULE: Run colabfold
        //
        COLABFOLD_BATCH(
            MMSEQS_COLABFOLDSEARCH.out.a3m,
            params.colabfold_model_preset,
            PREPARE_COLABFOLD_DBS.out.params,
            PREPARE_COLABFOLD_DBS.out.colabfold_db,
            PREPARE_COLABFOLD_DBS.out.uniref30,
            params.num_recycle
        )
        ch_versions = ch_versions.mix(COLABFOLD_BATCH.out.versions)
    }
     //
    // MODULE: Pipeline reporting
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowColabfold.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)
    methods_description    = WorkflowColabfold.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(COLABFOLD_BATCH.out.multiqc.collect())
    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// workflow.onComplete {
//     if (params.email || params.email_on_fail) {
//         NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
//     }
//     NfcoreTemplate.summary(workflow, params, log)
//     if (params.hook_url) {
//         NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
//     }
// }
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
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
