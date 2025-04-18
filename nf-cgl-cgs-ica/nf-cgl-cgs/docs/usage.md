# Clinical-Genomics-Laboratory/nf-cgl-cgs: Usage

Table of contents:

- [Clinical-Genomics-Laboratory/nf-cgl-cgs: Usage](#clinical-genomics-laboratorynf-cgl-cgs-usage)
  - [Setup](#setup)
  - [Input parameters](#input-parameters)
    - [LSF cluster parameters](#lsf-cluster-parameters)
    - [DRAGEN parameters](#dragen-parameters)
    - [Start by demultiplexing samples](#start-by-demultiplexing-samples)
    - [Start from FastQ list](#start-from-fastq-list)
    - [Batch joint genotyping](#batch-joint-genotyping)
    - [Save QC metrics in different location](#save-qc-metrics-in-different-location)
    - [Transfer data to AWS S3](#transfer-data-to-aws-s3)
  - [Running the pipeline](#running-the-pipeline)
  - [Core Nextflow arguments](#core-nextflow-arguments)
    - [`-profile`](#-profile)
    - [`-resume`](#-resume)
    - [`-c`](#-c)
  - [Custom configuration](#custom-configuration)
    - [Resource requests](#resource-requests)
    - [Custom containers](#custom-containers)
    - [Custom tool arguments](#custom-tool-arguments)
    - [Running in the background](#running-in-the-background)
    - [Nextflow memory requirements](#nextflow-memory-requirements)

## Setup

### Optional: AWS

To utilize this pipeline with AWS, the use of Nextflow secrets are required. Below are instructions on setting Nextflow secrets:

1. Store credentials using [Nextflow's secrets feature](https://www.nextflow.io/docs/latest/secrets.html).
2. Set environmental variable `NXF_ENABLE_SECRETS` to an appropriate value.

Here is an example of how to store a Nextflow secret (replace <KEY> with your key):

```bash
nextflow secrets set GNX_ACCESS_KEY <KEY>
```

#### AWS: Data transfers

| Secret         | Description                                                                              |
| -------------- | ---------------------------------------------------------------------------------------- |
| GNX_DATA       | The first directory in the AWS S3 bucket to save files to (ex. `s3://bucket/<GNX_DATA>`) |
| GNX_BUCKET     | Name of AWS S3 bucket                                                                    |
| GNX_REGION     | AWS S3 region                                                                            |
| GNX_ACCESS_KEY | Genoox AWS S3 access key                                                                 |
| GNX_SECRET_KEY | Genoox AWS S3 secret key                                                                 |

#### AWS: Compute

> [!NOTE]
> The following Nextflow secrets are only required if using Compute on AWS.

| Secret         | Description            |
| -------------- | ---------------------- |
| AWS_ACCESS_KEY | AWS Compute access key |
| AWS_SECRET_KEY | AWS Compute secret key |

#### AWS: DRAGEN

> [!NOTE]
> The following Nextflow secrets are only required if using the Illumina DRAGEN on AWS.

| Secret              | Description                                 |
| ------------------- | ------------------------------------------- |
| AWS_DRAGEN_USER     | Username to access Illumina's DRAGEN on AWS |
| AWS_DRAGEN_PASSWORD | Password to access Illumina's DRAGEN on AWS |

## Input parameters

### LSF cluster parameters

The LSF HPC cluster requires additional parameters when submitting jobs. Default parameters are used, but may need to be modified on a per user basis.

#### LSF queue selection

Specify the queue to submit all non-DRAGEN jobs to on the LSF HPC. The default queue is `pathology`.

```bash
--queue '[queue]'
```

#### LSF user group selection

Specify the user group to use when submitting jobs to the LSF HPC. The default user group is `compute-duncavagee`.

```bash
--user_group '[user group]'
```

#### LSF job group name

Specify the job group name to use when submitting jobs to the LSF HPC.

```bash
--job_group_name '[job group name]'
```

### DRAGEN parameters

The DRAGEN alignment process requires several reference parameters to properly align and map samples.

#### Generate gVCF during alignment

The DRAGEN can output variant calls in VCF or gVCF format. By default, gVCF files will be generated. To generate VCF files, set the following parameter to `false`.

```bash
--create_gvcf true
```

#### Trimming of adapter sequences

The DRAGEN can trim adapter sequences on paired-end reads. Specify the location of adapter sequences for Read 1 and Read 2.

```bash
--adapter1 '[path to Read 1 adapter sequences]' \
--adapter2 '[path to Read 2 adapter sequences]'
```

#### Cross-sample contamination

The DRAGEN has a cross-contamination module that is able to estimate the fraction of reads in a sample that may be from another human source. Specify the location of the sample cross contamination VCF file.

```bash
--qc_cross_contamination '[path to cross contamination VCF file]'
```

#### Coverage report over custom region

The DRAGEN can generate a coverage report over a custom region. Specify the location of a BED file.

```bash
--qc_coverage_region  '[path to BED file]'
```

#### dbSNP annotation

Variant calls are annotated using the dbSNP database. Specify the location to the dbSNP VCF file.

```bash
--dbsnp '[path to dbSNP VCF file]'
```

### Start by demultiplexing samples

To demultiplex samples, the demultiplexing parameter must be turned on and the location of the Illumina run directory and MGI samplesheet must be provided.

#### Illumina run directory

The Illumina run directory that contains base call information of samples that need demultiplexing has to be specified. Use the following parameter to specify its location:

```bash
--illumina_rundir '[path to Illumina run directory]'
```

#### MGI samplesheet

An Excel (.xlsx) samplesheet with information about the samples that needs to be demuliplexed must be created before running this pipeline. Use the following parameter to specify its location:

```bash
--input '[path to samplesheet file]'
```

##### MGI samplesheet example

```excel title="samplesheet.xlsx"
Run Directory: /path/to/run/directory
Lane    Flowcell ID    Content_Desc    Index    Exceptions
2       ABC123         Sample_1        AAG-ACC
2       ABC123         Sample_2        AGC-GAG
```

| Column          | Description                                                                         |
| --------------- | ----------------------------------------------------------------------------------- |
| `Run Directory` | The path to the Illumina run directory.                                             |
| `Lane`          | The lane number used on the instrument for each sample.                             |
| `Flowcell ID`   | The ID of the flowcell used.                                                        |
| `Content_Desc`  | The name of the sample.                                                             |
| `Index`         | The indexes used during library prep, and should be in the format of Index1-Index2. |
| `Exceptions`    | Note any exceptions for each sample.                                                |

### Start from FastQ list

Optionally, the pipeline can run from demultiplexed FastQ files using the `fastq_list.csv` file produced during demultiplexing. Use the following parameter to specify its location:

```bash
--fastq_list '[path to fastq_list.csv file]'
```

#### FastQ list example

```csv title="fastq_list.csv"
RGID,RGSM,RGLB,Lane,Read1File,Read2File
AAG-ACC.2,Sample_1,UnknownLibrary,2,/path/to/Sample_1_R1.fastq.gz,/path/to/Sample_1_R2.fastq.gz
AGC-CAG.2,Sample_2,UnknownLibrary,2,/path/to/Sample_2_R1.fastq.gz,/path/to/Sample_2_R2.fastq.gz
```

| Column      | Description                              |
| ----------- | ---------------------------------------- |
| `RGID`      | The read group for the sample.           |
| `RGSM`      | Sample ID                                |
| `RGLB`      | Library information                      |
| `Lane`      | The flowcell lane number.                |
| `Read1File` | Full path to the first FastQ read file.  |
| `Read2File` | Full path to the second FastQ read file. |

### Batch joint genotyping

Batch joint genotyping can be performed on all samples after alignment to reduce the noise in the final VCF files. The following types of joint genotyping can be performed: small variants (SNV/InDels), structural variants (SV), and/or copy number variants (CNV). By default, joint genotyping of small variants is turned on.

Use the following parameters to turn on or off joint genotyping:

```bash
--joint_genotype_sv false
--joint_genotype_cnv false
--joint_genotype_small_variants true
```

### Save QC metrics in different location

During the alignment and mapping of each sample, various QC metrics are produced. These files are saved in the specified `--outdir` location under the directory `QC_metrics`.

To save the QC metrics in another location, specify the location using the following parameter:

```bash
--qc_outdir '[path to directory]'
```

### Transfer data to AWS S3

> [!NOTE]
> This requires Nextflow secrets to be set. For more information, see the [AWS: Data transfers](#aws-data-transfers) section.

After the analysis is complete, the specified files can be synchronized to an AWS S3 bucket. This option is enabled by default, but can be configured by using the following parameter:

```bash
--transfer_data true
```

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run \
  Clinical-Genomics-Laboratory/nf-cgl-cgs \
  -r v1.0.0 \
  -profile docker \
  --input ./samplesheet.xlsx \
  --outdir ./results
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run Clinical-Genomics-Laboratory/nf-cgl-cgs -profile docker -params-file params.yaml
```

with `params.yaml` containing:

```yaml
input: './samplesheet.csv'
outdir: './results/'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull Clinical-Genomics-Laboratory/nf-cgl-cgs
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [Clinical-Genomics-Laboratory/nf-cgl-cgs releases page](https://github.com/Clinical-Genomics-Laboratory/nf-cgl-cgs/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom tool arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Azure resource requests

To be used with the `azurebatch` profile by specifying the `-profile azurebatch`.
We recommend providing a compute `params.vm_type` of `Standard_D16_v3` VMs by default but these options can be changed if required.

Note that the choice of VM size depends on your quota and the overall workload during the analysis.
For a thorough list, please refer the [Azure Sizes for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
