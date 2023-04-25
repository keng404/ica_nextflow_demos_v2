/*
 * Taxonomic classification with QIIME2
 */
include { QIIME2_INSEQ                  } from '../../modules/local/qiime2_inseq'
include { QIIME2_CLASSIFY               } from '../../modules/local/qiime2_classify'
workflow QIIME2_TAXONOMY {
    take:
    ch_fasta
    ch_classifier
    main:
    QIIME2_INSEQ ( ch_fasta )
    QIIME2_CLASSIFY ( ch_classifier, QIIME2_INSEQ.out.qza )
    emit:
    qza     = QIIME2_CLASSIFY.out.qza
    tsv     = QIIME2_CLASSIFY.out.tsv
    versions= QIIME2_INSEQ.out.versions
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
