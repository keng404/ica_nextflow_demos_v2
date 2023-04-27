# ICA data management concepts
# General

- ICA is project-centric
- Enter project context / provide `--project-id`
- Also provide `{data_id}`
  - alphanumderic strings (fil.* or fol.*)
    
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

## create new pipeline

## monitor pipeline run
