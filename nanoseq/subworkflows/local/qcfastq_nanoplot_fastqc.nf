/*
 * FastQ QC with NanoPlot and fastqc
 */
include { NANOPLOT     } from '../../modules/local/nanoplot'
include { FASTQC       } from '../../modules/nf-core/modules/fastqc/main'
workflow QCFASTQ_NANOPLOT_FASTQC {
    take:
    ch_fastq
    skip_nanoplot
    skip_fastqc
    main:
    ch_fastq
        .map { ch -> [ ch[0], ch[1] ] }
        .set { ch_fastq }
    /*
     * FastQ QC using NanoPlot
     */
    nanoplot_png     = Channel.empty()
    nanoplot_html    = Channel.empty()
    nanoplot_txt     = Channel.empty()
    nanoplot_log     = Channel.empty()
    nanoplot_version = Channel.empty()
    if (!skip_nanoplot){
        NANOPLOT ( ch_fastq )
        //nanoplot_png     = NANOPLOT.out.png
        nanoplot_html    = NANOPLOT.out.html
        nanoplot_txt     = NANOPLOT.out.txt
        nanoplot_log     = NANOPLOT.out.log
        nanoplot_version = NANOPLOT.out.versions
    }
    /*
     * FastQ QC using FASTQC
     */
    fastqc_zip     = Channel.empty()
    fastqc_html    = Channel.empty()
    fastqc_multiqc = Channel.empty()
    fastqc_version = Channel.empty()
    if (!skip_fastqc){
        FASTQC ( ch_fastq )
        fastqc_zip     = FASTQC.out.zip
        fastqc_html    = FASTQC.out.html
        fastqc_zip
            .map { it -> [ it[1] ] }
            .set { fastqc_zip_only }
        fastqc_html
            .map { it -> [ it[1] ] }
            .set { fastqc_html_only }
        fastqc_multiqc = fastqc_multiqc.mix( fastqc_zip_only, fastqc_html_only )
//       fastqc_version = FASTQC.out.versions
    }
    emit:
    nanoplot_png
    nanoplot_html
    nanoplot_txt
    nanoplot_log
    nanoplot_version
    fastqc_zip
    fastqc_html
    fastqc_version
    fastqc_multiqc
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
