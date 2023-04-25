/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/
def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)
// Validate input parameters
WorkflowBacass.initialise(params, log)
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.kraken2db, params.dfast_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
// Check krakendb
if(! params.skip_kraken2){
    if(params.kraken2db){
        kraken2db = file(params.kraken2db)
    } else {
        exit 1, "Missing Kraken2 DB arg"
    }
}
/*
========================================================================================
    CONFIG FILES
========================================================================================
*/
ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()
/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/
// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()
def unicycler_options = modules['unicycler']
unicycler_options.args       += " $params.unicycler_args"
def canu_options = modules['canu']
canu_options.args       += " $params.canu_args"
//
// MODULE: Local to the pipeline
//
include { GET_SOFTWARE_VERSIONS } from '../modules/local/get_software_versions'    addParams( options: [publish_files : ['tsv':'']] )
include { SKEWER                } from '../modules/local/skewer'                   addParams( options: modules['skewer']            )
include { NANOPLOT              } from '../modules/local/nanoplot'                 addParams( options: modules['nanoplot']          )
include { PYCOQC                } from '../modules/local/pycoqc'                   addParams( options: modules['pycoqc']            )
include { PORECHOP              } from '../modules/local/porechop'                 addParams( options: modules['porechop']          )
include { UNICYCLER             } from '../modules/local/unicycler'                addParams( options: unicycler_options            )
include { CANU                  } from '../modules/local/canu'                     addParams( options: canu_options                 )
include { MINIMAP2_ALIGN        } from '../modules/local/minimap_align'           addParams( options: modules['minimap_align']      )
include { MINIMAP2_ALIGN as MINIMAP2_CONSENSUS } from '../modules/local/minimap_align' addParams( options: modules['minimap_consensus'])
include { MINIMAP2_ALIGN as MINIMAP2_POLISH    } from '../modules/local/minimap_align' addParams( options: modules['minimap_polish'])
include { MINIASM               } from '../modules/local/miniasm'                  addParams( options: modules['miniasm']           )
include { RACON                 } from '../modules/local/racon'                    addParams( options: modules['racon']             )
include { MEDAKA                } from '../modules/local/medaka'                   addParams( options: modules['medaka']            )
include { NANOPOLISH            } from '../modules/local/nanopolish'               addParams( options: modules['nanopolish']        )
include { KRAKEN2_DB_PREPARATION} from '../modules/local/kraken2_db_preparation'
include { DFAST                 } from '../modules/local/dfast'                    addParams( options: modules['dfast']             )
//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check' addParams( options: [:] )
/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/
def multiqc_options   = modules['multiqc']
multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''
def prokka_options   = modules['prokka']
prokka_options.args  += " $params.prokka_args"
//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC    } from '../modules/nf-core/modules/fastqc/main'          addParams( options: modules['fastqc']    )
include { SAMTOOLS_SORT    } from '../modules/nf-core/modules/samtools/sort/main' addParams( options: [publish_files : false] )
include { SAMTOOLS_INDEX   } from '../modules/nf-core/modules/samtools/index/main' addParams( options: [publish_files : false] )
include { KRAKEN2_KRAKEN2 as KRAKEN2 } from '../modules/nf-core/modules/kraken2/kraken2/main' addParams( options: modules['kraken2'] )
include { KRAKEN2_KRAKEN2 as KRAKEN2_LONG } from '../modules/nf-core/modules/kraken2/kraken2/main' addParams( options: modules['kraken2_long'] )
include { QUAST     } from '../modules/nf-core/modules/quast/main'           addParams( options: modules['quast']     )
include { PROKKA    } from '../modules/nf-core/modules/prokka/main'          addParams( options: prokka_options       )
include { MULTIQC   } from '../modules/nf-core/modules/multiqc/main'         addParams( options: multiqc_options      )
/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/
// Info required for completion email and summary
def multiqc_report = []
workflow BACASS {
    ch_software_versions = Channel.empty()
    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    //
    // MODULE: Run FastQC
    //
    FASTQC (
        INPUT_CHECK.out.shortreads
    )
    ch_software_versions = ch_software_versions.mix(FASTQC.out.version.first().ifEmpty(null))
    //
    // MODULE: Skewer, trim and combine short read read-pairs per sample.
    //
    SKEWER (
        INPUT_CHECK.out.shortreads.dump(tag: 'shortreads')
    )
    ch_software_versions = ch_software_versions.mix(SKEWER.out.version.first().ifEmpty(null))
    //
    // MODULE: Nanoplot, quality check for nanopore reads and Quality/Length Plots
    //
    NANOPLOT (
        INPUT_CHECK.out.longreads
    )
    ch_software_versions = ch_software_versions.mix(NANOPLOT.out.version.first().ifEmpty(null))
    //
    // MODULE: PYCOQC, quality check for nanopore reads and Quality/Length Plots
    //
    if ( !params.skip_pycoqc ) {
        PYCOQC (
            INPUT_CHECK.out.fast5.dump(tag: 'fast5')
        )
        ch_software_versions = ch_software_versions.mix(PYCOQC.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: PYCOQC, quality check for nanopore reads and Quality/Length Plots
    //
    if ( params.assembly_type == 'hybrid' || params.assembly_type == 'long' && !('short' in params.assembly_type) ) {
        PORECHOP (
            INPUT_CHECK.out.longreads.dump(tag: 'longreads')
        )
        ch_software_versions = ch_software_versions.mix(PORECHOP.out.version.first().ifEmpty(null))
    }
    //
    // Join channels for assemblers. As samples have the same meta data, we can simply use join() to merge the channels based on this. If we only have one of the channels we insert 'NAs' which are not used in the unicycler process then subsequently, in case of short or long read only assembly.
    // Prepare channel for Kraken2
    //
    if(params.assembly_type == 'hybrid'){
        ch_for_kraken2_short = SKEWER.out.reads
        ch_for_kraken2_long = PORECHOP.out.reads.dump(tag: 'porechop')
        SKEWER.out.reads
            .dump(tag: 'skewer')
            .join(PORECHOP.out.reads)
            .dump(tag: 'ch_for_assembly')
            .set { ch_for_assembly }
    } else if ( params.assembly_type == 'short' ) {
        ch_for_kraken2_short = SKEWER.out.reads
        ch_for_kraken2_long = Channel.empty()
        SKEWER.out.reads
            .dump(tag: 'skewer')
            .map{ meta,reads -> tuple(meta,reads,'NA') }
            .dump(tag: 'ch_for_assembly')
            .set { ch_for_assembly }
    } else if ( params.assembly_type == 'long' ) {
        ch_for_kraken2_short = Channel.empty()
        ch_for_kraken2_long = PORECHOP.out.reads
        PORECHOP.out.reads
            .dump(tag: 'porechop')
            .map{ meta,lr -> tuple(meta,'NA',lr) }
            .dump(tag: 'ch_for_assembly')
            .set { ch_for_assembly }
    }
    //
    // ASSEMBLY: Unicycler, Canu, Miniasm
    //
    ch_assembly = Channel.empty()
    //
    // MODULE: Unicycler, genome assembly, nf-core module allows only short assembly
    //
    if ( params.assembler == 'unicycler' ) {
        UNICYCLER (
            ch_for_assembly
        )
        ch_assembly = ch_assembly.mix( UNICYCLER.out.scaffolds.dump(tag: 'unicycler') )
        ch_software_versions = ch_software_versions.mix(UNICYCLER.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: Canu, genome assembly, long reads
    //
    if ( params.assembler == 'canu' ) {
        CANU (
            ch_for_assembly
        )
        ch_assembly = ch_assembly.mix( CANU.out.assembly.dump(tag: 'canu') )
        ch_software_versions = ch_software_versions.mix(CANU.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: Miniasm, genome assembly, long reads
    //
    if ( params.assembler == 'miniasm' ) {
        MINIMAP2_ALIGN (
            ch_for_assembly.map{ meta,sr,lr -> tuple(meta,sr,lr,lr) }
        )
        ch_software_versions = ch_software_versions.mix(MINIMAP2_ALIGN.out.version.first().ifEmpty(null))
        MINIASM (
            MINIMAP2_ALIGN.out.paf.dump(tag: 'minimap2')
        )
        ch_software_versions = ch_software_versions.mix(MINIASM.out.version.first().ifEmpty(null))
        MINIMAP2_CONSENSUS (
            MINIASM.out.all.dump(tag: 'miniasm')
        )
        RACON (
            MINIMAP2_CONSENSUS.out.paf.dump(tag: 'minimap2_consensus')
        )
        ch_assembly = ch_assembly.mix( RACON.out.assembly.dump(tag: 'miniasm') )
        ch_software_versions = ch_software_versions.mix(RACON.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: Nanopolish, polishes assembly using FAST5 files - should take either miniasm, canu, or unicycler consensus sequence
    //
    if ( !params.skip_polish && params.assembly_type == 'long' && params.polish_method != 'medaka' ) {
        ch_for_assembly
            .join( ch_assembly )
            .set { ch_for_polish }
        MINIMAP2_POLISH (
            ch_for_polish.dump(tag: 'into_minimap2_polish')
        )
        ch_software_versions = ch_software_versions.mix(MINIMAP2_POLISH.out.version.first().ifEmpty(null))
        SAMTOOLS_SORT (
            MINIMAP2_POLISH.out.paf.map{ meta,sr,lr,ref,paf -> tuple(meta,paf) }.dump(tag: 'minimap2_polish')
        )
        ch_software_versions = ch_software_versions.mix(SAMTOOLS_SORT.out.version.first().ifEmpty(null))
        SAMTOOLS_INDEX (
            SAMTOOLS_SORT.out.bam.dump(tag: 'samtools_sort')
        )
        ch_software_versions = ch_software_versions.mix(SAMTOOLS_INDEX.out.version.first().ifEmpty(null))
        ch_for_polish //tuple val(meta), val(reads), file(longreads), file(assembly)
            .join( SAMTOOLS_SORT.out.bam ) //tuple  val(meta), file(bam)
            .join( SAMTOOLS_INDEX.out.bai ) //tuple  val(meta), file(bai)
            .join( INPUT_CHECK.out.fast5 ) //tuple val(meta), file(fast5)
            .set { ch_for_nanopolish } //tuple val(meta), val(reads), file(longreads), file(assembly), file(bam), file(bai), file(fast5)
        NANOPOLISH (
            ch_for_nanopolish.dump(tag: 'into_nanopolish')
        )
        ch_software_versions = ch_software_versions.mix(NANOPOLISH.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: Medaka, polishes assembly - should take either miniasm, canu, or unicycler consensus sequence
    //
    if ( !params.skip_polish && params.assembly_type == 'long' && params.polish_method == 'medaka' ) {
        ch_assembly
            .join( ch_for_assembly )
            .set { ch_for_medaka }
        MEDAKA ( ch_for_medaka.dump(tag: 'into_medaka') )
        ch_software_versions = ch_software_versions.mix(MEDAKA.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: Kraken2, QC for sample purity
    //
    if ( !params.skip_kraken2 ) {
        KRAKEN2_DB_PREPARATION (
            kraken2db
        )
        KRAKEN2 (
            ch_for_kraken2_short.dump(tag: 'kraken2_short'),
            KRAKEN2_DB_PREPARATION.out.db.map { info, db -> db }.dump(tag: 'kraken2_db_preparation')
        )
        ch_software_versions = ch_software_versions.mix(KRAKEN2.out.version.first().ifEmpty(null))
        KRAKEN2_LONG (
            ch_for_kraken2_long
                .map { meta, reads ->
                    info = [:]
                    info.id = meta.id
                    info.single_end = true
                    [ info, reads ]
                }
                .dump(tag: 'kraken2_long'),
            KRAKEN2_DB_PREPARATION.out.db.map { info, db -> db }.dump(tag: 'kraken2_db_preparation')
        )
        ch_software_versions = ch_software_versions.mix(KRAKEN2_LONG.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: QUAST, assembly QC
    //
    ch_assembly
        .map { meta, fasta -> fasta }
        .collect()
        .set { ch_to_quast }
    QUAST (
        ch_to_quast,
        [],
        [],
        false,
        false
    )
    ch_software_versions = ch_software_versions.mix(QUAST.out.version.ifEmpty(null))
    //
    // MODULE: PROKKA, gene annotation
    //
    if ( !params.skip_annotation && params.annotation_tool == 'prokka' ) {
        PROKKA (
            ch_assembly,
            [],
            []
        )
        ch_software_versions = ch_software_versions.mix(PROKKA.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: DFAST, gene annotation
    //
    // TODO: "dfast_file_downloader.py --protein dfast --dbroot ." could be used in a separate process and the db could be forwarded
    if ( !params.skip_annotation && params.annotation_tool == 'dfast' ) {
        DFAST (
            ch_assembly,
            Channel.value(params.dfast_config ? file(params.dfast_config) : "")
        )
        ch_software_versions = ch_software_versions.mix(DFAST.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: Pipeline reporting
    //
    ch_software_versions
        .map { it -> if (it) [ it.baseName, it ] }
        .groupTuple()
        .map { it[1][0] }
        .flatten()
        .collect()
        .set { ch_software_versions }
    GET_SOFTWARE_VERSIONS (
        ch_software_versions.map { it }.collect()
    )
    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowBacass.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
    MULTIQC (
        ch_multiqc_files.collect()
    )
    multiqc_report       = MULTIQC.out.report.toList()
    ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))
}
/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/
// workflow.onComplete {
//     if (params.email || params.email_on_fail) {
//         NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
//     }
//     NfcoreTemplate.summary(workflow, params, log)
// }
/*
========================================================================================
    THE END
========================================================================================
*/
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
