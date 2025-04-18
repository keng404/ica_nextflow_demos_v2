# Clinical-Genomics-Laboratory/nf-cgl-cgs: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Demultiplex samples (optional)](#demultiplex-samples-optional) - Demultiplex input samples if specified
- [Alignment and mapping](#alignment-and-mapping) - Samples are aligned and mapped to the reference input
- [Batch joint genotyping](#batch-joint-genotyping) - Gather and joint genotype all samples
- [Pipeline information](#pipeline-information)

### Demultiplex samples (optional)

> [!NOTE]
> Demultiplexing is an optional step. If FastQ files exist, input a `fastq_list.csv` to the `--fastq_list` parameter.

Samples can be demultiplexed when the following parameters are used: `--input <mgi_samplesheet>` and `--illumina_rundir <run_dir>`. To save the demultiplexed data, use `--demux_outdir <dir_path>`.

<details markdown="1">
<summary>Output files</summary>

- `<params.demux_outdir>/<params.batch_name>`

  - `dragen.time_metrics.csv`: Runtime log
  - `dragen-replay.json`: Log of commands and DRAGEN configurations for demultiplexing samples.
  - `*.fastq.gz`: File that contains biological sequence data and its corresponding quality scores.

- `<params.demux_outdir>/<params.batch_name>/Logs/`

  - `*.log`: DRAGEN output logs.
  - `FastqComplete.txt`: Contains timestamp of when FastQ generation is complete.

- `<params.demux_outdir>/<params.batch_name>/Reports/`
  - `*_{Metrics,Stats,Counts,Barcodes}.csv`: Various QC metrics.
  - `RunInfo.xml`: Run information for sample demultiplexing.
  - `SampleSheet.csv`: Contains sample information and their corresponding indexes.
  - `fastq_list.csv`: File that contains indexes, lane, FastQ file names, etc. for each sample.

</details>

### Alignment and mapping

The input reference files are used to align and map each sample.

<details markdown="1">
<summary>Output files</summary>

- `DRAGEN_output/<sample_name>`
  - `*.bai`: An index of the Binary Alignment Map (BAM) file.
  - `*_metrics.csv`: Reports that contain various QC metrics.
  - `*.bw`: BigWig files that can be used for visualization in IGV.
  - `*.targeted.json`: Summary of variant caller results for each target.
  - `*.bam`: Binary Alignment Map (BAM) file that represents aligned sequences.
  - `*.vcf.gz`: A text file that contains information about gene sequence variations.
  - `*.gff3`: A tab-delimited text file that contains information about copy number variants (CNV).
  - `*.cnv.excluded_intervals.bed.gz`: List of genomic intervals that are excluded due to failing at least one quality requirement.
  - `*_usage.txt`: Details DRAGEN credit usage for sample alignment.
  - `*-replay.json`: Details the exact parameters and configurations used for sample alignment.

</details>

### QC metrics

During the alignment and mapping of each sample, various QC metrics are produced.

> [!NOTE]
> To save QC metrics in an additional location, specify the location to a directory using `--qc_outdir`.

<details markdown="1">
<summary>Output files</summary>

- `QC_metrics/`
  - `*_All_QC.xlsx`: Includes all quality control metrics from the analysis.
  - `*_Genoox.xlsx`: Includes only the quality control metrics required by Genoox.
  - `*_MGI_QC.xlsx`: Includes only the quality control metrics required by MGI.

</details>

### Batch joint genotyping

All samples can undergo small variant (SNV/InDel), structural variant (SV), and/or copy number variant (CNV) joint genotyping. This is to help reduce the noise in the final VCF files.

<details markdown="1">
<summary>Output files</summary>

- `DRAGEN_output/<sample_name>`
  - `*.vcf.gz`: A text file that contains information about gene sequence variations.

</details>

### Pipeline information

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `aws_log.txt`: Contains error logs from AWS uploads.
  - `DRAGEN_usage.tsv`: Details DRAGEN credit usage for each sample and joint calling process.
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>
