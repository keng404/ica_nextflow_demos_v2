# ICA nextflow demos

A collection of nextflow pipelines ported to Illumina Connected Analytics (ICA). This is a starting point for porting these pipelines.
You may find that the XML files may need to be edited and a longer discussion of the XML files can be found [here](https://github.com/keng404/nextflow-to-icav2-config/blob/main/XML.md)

The method used to port these pipelines can be found in this [repository](https://github.com/keng404/nextflow-to-icav2-config?tab=readme-ov-file#what-do-these-scripts-do).
This method at a high level reads in existing Nextflow pipelines and modifies configuratiion and pipeline files to make them more compatible with ICA.

What does this method do to existing Nextflow pipelines?
1) Parse configuration files and the Nextflow scripts (main.nf, workflows, subworkflows, modules) of a pipeline and update the configuration of the pipeline with pod directives to tell ICA what compute instance to run
  - Strips out parameters that ICA utilizes for workflow orchestration
  - Migrates manifest closure to ```conf/base.ica.config``` file
  - Ensures that docker is enabled
2) Adds ```workflow.onError``` (main.nf, workflows, subworkflows, modules) to aid troubleshooting
3) Modifies the processes that reference scripts and tools in the ```bin/``` directory of a pipeline's ```projectDir```, so that when ICA orchestrates your Nextflow pipeline, it can find and properly execute your pipeline process
4) Generates parameter XML file based on ```nextflow_schema.json, nextflow.config, conf/```
`- Take a look at [this](https://github.com/keng404/nextflow-to-icav2-config/blob/main/XML.md) to understand a bit more of what's done with the XML, as you may want to make further edits to this file for better usability
5) Additional edits to ensure your pipeline runs more smoothly on ICA

Metadata on which pipelines and what versions were ported are found in [this JSON](https://github.com/keng404/ica_nextflow_demos_v2/blob/main/nf-core.ica_conversion.metadata.json)

It is best to use the ICA CLI to run these ported pipeline versions on ICA, there are [instructions](https://github.com/keng404/nextflow-to-icav2-config#prerequitsites) that will point to Illumina documentation (https://help.ica.illumina.com/). A 'CLI_Starter' Guide can be found [here](https://github.com/keng404/ica_nextflow_demos_v2/blob/main/CLI.md)

## Plug-and-Play

Using the XML files found within this repo, along with any file with the name ```*.pipeline.cli_template.json``` gives some boiler plate settings that can be used launch pipeline runs after using the script to [create a pipeline in ICA](https://github.com/keng404/nextflow-to-icav2-config#step-6-to-create-a-pipeline-in-ica-you-can-use-the-following-helper-script-nf-corecreate_ica_pipeliner) and using the JSON file and the  ```--template-json {path/to/*.pipeline.cli_template.json}``` with the command referenced [here](https://github.com/keng404/nextflow-to-icav2-config#how-to-run-a-pipeline-in--ica-via-cli)

This is not an official Illumina product, but is intended to make your nextflow experience in ICA more fruitful. See below for more details

## Known issues
1) In some cases when running these pipelines on ICA you will get a Groovy compilation error that suggests a syntax error in a nextflow config (```nextflow.ica.config``` or ```conf/base.ica.config```). You may need to manually update these files. This has to do with the parsing that is carried out by the [conversion code here](https://github.com/keng404/nextflow-to-icav2-config)

Typically you will see errors in your configuration file in the repos above, if your configuration file has multi-line expressions associated to a parameter or a 'complex' expression, for example:
```bash
  // Input data for full size test
  input_paths = [
    ['cage 1', 'https://github.com/nf-core/test-datasets/raw/cageseq/testdata/cage1.fastq.gz'],
    ['cage 2', 'https://github.com/nf-core/test-datasets/raw/cageseq/testdata/cage2.fastq.gz']
  ]
```
2) 'stub' in a process within your workflow may throw an error. Deleting the stub will not impact any pipeline functionality.

Your process may look like this:

```bash
process MY_AWESOME_PROCESS{
container 'my_tool/my_container_reference'
publishDir 'out'

input:
val x
path y

output:
path "my_newfile.txt" , emit: my_outputs

script:
"""
print ${x} > my_newfile.txt
print ${y} >> my_newfile.txt
"""
// you can delete everything from 'stub:' until the "}"
stub:
"""
print ${x} > my_newfile.txt
print ${y} >> my_newfile.txt
"""
}
```
3) If your pipeline run or pipeline uses any data from an external source (i.e. http/ftp server), note that by current convention, 
only port 80 and port 443 are exposed on ICA when running a pipeline. 

An example of what this error may look like in your pipeline run log:
```bash
curl: (28) Failed to connect to ftp.sra.ebi.ac.uk port 21 after 131117 ms: Connection timed out
Warning: Problem : timeout. Will retry in 4 seconds. 3 retries left.
```

See the ['Network Settings'](https://help.ica.illumina.com/reference/r-networksettings) portion of the ICA documentation].

As a result, you may run into issues downloading/staging data for your pipeline run.
One option to overcome this is to download and upload this data to ICA and reconfigure your pipeline to point to this new source.

If this is SRA data, you may have luck trying the [following pipeline](https://github.com/keng404/ica_nextflow_demos/tree/master/sra_download_pipeline) or incorporating this pipeline into your pipeline of interest.

## Docker troubleshooting

4) You may see errors when you run your pipeline in ICA that requires you to troubleshoot a docker image of interest. This investigation will look into if the user ICA runs your docker image as leads to libraries/modules not being properly loaded. To 'closely' replicate the docker run command on ICA, try the following ```docker run``` command that will mimic the 1000:1000 gid:uid that is run on ICA:
   ```bash
   docker run -itv `pwd`:`pwd` -e HOME=`pwd` -u 1000:1000 {DOCKER_IMAGE_OF_INTEREST} /bin/bash
   ```

# Current testing results

## succeded on test data set
- airrflow
- atacseq
- chipseq
- circdna
- eager
- epitopeprediction
- funcscan
- hlatyping
- isoseq
- mag
- methylseq
- oncoanalyser
- rnaseq
- sarek
- smrnaseq
- scrnaseq --- multiqc process has been commented out.
- viralrecon

## ran several processes with some issues with test dataset 
- ampliseq
- clipseq
- crisprseq
- demultiplex
- fetchngs
- pgdb
- proteinfold
