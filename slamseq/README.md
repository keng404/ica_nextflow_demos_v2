# ![nf-core/slamseq](docs/images/nf-core-slamseq_logo.png)

[![GitHub Actions CI Status](https://github.com/nf-core/slamseq/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/slamseq/actions)
[![GitHub Actions Linting Status](https://github.com/nf-core/slamseq/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/slamseq/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.10.0-brightgreen.svg)](https://www.nextflow.io/)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nfcore/slamseq.svg)](https://hub.docker.com/r/nfcore/slamseq)

## Introduction

**nf-core/slamseq** is a bioinformatics analysis pipeline used for [SLAMSeq](https://doi.org/10.1038/nmeth.4435) sequencing data.

The workflow processes SLAMSeq datasets using [Slamdunk](https://doi.org/10.1186/s12859-019-2849-7) and infers [direct transcriptional targets](https://doi.org/10.1126/science.aao2793) using [DESeq2](https://doi.org/10.1186/s13059-014-0550-8).

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

i. Install [`nextflow`](https://nf-co.re/usage/installation)

ii. Install either [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility (please only use [`Conda`](https://conda.io/miniconda.html) as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))

iii. Download the pipeline and test it on a minimal dataset with a single command

```bash
nextflow run nf-core/slamseq -profile test,<docker/singularity/conda/institute>
```

> Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.

iv. Start running your own analysis!

```bash
nextflow run nf-core/slamseq -profile <docker/singularity/conda/institute> --input design.tsv --genome GRCh38
```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## Documentation

The nf-core/slamseq pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](https://nf-co.re/usage/installation)
2. Pipeline configuration
    * [Local installation](https://nf-co.re/usage/local_installation)
    * [Adding your own system config](https://nf-co.re/usage/adding_own_config)
    * [Reference genomes](https://nf-co.re/usage/reference_genomes)
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](https://nf-co.re/usage/troubleshooting)

## Credits

nf-core/slamseq was originally written by Tobias Neumann ([@t-neumann](https://github.com/t-neumann)) for the use at the [IMP Vienna](https://www.imp.ac.at/).

Many thanks to other who have helped out along the way too, including (but not limited to):
[@apeltzer](https://github.com/apeltzer),
[@drpatelh](https://github.com/drpatelh),
[@pditommaso](https://github.com/pditommaso),
[@maxulysse](https://github.com/MaxUlysse),
[@ewels](https://github.com/ewels),
[@zethson](https://github.com/Zethson),
[@bgruening](https://github.com/bgruening),
[@micans](https://github.com/micans).

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on [Slack](https://nfcore.slack.com/channels/slamseq) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citation

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi. -->
<!-- If you use  nf-core/slamseq for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

You can cite `slamdunk` as follows:

> **Quantification of experimentally induced nucleotide conversions in high-throughput sequencing datasets.**
>
> Tobias Neumann, Veronika A. Herzog, Matthias Muhar, Arndt von Haeseler, Johannes Zuber, Stefan L. Ameres & Philipp Rescheneder.
>
> _BMC Bioinformatics_ 2019 May 20. doi: [10.1186/s12859-019-2849-7](https://doi.org/10.1186/s12859-019-2849-7).

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).  
> ReadCube: [Full Access Link](https://rdcu.be/b1GjZ)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
