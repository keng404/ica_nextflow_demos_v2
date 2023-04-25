//
// Check input samplesheet and get read channels
//
include { FASTQC } from '../../modules/nf-core/fastqc/main'
workflow FASTQC_CHECK {
  take:
  ch_fastq
  main:
  ch_fastq
      .map { ch -> [ ch[0], ch[1] ] }
      .set { ch_fastq }
  /*
   * FastQ QC using FASTQC
   */
  FASTQC ( ch_fastq )
  fastqc_zip     = FASTQC.out.zip
  fastqc_html    = FASTQC.out.html
  fastqc_zip
      .map { it -> [ it[1] ] }
      .set { fastqc_zip_only }
  fastqc_html
      .map { it -> [ it[1] ] }
      .set { fastqc_html_only }
  fastqc_multiqc = Channel.empty()
  fastqc_multiqc = fastqc_multiqc.mix( fastqc_zip_only, fastqc_html_only )
  fastqc_version = FASTQC.out.versions
  emit:
  fastqc_zip
  fastqc_html
  fastqc_version
  fastqc_multiqc
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
