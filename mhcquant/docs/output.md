# nf-core/mhcquant: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## General

### Quantification

<details markdown="1">
<summary>Output files</summary>

- `*.tsv` : If `--skip_quantification` is not specified.

</details>

The CSV output file is a table containing all information extracted from a database search throughout the pipeline. See the [OpenMS](https://www.openms.de/) or PSI documentation for more information about [annotated scores and format](https://abibuilder.informatik.uni-tuebingen.de/archive/openms/Documentation/release/latest/html/TOPP_TextExporter.html).

MAP contains information about the different mzML files that were provided initially

```bash
#MAP    id      filename        label   size
```

RUN contains information about the search that was performed on each run

```bash
#RUN    run_id  score_type      score_direction date_time       search_engine_version   parameters
```

PROTEIN contains information about the protein ids corresponding to the peptides that were detected (No protein inference was performed)

```bash
#PROTEIN        score   rank    accession       protein_description     coverage        sequence
```

UNASSIGNEDPEPTIDE contains information about PSMs that were identified but couldn't be quantified to a precursor feature on MS Level 1

```bash
#UNASSIGNEDPEPTIDE      rt      mz      score   rank    sequence        charge  aa_before       aa_after        score_type      search_identifier       accessions      FFId_category   feature_id      file_origin     map_index       spectrum_reference      COMET:IonFrac   COMET:deltCn    COMET:deltLCn   COMET:lnExpect  COMET:lnNumSP   COMET:lnRankSP  MS:1001491      MS:1001492      MS:1001493      MS:1002252      MS:1002253      MS:1002254      MS:1002255      MS:1002256      MS:1002257      MS:1002258      MS:1002259      num_matched_peptides    protein_references      target_decoy
```

CONSENSUS contains information about precursor features that were identified in multiple runs (eg. run 1-3 in this case)

```bash
#CONSENSUS      rt_cf   mz_cf   intensity_cf    charge_cf       width_cf        quality_cf      rt_0    mz_0    intensity_0     charge_0        width_0 rt_1    mz_1    intensity_1     charge_1        width_1 rt_2    mz_2    intensity_2     charge_2        width_2 rt_3    mz_3    intensity_3     charge_3        width_3
```

PEPTIDE contains information about peptide hits that were identified and correspond to the consensus features described below

```bash
#PEPTIDE        rt      mz      score   rank    sequence        charge  aa_before       aa_after        score_type      search_identifier       accessions      FFId_category   fea
```

### Intermediate results

<details markdown="1">
<summary>Output files</summary>

- `intermediate_results/`
  - `alignment`
    - `*filtered.idXML` : If `--skip_quantification` is not specified, then this file is generated in the `OPENMS_IDFILTER_Q_VALUE`
    - `{ID}_-_{filename}_filtered` : An outcome file of `OPENMS_IDFILTER_FOR_ALIGNMENT`, this file is only generated when `--skip_quantification` is not specified
  - `comet`
    - `{raw filename}.tsv` : The outcome of `CometAdapter` containing more detailed information about all of the hits that have been found (no filtering has been applied)
    - `{Sample}_{Condition}_{ID}.tsv` : Single files that hold information about the peptides sequences that have been identified (no filtering has been applied)
  - `features`
    - `*.mztab` : mztab file generated by the OpenMS MzTabExporter command which is present in the `PROCESS_FEATURE` step
    - `*.idXML` : Outcome of `PSMFEATUREEXTRACTOR`, containing the computations of extra features for each input PSM
    - `*.featureXML` : These files file is generated by the OpenMS `FeatureFinderIdentification` command
  - `ion_annotations`
    - `{Sample}_{Condition}_all_peaks.tsv`: Contains metadata of all measured ions of peptides reported after `OPENMS_IDFILTER_Q_VALUE`.
    - `{Sample}_{Condition}_matching_ions.tsv`: Contains ion annotations and additional metadata of peptides reported after `OPENMS_IDFILTER_Q_VALUE`.
  - `percolator`
    - `*all_ids_merged_psm_perc.idXML` : idXML files are generated with `OPENMS_PERCOLATORADAPTER`
  - `refined_fdr` (Only if `--refine_fdr_on_predicted_subset` is specified)
    - `*merged_psm_perc_filtered.mzTab` : This file export filtered percolator results (by q-value) as mztab
    - `*_all_ids_merged.mzTab` : Exportas all of the psm results as mztab
    - `*perc_subset.idXML` : This file is the outcome of a second OpenMS `PercolatorAdapter` run
    - `*pred_filtered.idXML` : Contains filtered PSMs prediction results by shrinked search space (outcome mhcflurry).
    - `{ID}_-_{filename}_filtered` : An outcome file of `OPENMS_IDFILTER_REFINED`

</details>

This folder contains the intermediate results from various steps of the MHCquant pipeline (e.g. (un)filtered PSMs, aligned mzMLs, features)

The output mzTab contains many columns annotating the most important information - here are a few outpointed:

```bash
PEP   sequence   accession   best_search_engine_score[1]   retention_time   charge   mass_to_charge   peptide_abundance_study_variable[1]
```

Most important to know is that in this format we annotated the q-value of each peptide identification in the `best_search_engine_score[1]` column and peptide quantities in the peptide_abundance_study_variable` columns.
[mzTab](http://www.psidev.info/mztab) is a light-weight format to report mass spectrometry search results. It provides all important information about identified peptide hits and is compatible with the PRIDE Archive - proteomics data repository.

## VCF

### Reference fasta

<details markdown="1">
<summary>Output files</summary>

- `*_vcf.fasta`: If `--include_proteins_from_vcf` is specified, then this fasta is created for the respective sample

</details>
The fasta database including mutated proteins used for the database search

### Neoepitopes

These CSV files list all of the theoretically possible neoepitope sequences from the variants specified in the vcf and neoepitopes that are found during the mass spectrometry search, independant of binding predictions, respectively

#### Found neoepitopes

<details markdown="1">
<summary>Output files</summary>

- `class_1_bindings/`
  - `*found_neoepitopes_class1.csv`: Generated when `--include_proteins_from_vcf` and `--predict_class_1` are specified
- `class_2_bindings/`
  - `*found_neoepitopes_class2.csv`: Generated when `--include_proteins_from_vcf` and `--predict_class_2` are specified

</details>

This CSV lists all neoepitopes that are found during the mass spectrometry search, independant of binding predictions.
The format is as follows:

```bash
peptide sequence   geneID
```

#### vcf_neoepitopes

<details markdown="1">
<summary>Output files</summary>

- `class_1_bindings/`
  - `*vcf_neoepitopes_class1.csv`: Generated when `--include_proteins_from_vcf` and `--predict_class_1` are specified
- `class_2_bindings/`
  - `*vcf_neoepitopes_class2.csv`: Generated when `--include_proteins_from_vcf` and `--predict_class_2` are specified

</details>

This CSV file contains all theoretically possible neoepitope sequences from the variants that were specified in the vcf.
The format is shown below

```bash
Sequence        Antigen ID       Variants
```

## Class prediction

### Class (1|2) bindings

<details markdown="1">
<summary>Output files</summary>

- `class_1_bindings/`
  - `*predicted_peptides_class_1.csv`: If `--predict_class_1` is specified, then this CSV is generated
- `class_2_bindings/`
  - `*predicted_peptides_class_2.csv`: If `--predict_class_2` is specified, then this CSV is generated

</details>

This folder contains the binding predictions of all detected class 1 or 2 peptides and all theoretically possible neoepitope sequences
The prediction outputs are comma-separated table (CSV) for each allele, listing each peptide sequence and its corresponding predicted affinity scores:

```bash
peptide   allele   prediction   prediction_low   prediction_high   prediction_percentile
```

## Retention time prediction

<details markdown="1">
<summary>Output files</summary>

- `RT_prediction`
  - `*id_RTpredicted.csv`: If `--predict_RT` is specified, the retention time found peptides are provided
  - `*txt_RTpredicted.csv`: If `--predict_RT` is specified, the retention time predicted neoepitopes are provided

</details>

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.html`.
  - Reports generated by the pipeline: `software_versions.yml`.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
