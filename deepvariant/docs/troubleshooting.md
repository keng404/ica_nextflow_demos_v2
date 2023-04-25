# nf-core/deepvariant: Troubleshooting

## Input files not found

If you are having trouble with the inputs for the tool its recommended that you read [about preprocessing](usage.md#about-preprocessing) and [BAM folder input](usage.md#--bam_folder)

## Data organization

The pipeline can't take a list of multiple input files - it takes a glob expression. If your input files are scattered in different paths then we recommend that you generate a directory with symlinked files. If running in paired end mode please make sure that your files are sensibly named so that they can be properly paired. See the previous point.

## Extra resources and getting help

If you still have an issue with running the pipeline then feel free to contact us.
Have a look at the [pipeline website](https://github.com/nf-core/deepvariant) to find out how.

If you have problems that are related to Nextflow and not our pipeline then check out the [Nextflow gitter channel](https://gitter.im/nextflow-io/nextflow) or the [google group](https://groups.google.com/forum/#!forum/nextflow).
