/*
 * pair the proper mapped pairs
 */
include { PAIRTOOLS_DEDUP    } from '../../modules/nf-core/modules/pairtools/dedup/main'
include { PAIRTOOLS_FLIP     } from '../../modules/nf-core/modules/pairtools/flip/main'
include { PAIRTOOLS_PARSE    } from '../../modules/nf-core/modules/pairtools/parse/main'
include { PAIRTOOLS_RESTRICT } from '../../modules/nf-core/modules/pairtools/restrict/main'
include { PAIRTOOLS_SELECT   } from '../../modules/nf-core/modules/pairtools/select/main'
include { PAIRTOOLS_SELECT
    as PAIRTOOLS_SELECT_LONG } from '../../modules/nf-core/modules/pairtools/select/main'
include { PAIRTOOLS_SORT     } from '../../modules/nf-core/modules/pairtools/sort/main'
include { PAIRIX             } from '../../modules/nf-core/modules/pairix/main'
include { READS_STAT         } from '../../modules/local/reads_stat'
include { READS_SUMMARY      } from '../../modules/local/reads_summary'
include { PAIRSQC            } from '../../modules/local/pairix/pairsqc'
include { PAIRSPLOT          } from '../../modules/local/pairix/pairsplot'
include { BIOC_PAIRS2HDF5    } from '../../modules/local/bioc/pairs2hdf5'
workflow PAIRTOOLS_PAIRE {
    take:
    ch_bam      // channel: [ val(meta), [bam] ]
    chromsizes  // channel: [ path(chromsizes) ]
    frag        // channel: [ path(fragment) ]
    main:
    //raw pairs, output raw.pairsam
    PAIRTOOLS_PARSE(ch_bam, chromsizes)
    // select valid pairs
    PAIRTOOLS_SELECT(PAIRTOOLS_PARSE.out.pairsam)
    // remove same fragment pairs, output samefrag.pairs, valid.pairs <- like HiC pairs
    PAIRTOOLS_RESTRICT(PAIRTOOLS_SELECT.out.selected, frag)
    PAIRTOOLS_SELECT_LONG(PAIRTOOLS_RESTRICT.out.restrict)
    // save valid pairs to hdf5
    BIOC_PAIRS2HDF5(PAIRTOOLS_SELECT_LONG.out.unselected, chromsizes)
    // select valid pairs, output sorted.pairs
    PAIRTOOLS_FLIP(PAIRTOOLS_SELECT_LONG.out.unselected, chromsizes)
    PAIRTOOLS_SORT(PAIRTOOLS_FLIP.out.flip)
    // remove duplicate pairs, output dedup.pairs
    PAIRTOOLS_DEDUP(PAIRTOOLS_SORT.out.sorted)
    // make index for valid.pairs
    PAIRIX(PAIRTOOLS_DEDUP.out.pairs)
    //reads information
    PAIRTOOLS_PARSE.out.stat
                        .map{meta, stat -> [meta.id, meta, stat]}
                        .join(PAIRTOOLS_DEDUP.out.stat.map{meta, stat -> [meta.id, stat]})
                        .map{id, meta, raw, dedup -> [meta, raw, dedup ]}
                        .set{ reads_stat }
    READS_STAT(reads_stat)
    PAIRSQC(PAIRIX.out.index, chromsizes)
    PAIRSPLOT(PAIRSQC.out.qc)
    READS_SUMMARY(READS_STAT.out.stat.map{it[1]}
                                    .mix(PAIRSPLOT.out.summary.map{it[1]})
                                    .mix(PAIRSPLOT.out.csv.map{it[1]}).collect())
    emit:
    pair = PAIRIX.out.index               // channel: [ val(meta), [valid.pair.gz], [valid.pair.gz.px] ]
    stat = READS_SUMMARY.out.summary      // channel: [ path(summary) ]
    qc   = PAIRSQC.out.qc                 // channel: [ val(meta), [qc]]
    raw  = PAIRTOOLS_PARSE.out.pairsam    // channel: [ val(meta), [pairsam] ]
    validpair  = PAIRTOOLS_SELECT.out.selected        // channel: [val(meta), [validpair]]
    distalpair = PAIRTOOLS_SELECT_LONG.out.unselected // channel: [val(meta), [valid.pair.gz]]
    hdf5 = BIOC_PAIRS2HDF5.out.hdf5       // channel: [ val(meta), [hdf5] ]
    versions = PAIRTOOLS_PARSE.out.versions // channel: [ path(version) ]
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
