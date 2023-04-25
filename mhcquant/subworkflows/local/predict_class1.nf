/*
 * Perform the class 1 prediction when the parameter --predict_class_1 is provided and --skip_quantification is not
 */
include { MHCFLURRY_PREDICTPEPTIDESCLASS1 }                                     from '../../modules/local/mhcflurry_predictpeptidesclass1'
include { PREDICT_POSSIBLE_NEOEPITOPES as PREDICT_POSSIBLE_CLASS1_NEOEPITOPES } from '../../modules/local/predict_possible_neoepitopes'
include { RESOLVE_FOUND_NEOEPITOPES as RESOLVE_FOUND_CLASS1_NEOEPITOPES }       from '../../modules/local/resolve_found_neoepitopes'
include { MHCFLURRY_PREDICTNEOEPITOPESCLASS1 }                                  from '../../modules/local/mhcflurry_predictneoepitopesclass1'
workflow PREDICT_CLASS1 {
    take:
        mztab
        peptides_class_1_alleles
        ch_vcf_from_sheet
    main:
        ch_versions = Channel.empty()
        ch_predicted_possible_neoepitopes = Channel.empty()
        // If specified predict peptides using MHCFlurry
        MHCFLURRY_PREDICTPEPTIDESCLASS1(
            mztab
                .map{ it -> [it[0].sample, it[0], it[1]] }
                .combine( peptides_class_1_alleles, by:0)
                .map( it -> [it[1], it[2], it[3]])
            )
        ch_versions = ch_versions.mix(MHCFLURRY_PREDICTPEPTIDESCLASS1.out.versions.first().ifEmpty(null))
        if ( params.include_proteins_from_vcf ) {
            // Predict all possible neoepitopes from vcf
            PREDICT_POSSIBLE_CLASS1_NEOEPITOPES(peptides_class_1_alleles.combine(ch_vcf_from_sheet, by:0))
            ch_versions = ch_versions.mix(PREDICT_POSSIBLE_CLASS1_NEOEPITOPES.out.versions.first().ifEmpty(null))
            ch_predicted_possible_neoepitopes = PREDICT_POSSIBLE_CLASS1_NEOEPITOPES.out.csv
            // Resolve found neoepitopes
            RESOLVE_FOUND_CLASS1_NEOEPITOPES(
                mztab
                    .map{ it -> [it[0].sample, it[0], it[1]] }
                    .combine( ch_predicted_possible_neoepitopes, by:0)
                    .map( it -> [it[1], it[2], it[3]])
                )
            ch_versions = ch_versions.mix(RESOLVE_FOUND_CLASS1_NEOEPITOPES.out.versions.first().ifEmpty(null))
            // Predict class 1 neoepitopes MHCFlurry
            MHCFLURRY_PREDICTNEOEPITOPESCLASS1(peptides_class_1_alleles.join(RESOLVE_FOUND_CLASS1_NEOEPITOPES.out.csv, by:0))
            ch_versions = ch_versions.mix(MHCFLURRY_PREDICTNEOEPITOPESCLASS1.out.versions.first().ifEmpty(null))
        }
    emit:
        // Define the information that is returned by this workflow
        versions = ch_versions
        ch_predicted_possible_neoepitopes = ch_predicted_possible_neoepitopes
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
