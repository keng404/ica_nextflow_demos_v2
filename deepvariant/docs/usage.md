# nf-core/deepvariant: Usage

## Table of contents

- [Introduction](#general-nextflow-info)
- [Running the pipeline](#running-the-pipeline)
  - [About preprocessing](#about-preprocessing)
- [Updating the pipeline](#updating-the-pipeline)
- [Reproducibility](#reproducibility)
- [Main arguments](#main-arguments)
  - [`-profile`](#-profile-single-dash)
    - [`docker`](#docker)
    - [`awsbatch`](#awsbatch)
    - [`standard`](#standard)
    - [`none`](#none)
  - [`--bam`](#--bam)
  - [`--bam_folder`](#--bam_folder)
  - [`--bam_file_prefix`](#--bam_file_prefix)
  - [`--bed`](#--bed)
- [Reference Genomes](#reference-genomes)
  - [`--genome`](#--genome)
    - [`hg19`](#hg19)
    - [`hg19chr20`](#hg19chr20)
    - [`h38`](#h38)
    - [`grch37primary`](#grch37primary)
    - [`hs37d5`](#hs37d5)
  - [`--genomes_base`](#--genomes_base)
  - [`--fasta`](#--fasta)
  - [`--fai`](#--fai)
  - [`--fastagz`](#--fastagz)
  - [`--gzfai`](#--gzfai)
  - [`--gzi`](#--gzi)
- [Exome Data](#exome-data)
  - [`--exome`](#--exome)
- [Job Resources](#job-resources)
- [Automatic resubmission](#automatic-resubmission)
- [Custom resource requests](#custom-resource-requests)
- [AWS batch specific parameters](#aws-batch-specific-parameters)
  - [`-awsbatch`](#-awsbatch)
  - [`--awsqueue`](#--awsqueue)
  - [`--awsregion`](#--awsregion)
- [Other command line parameters](#other-command-line-parameters)
  - [`--outdir`](#--outdir)
  - [`--email`](#--email)
  - [`-name`](#-name-single-dash)
  - [`-resume`](#-resume-single-dash)
  - [`-c`](#-c-single-dash)
  - [`--max_memory`](#--max_memory)
  - [`--max_time`](#--max_time)
  - [`--max_cpus`](#--max_cpus)
  - [`--plaintext_emails`](#--plaintext_emails)
  - [`--sampleLevel`](#--sampleLevel)
  - [`--multiqc_config`](#--multiqc_config)
- [Memory](#memory)

## General Nextflow info

Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/deepvariant --genome hg19 --bam testdata/test.bam --bed testdata/test.bed -profile standard,docker
```

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### About preprocessing

DeepVariant, in order to run at its fastest, requires some indexed and compressed versions of both the reference genome and the BAM files. With DeepVariant in Nextflow, if you wish, you can only use as an input the fasta and the BAM file and let us do the work for you in a clean and standarized way (standard tools like [samtools](http://samtools.sourceforge.net/) are used for indexing and every step is run inside of a Docker container).

This is how the list of the needed input files looks like. If these are passed all as input parameters, the preprocessing steps will be skipped.

```
NA12878_S1.chr20.10_10p1mb.bam   test_nist.b37_chr20_100kbp_at_10mb.bed   NA12878_S1.chr20.10_10p1mb.bam.bai
ucsc.hg19.chr20.unittest.fasta   ucsc.hg19.chr20.unittest.fasta.fai       ucsc.hg19.chr20.unittest.fasta.gz
ucsc.hg19.chr20.unittest.fasta.gz.fai   ucsc.hg19.chr20.unittest.fasta.gz.gzi
```

If you do not have all of them, these are the file you can give as input to the Nextflow pipeline, and the rest will be automatically produced for you .

```
NA12878_S1.chr20.10_10p1b.bam
test_nist.b37_chr20_100kbp_at_10mb.bed
ucsc.hg19.chr20.unittest.fasta
```

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/deepvariant
```

### Reproducibility

It's a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/deepvariant releases page](https://github.com/nf-core/deepvariant/releases) and find the latest version number - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

## Main Arguments

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments. Note that multiple profiles can be loaded, for example: `-profile standard,docker` - the order of arguments is important!

- `standard`
  - The default profile, used if `-profile` is not specified at all.
  - Runs locally and expects all software to be installed and available on the `PATH`.
- `docker`
  - A generic configuration profile to be used with [Docker](http://docker.com/)
  - Pulls software from dockerhub: [`nfcore/deepvariant`](http://hub.docker.com/r/nfcore/deepvariant/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](http://singularity.lbl.gov/)
  - Pulls software from singularity-hub
- `conda`
  - A generic configuration profile to be used with [conda](https://conda.io/docs/)
  - Pulls most software from [Bioconda](https://bioconda.github.io/)
- `awsbatch`
  - A generic configuration profile to be used with AWS Batch.
- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `test_s3`
  - A profile for testing the pipeline with files on an s3 bucket
  - Other than the `docker` profile no further inputs are required
- `none`
  - No configuration at all. Useful if you want to build your own config from scratch and want to avoid loading in the default `base` config profile (not recommended).

### `--bam`

Use this to specify the BAM file

```
--bam "/path/to/bam/file"
```

OR

### `--bam_folder`

Use this to specify a folder containing BAM files. Allows multiple BAM files to be analyzed at once. All BAM files will be analyzed unless `--bame_file_prefix` is used (see below). For example:

```
--bam_folder "/path/to/folder/where/bam/files/are"
```

**! TIP**
All the input files can be used in s3 buckets too and the s3://path/to/files/in/bucket can be used instead of a local path.

### `--bam_file_prefix`

- In case only some specific files inside the BAM folder should be used as input, a file prefix can be defined by:
  - `--bam_file_prefix`

```
--bam_file_prefix MYPREFIX                                    OPTIONAL
```

### `--bed`

- Path to bedfile, specifying region to be analysed must also be supplied

### Reference Genomes

The pipelines can acccept the refernece genome that was used to create the BAM file(s) in one of two ways. Either the reference genome can be specified eg `--genome hg19` (default) or by supplying a relevant fasta file (and optionally the indexes).

### `--genome`

Standard versions of the genome are prepared with all their compressed and indexed file in a lifebit s3 bucket.
They can be used with the following values for the `--genome` tag:

- `hg19`
  - Use if reads were aligned against hg19 reference genome to produce input bam file(s)
- `hg19chr20`
  - For testing purposes: chromosome 20 of the hg19 reference genome
- `h38`
  - Use if reads were aligned against GRCh38 reference genome to produce input bam file(s)
- `grch37primary`
  - Use if reads were aligned against GRCh37 primary reference genome to produce input bam file(s)
- `hs37d5`
  - Use if reads were aligned against hs37d5 reference genome to produce input bam file(s)

### `--genomes_base`

Base directory location of genomes (default = "s3://deepvariant-data/genomes") for use on computing clusters

OR you can use your own reference genome version, by using the following parameters:

The following parameter are optional:

### `--fasta`

- Path to fasta reference

### `--fai`

- Path to fasta index generated using `samtools faidx`

### `--fastagz`

- Path to gzipped fasta

### `--gzfai`

- Path to index of gzipped fasta generated using `samtools faidx`

### `--gzi`

- Path to bgzip index format (.gzi)

If the `fai`, `fastagz`, `gzfai` and `gzi` parameters are not passed, they will be automatically be produced for you and you will be able to find them in the "preprocessingOUTPUT" folder.

### Exome Data

### `--exome`

- For exome bam files

If you are running on exome data you need to prodive the `--exome` flag so that the right verison of the model will be used.

```bash
nextflow run nf-core/deepvariant --genome hg19 --bam_folder myBamFolder --bed myBedFile --exome
```

## Job Resources

### Automatic resubmission

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

### Custom resource requests

Wherever process-specific requirements are set in the pipeline, the default value can be changed by creating a custom config file. See the files in [`conf`](../conf) for examples.

## AWS Batch specific parameters

Running the pipeline on AWS Batch requires a couple of specific parameters to be set according to your AWS Batch configuration. Please use the `-awsbatch` profile and then specify all of the following parameters.

### `--awsqueue`

The JobQueue that you intend to use on AWS Batch.

### `--awsregion`

The AWS region to run your job in. Default is set to `eu-west-1` but can be adjusted to your needs.

Please make sure to also set the `-w/--work-dir` and `--outdir` parameters to a S3 storage bucket of your choice - you'll get an error message notifying you if you didn't.

## Other command line parameters

### `--outdir`

The output directory where the results will be saved.

### `--email`

Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to speicfy this on the command line for every run.

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

Note - you can use this to override defaults. For example, you can specify a config file using `-c` that contains the following:

```nextflow
process.$multiqc.module = []
```

### `--max_memory`

Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'``

### `--max_time`
Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### `--max_cpus`

Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`

### `--plaintext_email`

Set to receive plain-text e-mails instead of HTML formatted.

### `--multiqc_config`
Specify a path to a custom MultiQC configuration file.

## Memory
DeepVariant is quite memory intensive. The most memory intensive process is `make_examples`. The memory requirement should be approximately 10-15x the size of your BAM file. For example, for a 5GB BAM file the memory should be set to 50GB. Fortunately this is set automaticaally for you in `base.config` for all of the man deepvariant processes, so you don't need change anything more and can run the pipeline as normal.
