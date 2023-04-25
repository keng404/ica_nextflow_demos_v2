/*
 * Basecalling QC with PycoQC and NanoPlot
 */
include { PYCOQC      } from '../../modules/nf-core/modules/pycoqc/main'
include { NANOPLOT    } from '../../modules/local/nanoplot'
workflow QCBASECALL_PYCOQC_NANOPLOT {
    take:
    ch_guppy_summary_txt // channel: [ val(meta), [ reads ] ]
    skip_pycoqc
    skip_nanoplot
    main:
    /*
     * QC using PycoQC
     */
    pycoqc_html    = Channel.empty()
    pycoqc_multiqc = Channel.empty()
    pycoqc_version = Channel.empty()
    ch_guppy_summary_txt
        .map { it -> [ it[1] ] }
        .set { ch_pycoqc_input }
    if (!skip_pycoqc){
        PYCOQC ( ch_pycoqc_input )
        pycoqc_html    = PYCOQC.out.html
        pycoqc_multiqc = PYCOQC.out.json
        pycoqc_version = PYCOQC.out.versions
    }
    /*
     * QC using NanoPlot
     */
    nanoplot_png    = Channel.empty()
    nanoplot_html   = Channel.empty()
    nanoplot_txt    = Channel.empty()
    nanoplot_log    = Channel.empty()
    if (!skip_nanoplot){
        NANOPLOT ( ch_guppy_summary_txt )
        //nanoplot_png      = NANOPLOT.out.png
        nanoplot_html     = NANOPLOT.out.html
        nanoplot_txt      = NANOPLOT.out.txt
        nanoplot_log      = NANOPLOT.out.log
        nanoplot_versions = NANOPLOT.out.versions
    }
    emit:
    pycoqc_html
    pycoqc_multiqc
    pycoqc_version
    nanoplot_png
    nanoplot_html
    nanoplot_txt
    nanoplot_log
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
