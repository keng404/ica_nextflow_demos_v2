/*
 * Identify transcripts with homer
 */
include { HOMER_MAKETAGDIRECTORY } from '../../../../modules/nf-core/homer/maketagdirectory/main'
include { HOMER_MAKEUCSCFILE     } from '../../../../modules/nf-core/homer/makeucscfile/main'
include { HOMER_FINDPEAKS        } from '../../../../modules/nf-core/homer/findpeaks/main'
include { HOMER_POS2BED          } from '../../../../modules/nf-core/homer/pos2bed/main'
workflow HOMER_GROSEQ {
    take:
    bam   // channel: [ val(meta), [ reads ] ]
    fasta //    file: /path/to/bwa/index/
    main:
    ch_versions = Channel.empty()
    /*
    * Create a Tag Directory From The GRO-Seq experiment
    */
    HOMER_MAKETAGDIRECTORY ( bam, fasta )
    ch_versions = ch_versions.mix(HOMER_MAKETAGDIRECTORY.out.versions.first())
    /*
    * Creating UCSC Visualization Files
    */
    HOMER_MAKEUCSCFILE ( HOMER_MAKETAGDIRECTORY.out.tagdir )
    ch_versions = ch_versions.mix(HOMER_MAKEUCSCFILE.out.versions.first())
    /*
    * Find transcripts directly from GRO-Seq
    */
    HOMER_FINDPEAKS ( HOMER_MAKETAGDIRECTORY.out.tagdir )
    ch_versions = ch_versions.mix(HOMER_FINDPEAKS.out.versions.first())
    /*
    * Convert peak file to bed file
    */
    HOMER_POS2BED ( HOMER_FINDPEAKS.out.txt )
    ch_versions = ch_versions.mix(HOMER_POS2BED.out.versions.first())
    emit:
    tagdir             = HOMER_MAKETAGDIRECTORY.out.tagdir // channel: [ val(meta), [ tagdir ] ]
    bed_graph          = HOMER_MAKEUCSCFILE.out.bedGraph   // channel: [ val(meta), [ tag_dir/*ucsc.bedGraph.gz ] ]
    peaks              = HOMER_FINDPEAKS.out.txt           // channel: [ val(meta), [ *peaks.txt ] ]
    bed                = HOMER_POS2BED.out.bed             // channel: [ val(meta), [ *peaks.txt ] ]
    versions = ch_versions                                 // channel: [ versions.yml ]
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
