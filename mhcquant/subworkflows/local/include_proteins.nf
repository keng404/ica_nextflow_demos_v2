/*
 * Perform the necessary steps to make the data uniform for further processing
 */
include { GENERATE_PROTEINS_FROM_VCF }                                      from '../../modules/local/generate_proteins_from_vcf'
workflow INCLUDE_PROTEINS {
    take:
        input_fasta
    main:
        ch_versions = Channel.empty()
        // Variant
        vcf_sheet = file(params.vcf_sheet, checkIfExists: true)
        Channel.from( vcf_sheet )
            .splitCsv(header: ['Sample', 'VCF_FileName'], sep:'\t', skip: 1)
            .map { col -> tuple("${col.Sample}", file("${col.VCF_FileName}"),) }
            .set { ch_vcf_from_sheet }
        // Combine the vcf information with the meta information
        ch_vcf = input_fasta
            .map{ it -> [it[0].sample, it[0], it[1]] }
            .combine( ch_vcf_from_sheet, by: 0 )
            .map(it -> [it[1], it[2], it[3]])
        // If specified translate variants to proteins and include in reference fasta
        GENERATE_PROTEINS_FROM_VCF( ch_vcf )
        ch_versions = ch_versions.mix(GENERATE_PROTEINS_FROM_VCF.out.versions.first().ifEmpty(null))
    emit:
        // Define the information that is returned by this workflow
        versions = ch_versions
        ch_vcf_from_sheet = ch_vcf_from_sheet
        ch_fasta_file = GENERATE_PROTEINS_FROM_VCF.out.vcf_fasta
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
