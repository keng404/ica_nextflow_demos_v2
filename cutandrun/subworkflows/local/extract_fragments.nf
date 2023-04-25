/*
 * Extract fragments from a BAM file into a bedfile format
*/
include { SAMTOOLS_SORT      } from "../../modules/nf-core/samtools/sort/main.nf"
include { BEDTOOLS_BAMTOBED  } from "../../modules/nf-core/bedtools/bamtobed/main.nf"
include { AWK                } from '../../modules/local/linux/awk'
include { CUT                } from '../../modules/local/linux/cut'
workflow EXTRACT_FRAGMENTS {
    take:
    bam // channel: [ val(meta), [ bam ] ]
    main:
    ch_versions = Channel.empty()
    /*
    * MODULE: Sort reads by name for bamtobed
    */
    SAMTOOLS_SORT (
        bam
    )
    /*
    * MODULE: Convert BAM file to paired-end bed format
    */
    BEDTOOLS_BAMTOBED(
        SAMTOOLS_SORT.out.bam
    )
    ch_versions = ch_versions.mix(BEDTOOLS_BAMTOBED.out.versions)
    // BEDTOOLS_BAMTOBED.out.bed | view
    /*
    * MODULE: Keep the read pairs that are on the same chromosome and fragment length less than 1000bp.
    */
    AWK (
        BEDTOOLS_BAMTOBED.out.bed  
    )
    ch_versions = ch_versions.mix(AWK.out.versions)
    /*
    * MODULE: Only extract the fragment related columns
    */
    CUT (
        AWK.out.file
    )
    emit:
    bed      = CUT.out.file // channel: [ val(meta), [ bed ] ]
    versions = ch_versions  // channel: [ versions.yml ]
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
