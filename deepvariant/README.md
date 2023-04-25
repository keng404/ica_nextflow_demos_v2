![deepvariant](https://raw.githubusercontent.com/nf-core/deepvariant/master/docs/images/deepvariant_logo.png)

# nf-core/deepvariant

**Deep Variant as a Nextflow pipeline**

[![Build Status](https://travis-ci.org/nf-core/deepvariant.svg?branch=master)](https://travis-ci.org/nf-core/deepvariant)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A518.10.1-brightgreen.svg)](https://www.nextflow.io/)
[![Gitter](https://img.shields.io/badge/gitter-%20join%20chat%20%E2%86%92-4fb99a.svg)](https://gitter.im/nf-core/Lobby)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nfcore/deepvariant.svg)](https://hub.docker.com/r/nfcore/deepvariant)
![Singularity Container available](https://img.shields.io/badge/singularity-available-7E4C74.svg)

A Nextflow pipeline for running the [Google DeepVariant variant caller](https://github.com/google/deepvariant).

## What is DeepVariant and why in Nextflow?

The Google Brain Team in December 2017 released a [Variant Caller](https://www.ebi.ac.uk/training/online/course/human-genetic-variation-i-introduction/variant-identification-and-analysis/what-variant) based on DeepLearning: DeepVariant.

In practice, DeepVariant first builds images based on the BAM file, then it uses a DeepLearning image recognition approach to obtain the variants and eventually it converts the output of the prediction in the standard VCF format.

DeepVariant as a Nextflow pipeline provides several advantages to the users. It handles automatically, through **preprocessing steps**, the creation of some extra needed indexed and compressed files which are a necessary input for DeepVariant, and which should normally manually be produced by the users.
Variant Calling can be performed at the same time on **multiple BAM files** and thanks to the internal parallelization of Nextflow no resources are wasted.
Nextflow's support of Docker allows to produce the results in a computational reproducible and clean way by running every step inside of a **Docker container**.

For more detailed information about Google's DeepVariant please refer to [google/deepvariant](https://github.com/google/deepvariant) or this [blog post](https://research.googleblog.com/2017/12/deepvariant-highly-accurate-genomes.html). <br />
For more information about DeepVariant in Nextflow please refer to this [blog post](https://blog.lifebit.ai/post/deepvariant/?utm_campaign=documentation&utm_source=github&utm_medium=web)

## Quick Start

**Warning DeepVariant can be very computationally intensive to run.**

To **test** the pipeline you can run:

```bash
nextflow run nf-core/deepvariant -profile test,docker
```

A typical run on **whole genome data** looks like this:

```bash
nextflow run nf-core/deepvariant --genome hg19 --bam yourBamFile --bed yourBedFile -profile standard,docker
```

In this case variants are called on the bam files contained in the testdata directory. The hg19 version of the reference genome is used.
One vcf files is produced and can be found in the folder "results"

A typical run on **whole exome data** looks like this:

```bash
nextflow run nf-core/deepvariant --exome --genome hg19 --bam_folder myBamFolder --bed myBedFile -profile standard,docker
```

## Documentation

The nf-core/deepvariant documentation is split into the following files:

1. [Installation](docs/installation.md)
2. [Running the pipeline](docs/usage.md)
3. Pipeline configuration
   - [Adding your own system](docs/configuration/adding_your_own.md)
   - [Reference genomes](docs/configuration/reference_genomes.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](docs/troubleshooting.md)
6. [More about DeepVariant](docs/about.md)

## More about the pipeline

As shown in the following picture, the worklow both contains **preprocessing steps** ( light blue ones ) and proper **variant calling steps** ( darker blue ones ).

Some input files ar optional and if not given, they will be automatically created for the user during the preprocessing steps. If these are given, the preprocessing steps are skipped. For more information about preprocessing, please refer to the "INPUT PARAMETERS" section.

The worklow **accepts one reference genome and multiple BAM files as input**. The variant calling for the several input BAM files will be processed completely indipendently and will produce indipendent VCF result files. The advantage of this approach is that the variant calling of the different BAM files can be parallelized internally by Nextflow and take advantage of all the cores of the machine in order to get the results at the fastest.

<p align="center">
  <img src="https://github.com/nf-core/deepvariant/blob/master/pics/pic_workflow.jpg">
</p>

## Credits

This pipeline was originally developed at [Lifebit](https://lifebit.ai/?utm_campaign=documentation&utm_source=github&utm_medium=web), by @luisas, to ease and reduce cost for variant calling analyses

Many thanks to nf-core and those who have helped out along the way too, including (but not limited to): @ewels, @MaxUlysse, @apeltzer, @sven1103 & @pditommaso
