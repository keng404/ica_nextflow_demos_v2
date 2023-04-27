# ICA data management concepts
# General

- ICA is project-centric
  - Each project has data, pipelines, and analyses associated to a project   
- In order to enter project context / provide `--project-id`
- Also provide `{data_id}`, `{analysis_id}`, `{pipeline_id}`
  - `{data_id}` alphanumderic strings (fil.* or fol.*)
  - `{analysis_id}` alphanumeric strings
  - `{pipeline_id}` alphanumeric strings

## copy/upload

- CLI
  - `icav2 projectdata upload`
- API
  - [Create upload URL endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/createUploadUrlForData)

## delete

- CLI
  - `icav2 projectdata delete`
- API
  - [Delete Data endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/deleteData)
## link

- CLI
  -`icav2 projectdata link`
- API 
  - [Link Data Endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/linkDataToProject)

## unlink
- CLI 
  - `icav2 projectdata unlink`
- API 
  - [Unlink Data Endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/unlinkDataFromProject)

## move/rename
- 1) create data
  - [Create Data Endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/createDataInProject)
  - ```request body template
      {
        "name": "string",
        "folderPath": "string",
        "dataType": "FILE"
      } 
- 2) get temporary credentials
  - [get AWS temp creds endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/createTemporaryCredentialsForData)
- 3) rclone/aws cli to perform upload

## archive
- CLI
  - `icav2 projectdata archive`
- API 
  - [Archive Data Endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/archiveData)

## unarchive
- CLI
  - `icav2 projectdata unarchive`
- API
  - [Unarchive Data Endpoint](https://ica.illumina.com/ica/api/swagger/index.html#/Project%20Data/unarchiveData)


# pipeline

## launch pipeline run
Check out this [short guide](https://github.com/keng404/ica_nextflow_demos/blob/master/cli_demo.md)

## create new pipeline

## monitor/troubleshoot pipeline run
These scripts can also be of help (https://github.com/keng404/monitor_ica_analysis_run)
