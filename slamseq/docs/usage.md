# nf-core/slamseq: Usage

## Table of contents

* [Table of contents](#table-of-contents)
* [Introduction](#introduction)
* [Running the pipeline](#running-the-pipeline)
  * [Updating the pipeline](#updating-the-pipeline)
  * [Reproducibility](#reproducibility)
* [Main arguments](#main-arguments)
  * [`-profile`](#-profile)
  * [`--input`](#--input)
* [Reference genomes](#reference-genomes)
  * [`--genome` (using iGenomes)](#--genome-using-igenomes)
  * [`--fasta`](#--fasta)
  * [`--bed`](#--bed)
  * [`--mapping`](#--mapping)
  * [`--vcf`](#--vcf)
  * [`--igenomes_ignore`](#--igenomes_ignore)
* [Processing parameters](#processing-parameters)
  * [`--trim5`](#--trim5)
  * [`--polyA`](#--polyA)
  * [`--multimappers`](#--multimappers)
  * [`--quantseq`](#--quantseq)
  * [`--endtoend`](#--endtoend)
  * [`--min_coverage`](#--min_coverage)
  * [`--var_fraction`](#--var_fraction)
  * [`--conversions`](#--conversions)
  * [`--base_quality`](#--base_quality)
  * [`--read_length`](#--read_length)
  * [`--pvalue`](#--pvalue)
  * [`--skip_trimming`](#--skip_trimming)
  * [`--skip_deseq2`](#--skip_deseq2)
* [Job resources](#job-resources)
  * [Automatic resubmission](#automatic-resubmission)
  * [Custom resource requests](#custom-resource-requests)
* [AWS Batch specific parameters](#aws-batch-specific-parameters)
  * [`--awsqueue`](#--awsqueue)
  * [`--awsregion`](#--awsregion)
  * [`--awscli`](#--awscli)
* [Other command line parameters](#other-command-line-parameters)
  * [`--outdir`](#--outdir)
  * [`--email`](#--email)
  * [`--email_on_fail`](#--email_on_fail)
  * [`--max_multiqc_email_size`](#--max_multiqc_email_size)
  * [`-name`](#-name)
  * [`-resume`](#-resume)
  * [`-c`](#-c)
  * [`--custom_config_version`](#--custom_config_version)
  * [`--custom_config_base`](#--custom_config_base)
  * [`--max_memory`](#--max_memory)
  * [`--max_time`](#--max_time)
  * [`--max_cpus`](#--max_cpus)
  * [`--plaintext_email`](#--plaintext_email)
  * [`--monochrome_logs`](#--monochrome_logs)
  * [`--multiqc_config`](#--multiqc_config)

## Introduction

Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/slamseq --input input.tsv -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/slamseq
```

### Reproducibility

It's a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/slamseq releases page](https://github.com/nf-core/slamseq/releases) and find the latest version number - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

## Main arguments

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Conda) - see below.

> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended.

* `docker`
  * A generic configuration profile to be used with [Docker](http://docker.com/)
  * Pulls software from dockerhub: [`nfcore/slamseq`](http://hub.docker.com/r/nfcore/slamseq/)
* `singularity`
  * A generic configuration profile to be used with [Singularity](http://singularity.lbl.gov/)
  * Pulls software from DockerHub: [`nfcore/slamseq`](http://hub.docker.com/r/nfcore/slamseq/)
* `conda`
  * Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker or Singularity.
  * A generic configuration profile to be used with [Conda](https://conda.io/docs/)
  * Pulls most software from [Bioconda](https://bioconda.github.io/)
* `test`
  * A profile with a complete configuration for automated testing
  * Includes links to test data so needs no other parameters

### `--input`

You will need to create a design file with information about the samples in your experiment before running the pipeline. Use this parameter to specify its location. It has to be a tab-separated file with minimum 4 columns, and a header row as shown in the examples below.

```bash
--input '[path to design file]'
```

#### Required columns

The `group` identifier demarks a given celltype or patient in which an experiment was performed and should be identical for all conditions and replicates in which an experiment was performed. The `condition` identifier demarks a given condition such as a control / drug treatment or WT / KO genotype and should be identical for all replicates of the given condition. The `control` identifier is used to demark all replicates of a control `condition` with a given `group` and should be `1` for control replicates and `0` for all others. This is used to set up the proper contrasts for the [DESeq2](https://doi.org/10.1186/s13059-014-0550-8) analysis. The last required column is `reads` pointing to the associated raw read sets in fastq format.

In the design below there a triplicate samples for two groups (`K562` and `OCIAML3`) with two conditions each (one control condition `DMSO` and two treatment conditions `NVP.lo` and `NVP.hi`).

| group   | condition | control | reads |
|---------|-----------|---------|-------|
| MOLM-13 | DMSO   | 1 | MOLM-13_dmso_1.fq.gz   |
| MOLM-13 | DMSO   | 1 | MOLM-13_dmso_2.fq.gz   |
| MOLM-13 | DMSO   | 1 | MOLM-13_dmso_3.fq.gz   |
| MOLM-13 | NVP_hi | 0 | MOLM-13_nvp.hi_1.fq.gz |
| MOLM-13 | NVP_hi | 0 | MOLM-13_nvp.hi_2.fq.gz |
| MOLM-13 | NVP_hi | 0 | MOLM-13_nvp.hi_3.fq.gz |
| MOLM-13 | NVP_lo | 0 | MOLM-13_nvp.lo_1.fq.gz |
| MOLM-13 | NVP_lo | 0 | MOLM-13_nvp.lo_2.fq.gz |
| MOLM-13 | NVP_lo | 0 | MOLM-13_nvp.lo_3.fq.gz |
| OCIAML3 | DMSO   | 1 | OCIAML3_dmso_1.fq.gz   |
| OCIAML3 | DMSO   | 1 | OCIAML3_dmso_2.fq.gz   |
| OCIAML3 | DMSO   | 1 | OCIAML3_dmso_3.fq.gz   |
| OCIAML3 | NVP_hi | 0 | OCIAML3_nvp.hi_1.fq.gz |
| OCIAML3 | NVP_hi | 0 | OCIAML3_nvp.hi_2.fq.gz |
| OCIAML3 | NVP_hi | 0 | OCIAML3_nvp.hi_3.fq.gz |
| OCIAML3 | NVP_lo | 0 | OCIAML3_nvp.lo_1.fq.gz |
| OCIAML3 | NVP_lo | 0 | OCIAML3_nvp.lo_2.fq.gz |
| OCIAML3 | NVP_lo | 0 | OCIAML3_nvp.lo_3.fq.gz |

<details>
<summary>Raw TSV:</summary>

```bash
group  condition control reads
MOLM-13 DMSO  1 MOLM-13_dmso_1.fq.gz
MOLM-13 DMSO  1 MOLM-13_dmso_2.fq.gz
MOLM-13 DMSO  1 MOLM-13_dmso_3.fq.gz
MOLM-13 NVP_hi  0 MOLM-13_nvp.hi_1.fq.gz
MOLM-13 NVP_hi  0 MOLM-13_nvp.hi_2.fq.gz
MOLM-13 NVP_hi  0 MOLM-13_nvp.hi_3.fq.gz
MOLM-13 NVP_lo  0 MOLM-13_nvp.lo_1.fq.gz
MOLM-13 NVP_lo  0 MOLM-13_nvp.lo_2.fq.gz
MOLM-13 NVP_lo  0 MOLM-13_nvp.lo_3.fq.gz
OCIAML3 DMSO  1 OCIAML3_dmso_1.fq.gz
OCIAML3 DMSO  1 OCIAML3_dmso_2.fq.gz
OCIAML3 DMSO  1 OCIAML3_dmso_3.fq.gz
OCIAML3 NVP_hi  0 OCIAML3_nvp.hi_1.fq.gz
OCIAML3 NVP_hi  0 OCIAML3_nvp.hi_2.fq.gz
OCIAML3 NVP_hi  0 OCIAML3_nvp.hi_3.fq.gz
OCIAML3 NVP_lo  0 OCIAML3_nvp.lo_1.fq.gz
OCIAML3 NVP_lo  0 OCIAML3_nvp.lo_2.fq.gz
OCIAML3 NVP_lo  0 OCIAML3_nvp.lo_3.fq.gz
```

</details>

#### Optional columns

In the above example the sample name will be derived from the read file name in the `reads` column. If you want to have control over the sample naming, you can add three additional metadata columns for file naming and information about whether the samples were produced in a `pulse` or `chase` experiment as well as the duration of the `4SU` treatment in minutes. The latter two columns `type` and `time` can be to facilitate half-life estimates.

If those columns are left empty or in the minimal design above, the `type` column will default to `pulse` and the `time` column to `0`.

A full design file using the above example may look something like the one below:

| group   | condition | control | reads | name | type | time |
|---------|-----------|---------|-------|------|------|------|
| MOLM-13 | DMSO   | 1 | MOLM-13_dmso_1.fq.gz   | M13_DMSO_1   | pulse | 60 |
| MOLM-13 | DMSO   | 1 | MOLM-13_dmso_2.fq.gz   | M13_DMSO_2   | pulse | 60 |
| MOLM-13 | DMSO   | 1 | MOLM-13_dmso_3.fq.gz   | M13_DMSO_3   | pulse | 60 |
| MOLM-13 | NVP_hi | 0 | MOLM-13_nvp.hi_1.fq.gz | M13_NVP_HI_1 | pulse | 60 |
| MOLM-13 | NVP_hi | 0 | MOLM-13_nvp.hi_2.fq.gz | M13_NVP_HI_2 | pulse | 60 |
| MOLM-13 | NVP_hi | 0 | MOLM-13_nvp.hi_3.fq.gz | M13_NVP_HI_3 | pulse | 60 |
| MOLM-13 | NVP_lo | 0 | MOLM-13_nvp.lo_1.fq.gz | M13_NVP_LO_1 | pulse | 60 |
| MOLM-13 | NVP_lo | 0 | MOLM-13_nvp.lo_2.fq.gz | M13_NVP_LO_2 | pulse | 60 |
| MOLM-13 | NVP_lo | 0 | MOLM-13_nvp.lo_3.fq.gz | M13_NVP_LO_3 | pulse | 60 |
| OCIAML3 | DMSO   | 1 | OCIAML3_dmso_1.fq.gz   | O3_DMSO_1    | pulse | 60 |
| OCIAML3 | DMSO   | 1 | OCIAML3_dmso_2.fq.gz   | O3_DMSO_2    | pulse | 60 |
| OCIAML3 | DMSO   | 1 | OCIAML3_dmso_3.fq.gz   | O3_DMSO_3    | pulse | 60 |
| OCIAML3 | NVP_hi | 0 | OCIAML3_nvp.hi_1.fq.gz | O3_NVP_HI_1  | pulse | 60 |
| OCIAML3 | NVP_hi | 0 | OCIAML3_nvp.hi_2.fq.gz | O3_NVP_HI_2  | pulse | 60 |
| OCIAML3 | NVP_hi | 0 | OCIAML3_nvp.hi_3.fq.gz | O3_NVP_HI_3  | pulse | 60 |
| OCIAML3 | NVP_lo | 0 | OCIAML3_nvp.lo_1.fq.gz | O3_NVP_LO_1  | pulse | 60 |
| OCIAML3 | NVP_lo | 0 | OCIAML3_nvp.lo_2.fq.gz | O3_NVP_LO_2  | pulse | 60 |
| OCIAML3 | NVP_lo | 0 | OCIAML3_nvp.lo_3.fq.gz | O3_NVP_LO_3  | pulse | 60 |

<details>
<summary>Raw TSV:</summary>

```bash
group  condition control reads name  type  time
MOLM-13 DMSO  1 MOLM-13_dmso_1.fq.gz  M13_DMSO_1  pulse 60
MOLM-13 DMSO  1 MOLM-13_dmso_2.fq.gz  M13_DMSO_2  pulse 60
MOLM-13 DMSO  1 MOLM-13_dmso_3.fq.gz  M13_DMSO_3  pulse 60
MOLM-13 NVP_hi  0 MOLM-13_nvp.hi_1.fq.gz  M13_NVP_HI_1  pulse 60
MOLM-13 NVP_hi  0 MOLM-13_nvp.hi_2.fq.gz  M13_NVP_HI_2  pulse 60
MOLM-13 NVP_hi  0 MOLM-13_nvp.hi_3.fq.gz  M13_NVP_HI_3  pulse 60
MOLM-13 NVP_lo  0 MOLM-13_nvp.lo_1.fq.gz  M13_NVP_LO_1  pulse 60
MOLM-13 NVP_lo  0 MOLM-13_nvp.lo_2.fq.gz  M13_NVP_LO_2  pulse 60
MOLM-13 NVP_lo  0 MOLM-13_nvp.lo_3.fq.gz  M13_NVP_LO_3  pulse 60
OCIAML3 DMSO  1 OCIAML3_dmso_1.fq.gz  O3_DMSO_1 pulse 60
OCIAML3 DMSO  1 OCIAML3_dmso_2.fq.gz  O3_DMSO_2 pulse 60
OCIAML3 DMSO  1 OCIAML3_dmso_3.fq.gz  O3_DMSO_3 pulse 60
OCIAML3 NVP_hi  0 OCIAML3_nvp.hi_1.fq.gz  O3_NVP_HI_1 pulse 60
OCIAML3 NVP_hi  0 OCIAML3_nvp.hi_2.fq.gz  O3_NVP_HI_2 pulse 60
OCIAML3 NVP_hi  0 OCIAML3_nvp.hi_3.fq.gz  O3_NVP_HI_3 pulse 60
OCIAML3 NVP_lo  0 OCIAML3_nvp.lo_1.fq.gz  O3_NVP_LO_1 pulse 60
OCIAML3 NVP_lo  0 OCIAML3_nvp.lo_2.fq.gz  O3_NVP_LO_2 pulse 60
OCIAML3 NVP_lo  0 OCIAML3_nvp.lo_3.fq.gz  O3_NVP_LO_3 pulse 60
```

</details>

| Column      | Description                                                                                                                                      |
|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `group`     | Group identifier for sample. This will be identical for all conditions and replicate samples from the same experimental group. |
| `condition` | Condition within a given group, such as a control / drug treatment or WT / KO condition. This will be identical for all replicate samples of a given condition.           |
| `control` | Integer value denoting whether a sample belongs to a control condition `1` or not `0`. This is used to build contrasts for DE-analysis.           |
| `reads`   | Full path to reads FastQ file. File has to be zipped and have the extension ".fastq.gz" or ".fq.gz".                                        |
| `name`   | Sample name                                        |
| `type`  | Type of the labelling experiment. Has to be either `pulse` or `chase`.                 |
| `time`   | Labelling time with 4SU in minute.     |

Example design files have been provided in the [test-datasets](../assets/design_pe.csv).

## Reference genomes

The pipeline config files come bundled with paths to the illumina iGenomes reference index files. If running with docker or AWS, the configuration is set up to use the [AWS-iGenomes](https://ewels.github.io/AWS-iGenomes/) resource.

### `--genome` (using iGenomes)

There are 31 different species supported in the iGenomes references. To run the pipeline, you must specify which to use with the `--genome` flag.

You can find the keys to specify the genomes in the [iGenomes config file](../conf/igenomes.config). Common genomes that are supported are:

* Human
  * `--genome GRCh38`
* Mouse
  * `--genome GRCm38`
* _Drosophila_
  * `--genome BDGP6`
* _S. cerevisiae_
  * `--genome 'R64-1-1'`

> There are numerous others - check the config file for more.

Note that you can use the same configuration setup to save sets of reference files for your own use, even if they are not part of the iGenomes resource. See the [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for instructions on where to save such a file.

The syntax for this reference configuration is as follows:

```nextflow
params {
  genomes {
    'GRCh37' {
      fasta   = '<path to the genome fasta file>' // Used if fasta given
      gtf     = '<path to the genome gtf file>' // Used if no bed given
    }
    // Any number of additional genomes, key is used with --genome
  }
}
```

### `--fasta`

Full path to fasta file containing reference genome (*mandatory* if `--genome` is not specified).

```bash
--fasta '[path to FASTA reference]'
```

### `--bed`

Full path to bed file containing 3' end counting windows (*mandatory* if `--genome` is not specified).

```bash
--bed '[path to counting windows bed]'
```

### `--mapping`

Full path to bed file containing 3' UTRs for multimapper recovery (optional).

```bash
--mapping '[path to UTR bed]'
```

### `--vcf`

Path to VCF file for genomic SNPs to mask T>C conversions (optional)
Full path to VCF file for genomic SNPs to mask T>C conversions (optional). Bypasses `slamdunk snp` step.

```bash
--vcf '[path to SNP vcf]'
```

### `--igenomes_ignore`

Do not load `igenomes.config` when running the pipeline. You may choose this option if you observe clashes between custom parameters and those supplied in `igenomes.config`.

## Processing parameters

### `--trim5`

Integer indicating the number of basepairs to trim from the 5' end of the reads.

```bash
--trim5 '[number of  bp to trim from 5prime end]'
```

### `--polyA`

Integer indicating the maximum number of As at the 3' end of a read before considering them as poly-As and trimming them.

```bash
--polyA '[Maximum 3prime end read As]'
```

### `--multimappers`

Boolean flag activating the [multimapper recovery strategy](https://t-neumann.github.io/slamdunk/docs.html#multimapper-reconciliation). Will either use the bed file supplied by `--mapping` or alternatively use the plain `--bed` file.

### `--quantseq`

Boolean flag deactivating the conversion-aware scoring scheme in [NextGenMap](http://cibiv.github.io/NextGenMap/). This will result in always zero T>C reads and render [DESeq2](https://doi.org/10.1186/s13059-014-0550-8) analysis meaningless.

### `--endtoend`

Boolean flag to activate end-to-end mapping in [NextGenMap](http://cibiv.github.io/NextGenMap/).

### `--min_coverage`

Minimum coverage to call a SNP as integer.

```bash
--min_coverage '[Minimum coverage to call a SNP]'
```

### `--var_fraction`

Minimum variant fraction to call a SNP as float.

```bash
--var_fraction '[Minimum variant fraction to call a SNP]'
```

### `--conversions`

Minimum number of T>C conversions in a read to call it a T>C read.

```bash
--conversions '[Number of conversions to call a T>C read]'
```

### `--base_quality`

Minimum base quality to call a T>C conversion as integer.

```bash
--base_quality '[Minimum base quality for a T>C conversion]'
```

### `--read_length`

Read length of your samples as integer.

```bash
--read_length '[Read length of your samples]'
```

### `--pvalue`

P-value cutoff for the MA-plots.

```bash
--pvalue '[P-value cutoff]'
```

### `--skip_trimming`

Booelan flag to skip trimming with [`Trim Galore!`](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/).

### `--skip_deseq2`

Booelan flag to skip differential transcriptional output anaysis with [DESeq2](https://doi.org/10.1186/s13059-014-0550-8).

## Job resources

### Automatic resubmission

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

### Custom resource requests

Wherever process-specific requirements are set in the pipeline, the default value can be changed by creating a custom config file. See the files hosted at [`nf-core/configs`](https://github.com/nf-core/configs/tree/master/conf) for examples.

If you are likely to be running `nf-core` pipelines regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter (see definition below). You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack).

## AWS Batch specific parameters

Running the pipeline on AWS Batch requires a couple of specific parameters to be set according to your AWS Batch configuration. Please use [`-profile awsbatch`](https://github.com/nf-core/configs/blob/master/conf/awsbatch.config) and then specify all of the following parameters.

### `--awsqueue`

The JobQueue that you intend to use on AWS Batch.

### `--awsregion`

The AWS region in which to run your job. Default is set to `eu-west-1` but can be adjusted to your needs.

### `--awscli`

The [AWS CLI](https://www.nextflow.io/docs/latest/awscloud.html#aws-cli-installation) path in your custom AMI. Default: `/home/ec2-user/miniconda/bin/aws`.

Please make sure to also set the `-w/--work-dir` and `--outdir` parameters to a S3 storage bucket of your choice - you'll get an error message notifying you if you didn't.

## Other command line parameters

### `--outdir`

The output directory where the results will be saved.

### `--email`

Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.

### `--email_on_fail`

This works exactly as with `--email`, except emails are only sent if the workflow is not successful.

### `--max_multiqc_email_size`

Threshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, it will not be attached (Default: 25MB).

### `-name`

Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

This is used in the MultiQC report (if not default) and in the summary HTML / e-mail (always).

**NB:** Single hyphen (core Nextflow option)

### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

**NB:** Single hyphen (core Nextflow option)

### `-c`

Specify the path to a specific config file (this is a core NextFlow command).

**NB:** Single hyphen (core Nextflow option)

Note - you can use this to override pipeline defaults.

### `--custom_config_version`

Provide git commit id for custom Institutional configs hosted at `nf-core/configs`. This was implemented for reproducibility purposes. Default: `master`.

```bash
## Download and use config file with following git commid id
--custom_config_version d52db660777c4bf36546ddb188ec530c3ada1b96
```

### `--custom_config_base`

If you're running offline, nextflow will not be able to fetch the institutional config files
from the internet. If you don't need them, then this is not a problem. If you do need them,
you should download the files from the repo and tell nextflow where to find them with the
`custom_config_base` option. For example:

```bash
## Download and unzip the config files
cd /path/to/my/configs
wget https://github.com/nf-core/configs/archive/master.zip
unzip master.zip

## Run the pipeline
cd /path/to/my/data
nextflow run /path/to/pipeline/ --custom_config_base /path/to/my/configs/configs-master/
```

> Note that the nf-core/tools helper package has a `download` command to download all required pipeline
> files + singularity containers + institutional configs in one go for you, to make this process easier.

### `--max_memory`

Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'`

### `--max_time`

Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### `--max_cpus`

Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`

### `--plaintext_email`

Set to receive plain-text e-mails instead of HTML formatted.

### `--monochrome_logs`

Set to disable colourful command line output and live life in monochrome.

### `--multiqc_config`

Specify a path to a custom MultiQC configuration file.
