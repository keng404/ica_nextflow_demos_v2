# nf-core/deepvariant: Changelog

## v1.0 - 2018-11-19

This release marks the point where the pipeline was moved from lifebit-ai/DeepVariant over to the new nf-core community, at nf-core/DeepVariant. The [nf-core](http://nf-co.re/) template was used to help ensure that the pipeline meets the standards of nf-core.

In summary, the main changes are:

- Rebranding and renaming throughout the pipeline to nf-core
- Updating many parts of the pipeline config and style to meet nf-core standards
- Continuous integration tests with Travis CI
- Dependencies installed via conda
- Added support for BAM input as file, not just a folder
- Added channels to process input files
- Added separate processes for each of the steps in FASTA file preprocessing
- Use of genomes config to specify relevant reference genome files similar to igenomes
- Added BAM size dependent setting of memory
- Slightly improved documentation

...and many more minor tweaks.

Thanks to everyone who has worked on this release!
