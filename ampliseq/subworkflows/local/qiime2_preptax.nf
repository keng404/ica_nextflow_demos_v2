/*
 * Training of a classifier with QIIME2
 */
include { FORMAT_TAXONOMY_QIIME } from '../../modules/local/format_taxonomy_qiime'
include { QIIME2_EXTRACT        } from '../../modules/local/qiime2_extract'
include { QIIME2_TRAIN          } from '../../modules/local/qiime2_train'
workflow QIIME2_PREPTAX {
    take:
    ch_qiime_ref_taxonomy //channel, list of files
    FW_primer //val
    RV_primer //val
    main:
    FORMAT_TAXONOMY_QIIME ( ch_qiime_ref_taxonomy )
    ch_ref_database = FORMAT_TAXONOMY_QIIME.out.fasta.combine(FORMAT_TAXONOMY_QIIME.out.tax)
    ch_ref_database
        .map {
            db ->
                def meta = [:]
                meta.FW_primer = FW_primer
                meta.RV_primer = RV_primer
                [ meta, db ] }
        .set { ch_ref_database }
    QIIME2_EXTRACT ( ch_ref_database )
    QIIME2_TRAIN ( QIIME2_EXTRACT.out.qza )
    emit:
    classifier      = QIIME2_TRAIN.out.qza
    versions        = QIIME2_TRAIN.out.versions
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
