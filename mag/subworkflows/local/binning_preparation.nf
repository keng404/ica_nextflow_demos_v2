/*
 * Binning preparation with Bowtie2
 */
params.bowtie2_build_options      = [:]
params.bowtie2_align_options      = [:]
include { BOWTIE2_ASSEMBLY_BUILD    } from '../../modules/local/bowtie2_assembly_build'   addParams( options: params.bowtie2_build_options      )
include { BOWTIE2_ASSEMBLY_ALIGN    } from '../../modules/local/bowtie2_assembly_align'   addParams( options: params.bowtie2_align_options      )
workflow BINNING_PREPARATION {
    take:
    assemblies           // channel: [ val(meta), path(assembly) ]
    reads                // channel: [ val(meta), [ reads ] ]
    main:
    // build bowtie2 index for all assemblies
    BOWTIE2_ASSEMBLY_BUILD ( assemblies )
    // combine assemblies with sample reads for binning depending on specified mapping mode
    if (params.binning_map_mode == 'all'){
        // combine assemblies with reads of all samples
        ch_bowtie2_input = BOWTIE2_ASSEMBLY_BUILD.out.assembly_index
            .combine(reads)
    } else if (params.binning_map_mode == 'group'){
        // combine assemblies with reads of samples from same group
        ch_reads_bowtie2 = reads.map{ meta, reads -> [ meta.group, meta, reads ] }
        ch_bowtie2_input = BOWTIE2_ASSEMBLY_BUILD.out.assembly_index
            .map { meta, assembly, index -> [ meta.group, meta, assembly, index ] }
            .combine(ch_reads_bowtie2, by: 0)
            .map { group, assembly_meta, assembly, index, reads_meta, reads -> [ assembly_meta, assembly, index, reads_meta, reads ] }
    } else {
        // combine assemblies (not co-assembled) with reads from own sample
        ch_reads_bowtie2 = reads.map{ meta, reads -> [ meta.id, meta, reads ] }
        ch_bowtie2_input = BOWTIE2_ASSEMBLY_BUILD.out.assembly_index
            .map { meta, assembly, index -> [ meta.id, meta, assembly, index ] }
            .combine(ch_reads_bowtie2, by: 0)
            .map { id, assembly_meta, assembly, index, reads_meta, reads -> [ assembly_meta, assembly, index, reads_meta, reads ] }
    }
    BOWTIE2_ASSEMBLY_ALIGN ( ch_bowtie2_input )
    // group mappings for one assembly
    ch_grouped_mappings = BOWTIE2_ASSEMBLY_ALIGN.out.mappings
        .groupTuple(by: 0)
        .map { meta, assembly, bams, bais -> [ meta, assembly.sort()[0], bams, bais ] }     // multiple symlinks to the same assembly -> use first of sorted list
    emit:
    bowtie2_assembly_multiqc = BOWTIE2_ASSEMBLY_ALIGN.out.log.map { assembly_meta, reads_meta, log -> if (assembly_meta.id == reads_meta.id) {return [ log ]} }
    bowtie2_version          = BOWTIE2_ASSEMBLY_ALIGN.out.versions
    grouped_mappings         = ch_grouped_mappings
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
