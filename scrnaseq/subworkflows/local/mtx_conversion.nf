/* --    IMPORT LOCAL MODULES/SUBWORKFLOWS     -- */
include { MTX_TO_H5AD   }             from '../../modules/local/mtx_to_h5ad.nf'
include { CONCAT_H5AD   }             from '../../modules/local/concat_h5ad.nf'
include { MTX_TO_SEURAT }             from '../../modules/local/mtx_to_seurat.nf'
workflow MTX_CONVERSION {
    take:
    mtx_matrices
    samplesheet
    main:
        ch_versions = Channel.empty()
        // Convert matrix do h5ad
        //
        MTX_TO_H5AD (
            mtx_matrices
        )
        //
        // Concat sample-specific h5ad in one
        //
        CONCAT_H5AD (
            MTX_TO_H5AD.out.h5ad.collect(), // gather all sample-specific files
            samplesheet
        )
        //
        // Convert matrix do seurat
        //
        MTX_TO_SEURAT (
            mtx_matrices
        )
        //TODO CONCAT h5ad and MTX to h5ad should also have versions.yaml output
        ch_version = ch_versions.mix(MTX_TO_SEURAT.out.versions)
    emit:
    ch_versions
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
