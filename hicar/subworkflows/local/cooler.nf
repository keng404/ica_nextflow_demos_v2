/*
 * pair the proper mapped pairs
 */
include { COOLER_CLOAD   } from '../../modules/local/cooler/cload/main'
include { COOLER_MERGE   } from '../../modules/local/cooler/merge/main'
include { COOLER_ZOOMIFY } from '../../modules/local/cooler/zoomify/main'
include { COOLER_DUMP
    as COOLER_DUMP_PER_GROUP    } from '../../modules/nf-core/modules/cooler/dump/main'
include { COOLER_DUMP
    as COOLER_DUMP_PER_SAMPLE   } from '../../modules/nf-core/modules/cooler/dump/main'
include { DUMPINTRAREADS
    as DUMPINTRAREADS_PER_GROUP } from '../../modules/local/cooler/dumpintrareads'
include { DUMPINTRAREADS
    as DUMPINTRAREADS_PER_SAMPLE} from '../../modules/local/cooler/dumpintrareads'
include { JUICER         } from '../../modules/local/cooler/juicer'
workflow COOLER {
    take:
    valid_pairs               // channel: [ val(meta), val(bin), [pairs], [pairs.px] ]
    chromsizes                // channel: [ path(chromsizes) ]
    juicer_jvm_params         // values
    juicer_tools_jar          // channel: [ path(juicer_tool jar) ]
    main:
    // HiC-like contact matrix
    ch_version = COOLER_CLOAD(valid_pairs.map{[it[0], it[2], it[3]]}, valid_pairs.map{it[1]}, chromsizes).versions
    // Merge contacts
    COOLER_CLOAD.out.cool
                .map{
                    meta, bin, cool ->
                    [meta.group, bin, cool]
                }
                .groupTuple(by:[0, 1])
                .map{group, bin, cool -> [[id:group, bin:bin], cool]}
                .set{ch_cooler}
    COOLER_MERGE(ch_cooler)
    // create mcooler file for visualization
    COOLER_ZOOMIFY(COOLER_MERGE.out.cool)
    // dump long.intra.bedpe for each group for MAPS to call peaks
    COOLER_DUMP_PER_GROUP(COOLER_MERGE.out.cool, []).bedpe | DUMPINTRAREADS_PER_GROUP
    if(juicer_tools_jar){
        JUICER(DUMPINTRAREADS_PER_GROUP.out.gi, juicer_tools_jar, chromsizes, juicer_jvm_params)
        ch_version = ch_version.mix(JUICER.out.versions)
    }
    // dump long.intra.bedpe for each sample
    COOLER_DUMP_PER_SAMPLE(COOLER_CLOAD.out.cool.map{ meta, bin, cool -> [[id:meta.id, group:meta.group, bin:bin], cool]}, [])
    DUMPINTRAREADS_PER_SAMPLE(COOLER_DUMP_PER_SAMPLE.out.bedpe)
    ch_version = ch_version.mix(DUMPINTRAREADS_PER_GROUP.out.versions)
    emit:
    mcool       = COOLER_ZOOMIFY.out.mcool                  // channel: [ val(meta), [mcool] ]
    groupbedpe  = COOLER_DUMP_PER_GROUP.out.bedpe           // channel: [ val(meta), [bedpe] ]
    bedpe       = DUMPINTRAREADS_PER_GROUP.out.bedpe        // channel: [ val(meta), [bedpe] ]
    samplebedpe = DUMPINTRAREADS_PER_SAMPLE.out.bedpe       // channel: [ val(meta), [bedpe] ]
    versions    = ch_version                                // channel: [ path(version) ]
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
