include { STAR_ALIGN as STAR_FOR_STARFUSION }    from '../../modules/nf-core/modules/star/align/main'
include { STARFUSION }                           from '../../modules/local/starfusion/detect/main'
include { GET_META }                             from '../../modules/local/getmeta/main'
workflow STARFUSION_WORKFLOW {
    take:
        reads
        ch_chrgtf
        ch_starindex_ref
    main:
        ch_versions = Channel.empty()
        ch_align = Channel.empty()
        ch_dummy_file = file("$baseDir/assets/dummy_file_starfusion.txt", checkIfExists: true)
        if ((params.starfusion || params.all) && !params.fusioninspector_only) {
            if (params.starfusion_fusions){
                ch_starfusion_fusions = GET_META(reads, params.starfusion_fusions)
            } else {
                STAR_FOR_STARFUSION( reads, ch_starindex_ref, ch_chrgtf, params.star_ignore_sjdbgtf, '', params.seq_center ?: '')
                ch_versions = ch_versions.mix(STAR_FOR_STARFUSION.out.versions)
                ch_align = STAR_FOR_STARFUSION.out.bam_sorted
                reads_junction = reads.join(STAR_FOR_STARFUSION.out.junction )
                STARFUSION( reads_junction, params.starfusion_ref)
                ch_versions = ch_versions.mix(STARFUSION.out.versions)
                ch_starfusion_fusions = STARFUSION.out.fusions
                ch_star_stats = STAR_FOR_STARFUSION.out.log_final
            }
        }
        else {
            ch_starfusion_fusions = GET_META(reads, ch_dummy_file)
            ch_star_stats = Channel.empty()
        }
    emit:
        fusions         = ch_starfusion_fusions
        star_stats      = ch_star_stats
        bam_sorted      = ch_align
        versions        = ch_versions.ifEmpty(null)
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
