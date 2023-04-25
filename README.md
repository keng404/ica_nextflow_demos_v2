# ICA nextflow demos

A collection of nextflow pipelines ported to Illumina Connected Analytics (ICA). This is a starting point for porting these pipelines 
You may find that the XML files may need to be edited and a longer discussion of the XML files can be found [here](https://github.com/keng404/nextflow-to-icav2-config/blob/main/XML.md)

This is not an official Illumina product, but is intended to make your nextflow experience in ICA more fruitful

## Known issues
1) In some cases when running these pipelines you will get a Groovy compilation error that suggests a syntax error in a nextflow config (```nextflow.ica.config``` or ```conf/base.ica.config```). You may need to manually update these files.
2) 'stubs' in you process of interest. Deleting the stub will not impact any pipeline functionality.
