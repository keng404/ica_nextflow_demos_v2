/*
 * Convert BAM to BigWig
 */
include { BEDTOOLS_GENOMECOV    } from '../../modules/local/bedtools_genomecov'
include { UCSC_BEDGRAPHTOBIGWIG } from '../../modules/local/ucsc_bedgraphtobigwig'
workflow BEDTOOLS_UCSC_BIGWIG {
    take:
    ch_sortbam // channel: [ val(meta), [ reads ] ]
    main:
    /*
     * Convert BAM to BEDGraph
     */
    BEDTOOLS_GENOMECOV ( ch_sortbam )
    ch_bedgraph      = BEDTOOLS_GENOMECOV.out.bedgraph
    bedtools_version = BEDTOOLS_GENOMECOV.out.versions
    /*
     * Convert BEDGraph to BigWig
     */
    UCSC_BEDGRAPHTOBIGWIG ( ch_bedgraph )
    ch_bigwig = UCSC_BEDGRAPHTOBIGWIG.out.bigwig
    bedgraphtobigwig_version = UCSC_BEDGRAPHTOBIGWIG.out.versions
    emit:
    ch_bigwig
    bedtools_version
    bedgraphtobigwig_version
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
