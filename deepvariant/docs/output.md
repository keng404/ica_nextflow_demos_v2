# nf-core/deepvariant: Output

This document describes the processes and output produced by the pipeline.

Main steps:

- preprocessing of fasta/reference files (fai, fastagz, gzfai & gzi)
  - These steps can be skipped if the the `--genome` options is used or the fai, fastagz, gzfai & gzi files are supplied.
- preprocessing of BAM files
  - Also can be skipped if BAM files contain necessary read group line
- make examples
  - Gets bam files and converts them to images ( named examples )
- call variants
  - Does the variant calling based on the ML trained model.
- post processing

  - Trasforms the variant calling output (tfrecord file) into a standard vcf file.

For further reading and documentation about deepvariant see [google/deepvariant](https://github.com/google/deepvariant)

## VCF

The output from DeepVariant is a variant call file or [vcf v4.2](https://samtools.github.io/hts-specs/VCFv4.2.pdf)

**Output directory: `results`** (by default)

- `pipeline_info`
  - produced by nextflow
- `{bamSampleName}.vcf`
  - output vcf file produced by deepvariant
