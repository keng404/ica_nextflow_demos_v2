# nf-core/diaproteomics: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/)
and processes data using the following steps:

* [Summary output files](#SummaryOutput) - Output files of peptide / protein quantities and pdf reports
* [Spectral library files](#SpectralLibrary) - Generated spectral library files (tsv, pqp, with/without decoys, irts)
* [OpenSwathWorkflow output files](#OpenSwathWorkflow) - Output files of the OpenSwathWorkflow (osw, chrom.mzML)
* [Pyprophet output files](#Pyprophet) - Output files of pyprophet (osw, tsv, pdf)
* [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

For detailed information about file formats and how they are in the various steps visit the detailed documentation of the [OpenSwathWorkflow](http://openswath.org/en/latest/docs/openswath.html).

## SummaryOutput

Several csv tables and optional an mzTab file (Note: the mzTab format is not yet well supported for DIA) are generated summarizing peptide or protein quantities (if protein level msstats was applied). In addition PDF reports are created.

* Output visualizations:
  * the number of peptide / protein identifications
  * the peptide charge distribution
  * the library and DIA measurement RT deviation
  * the comparative quantities across samples as heatmap
  * (+ if protein level MSstat was applied additional comparative volcano plots)

## SpectralLibrary

Several files summarizing the used spectral library are generated, depending on whether the library and iRTs were generated from provided matched DDA data.

* Library files:
  * a tsv table listing all peptide precursors and their transitions used for the library
  * a pqp file storing the library in sqlite format including generated decoy transitions
  * a pqp file storing the iRT library in sqlite format
  * if merging of multiple libraries and RT alignment was specified, the pairwise alignment graph is exported as pdf.

## OpenSwathWorkflow

For each provided DIA MS run the OpenSwathWorkflow output is reported.

* OpenSwathWorkflow output:
  * osw files storing the scoring output in sqlite format
  * chrom.mzML file storing the extracted ion chromatogram for each peptide transition

## Pyprophet

Several files summarizing the pyprophet local or global scoring results for each DIA MS run separately, aggregated in sqlite format and visualized as report.

* PyprophetOutput
  * osw files storing the aggregated scoring output per sample
  * tsv files storing the scoring output as table for each MS run
  * pdf reports visualizing the aggregated target decoy score distributions

## Pipeline information

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

**Output files:**

* `pipeline_info/`
  * Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  * Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.csv`.
  * Documentation for interpretation of results in HTML format: `results_description.html`.