include { CUSTOM_SRATOOLSNCBISETTINGS } from '../../../modules/nf-core/custom/sratoolsncbisettings/main'
include { SRATOOLS_PREFETCH           } from '../../../modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP        } from '../../../modules/nf-core/sratools/fasterqdump/main'
//
// Download FASTQ sequencing reads from the NCBI's Sequence Read Archive (SRA).
//
workflow FASTQ_DOWNLOAD_PREFETCH_FASTERQDUMP_SRATOOLS {
    take:
    ch_sra_ids  // channel: [ val(meta), val(id) ]
    main:
    ch_versions = Channel.empty()
    //
    // Detect existing NCBI user settings or create new ones.
    //
    CUSTOM_SRATOOLSNCBISETTINGS()
    def settings = CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings  // value channel: path(settings)
    ch_versions = ch_versions.mix(CUSTOM_SRATOOLSNCBISETTINGS.out.versions)
    //
    // Prefetch sequencing reads in SRA format.
    //
    SRATOOLS_PREFETCH ( ch_sra_ids, settings )
    ch_versions = ch_versions.mix(SRATOOLS_PREFETCH.out.versions.first())
    //
    // Convert the SRA format into one or more compressed FASTQ files.
    //
    SRATOOLS_FASTERQDUMP ( SRATOOLS_PREFETCH.out.sra, settings )
    ch_versions = ch_versions.mix(SRATOOLS_FASTERQDUMP.out.versions.first())
    emit:
    reads    = SRATOOLS_FASTERQDUMP.out.reads  // channel: [ val(meta), [ reads ] ]
    versions = ch_versions                     // channel: [ versions.yml ]
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