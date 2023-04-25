process DEXSEQ {
    label "process_medium"
    container "docker.io/yuukiiwa/nanoseq:dexseq"
    // need a multitool container for r-base, dexseq, stager, drimseq and on quay hub
    input:
    path counts
    output:
    path "*.txt"                , emit: dexseq_txt
    path "versions.yml"         , emit: versions
    script:
    """
    Rscript ${workflow.launchDir}/bin/run_dexseq.r $params.quantification_method $counts
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        bioconductor-dexseq:  \$(Rscript -e "library(DEXSeq); cat(as.character(packageVersion('DEXSeq')))")
        bioconductor-drimseq: \$(Rscript -e "library(DRIMSeq); cat(as.character(packageVersion('DRIMSeq')))")
        bioconductor-stager:  \$(Rscript -e "library(stageR); cat(as.character(packageVersion('stageR')))")
    END_VERSIONS
    """
}
