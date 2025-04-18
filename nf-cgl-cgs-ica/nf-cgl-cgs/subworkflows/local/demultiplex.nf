/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { CREATE_DEMULTIPLEX_SAMPLESHEET   } from '../../modules/local/create_demultiplex_samplesheet'
include { DRAGEN_DEMULTIPLEX               } from '../../modules/local/dragen_demultiplex'
include { INPUT_CHECK as VERIFY_FASTQ_LIST } from '../../subworkflows/local/input_check'
/*
========================================================================================
    SUBWORKFLOW TO DEMULTIPLEX DATA
========================================================================================
*/
workflow DEMULTIPLEX {
    take:
    ch_samplesheet      // channel: [ path(file) ]
    ch_illumina_run_dir // channel: [ path(dir) ]
    main:
    ch_versions = Channel.empty()
    //
    // MODULE: Create demultiplex samplesheet
    //
    CREATE_DEMULTIPLEX_SAMPLESHEET (
        ch_samplesheet,
        ch_illumina_run_dir
    )
    ch_versions = ch_versions.mix(CREATE_DEMULTIPLEX_SAMPLESHEET.out.versions)
    //
    // MODULE: Demultiplex samples
    //
    DRAGEN_DEMULTIPLEX (
        CREATE_DEMULTIPLEX_SAMPLESHEET.out.samplesheet,
        ch_illumina_run_dir
    )
    ch_versions = ch_versions.mix(DRAGEN_DEMULTIPLEX.out.versions)
    //
    // SUBWORKFLOW: Verify fastq_list.csv
    //
    VERIFY_FASTQ_LIST (
        [],
        DRAGEN_DEMULTIPLEX.out.fastq_list
    )
    ch_versions = ch_versions.mix(VERIFY_FASTQ_LIST.out.versions)
    // Use 'params.demux_outdir' path for paths in 'fastq_list.csv' and save
    if (params.demux_outdir) {
        def batch_name = params.batch_name ?: new java.util.Date().format('yyyyMMdd') + '_CGS'
        DRAGEN_DEMULTIPLEX.out.fastq_list
            .splitCsv( header: true )
            .map{
                row ->
                    def read1 = row['Read1File'].split('/')[-2..-1].join('/')
                    def read2 = row['Read2File'].split('/')[-2..-1].join('/')
                    // Get absolute path of 'params.demux_outdir'
                    def demux_outdir = file(params.demux_outdir).toAbsolutePath().toString()
                    row['Read1File'] = "${demux_outdir}/${read1}"
                    row['Read2File'] = "${demux_outdir}/${read2}"
                    return "${row.keySet().join(',')}\n${row.values().join(',')}\n"
            }
            .collectFile(
                name      : "fastq_list.csv",
                keepHeader: true,
                storeDir  : "${params.demux_outdir}/${batch_name}/Reports/"
            )
    }
    emit:
    samples  = VERIFY_FASTQ_LIST.out.samples  // channel: [ val(meta), path(file) ]
    versions = ch_versions                    // channel: [ path(file) ]
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
