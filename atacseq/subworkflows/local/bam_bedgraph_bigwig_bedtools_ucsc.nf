//
// Convert BAM to normalised bigWig via bedGraph using BEDTools and UCSC
//
include { BEDTOOLS_GENOMECOV    } from '../../modules/local/bedtools_genomecov'
include { UCSC_BEDGRAPHTOBIGWIG } from '../../modules/nf-core/ucsc/bedgraphtobigwig/main'
workflow BAM_BEDGRAPH_BIGWIG_BEDTOOLS_UCSC {
    take:
    ch_bam_flagstat // channel: [ val(meta), [bam], [flagstat] ]
    ch_chrom_sizes  // channel: [ bed ]
    
    main:
    ch_versions = Channel.empty()
    //
    // Create bedGraph coverage track
    //
    BEDTOOLS_GENOMECOV (
        ch_bam_flagstat
    )
    ch_versions = ch_versions.mix(BEDTOOLS_GENOMECOV.out.versions.first())
    //
    // Create bigWig coverage tracks
    //
    UCSC_BEDGRAPHTOBIGWIG (
        BEDTOOLS_GENOMECOV.out.bedgraph,
        ch_chrom_sizes
    )
    ch_versions = ch_versions.mix(UCSC_BEDGRAPHTOBIGWIG.out.versions.first())
    emit:
    bedgraph     = BEDTOOLS_GENOMECOV.out.bedgraph      // channel: [ val(meta), [ bedgraph ] ]
    scale_factor = BEDTOOLS_GENOMECOV.out.scale_factor  // channel: [ val(meta), [ txt ] ]
    bigwig       = UCSC_BEDGRAPHTOBIGWIG.out.bigwig     // channel: [ val(meta), [ bigwig ] ]
    versions     = ch_versions                          // channel: [ versions.yml ]
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
