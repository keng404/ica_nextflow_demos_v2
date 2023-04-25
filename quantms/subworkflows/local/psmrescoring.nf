//
// Extract psm feature and ReScoring psm
//
include { EXTRACTPSMFEATURES } from '../../modules/local/openms/extractpsmfeatures/main'
include { PERCOLATOR } from '../../modules/local/openms/thirdparty/percolator/main'
include { FALSEDISCOVERYRATE as FDRIDPEP } from '../../modules/local/openms/falsediscoveryrate/main'
include { IDPEP } from '../../modules/local/openms/idpep/main'
workflow PSMRESCORING {
    take:
    id_files
    main:
    ch_versions = Channel.empty()
    ch_results = Channel.empty()
    ch_fdridpep = Channel.empty()
    if (params.posterior_probabilities == 'percolator') {
        EXTRACTPSMFEATURES(id_files)
        ch_versions = ch_versions.mix(EXTRACTPSMFEATURES.out.version)
        PERCOLATOR(EXTRACTPSMFEATURES.out.id_files_feat)
        ch_versions = ch_versions.mix(PERCOLATOR.out.version)
        ch_results = PERCOLATOR.out.id_files_perc
    }
    if (params.posterior_probabilities != 'percolator') {
        if (params.search_engines.split(",").size() == 1) {
            FDRIDPEP(id_files)
            ch_versions = ch_versions.mix(FDRIDPEP.out.version)
            id_files = Channel.empty()
            ch_fdridpep = FDRIDPEP.out.id_files_idx_ForIDPEP_FDR
        }
        IDPEP(ch_fdridpep.mix(id_files))
        ch_versions = ch_versions.mix(IDPEP.out.version)
        ch_results = IDPEP.out.id_files_ForIDPEP
    }
    emit:
    results = ch_results
    versions = ch_versions
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
