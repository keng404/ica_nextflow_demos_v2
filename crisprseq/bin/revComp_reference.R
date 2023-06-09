#!/usr/bin/env Rscript

############################
#### author: Marta Sanvicente
#### Released under the MIT license. See git repository (https://github.com/nf-core/crisprseq) for full license text.
####
#### Orient a reference sequence according to reads orientation.
############################

args = commandArgs(trailingOnly=TRUE)

library(ShortRead)
library(seqinr)
library(Biostrings)

strComp=function(X){
    return(c2s(rev(comp(s2c(X)))))
}

ref_fasta <- args[1]
ref_out <- args[2]
gR <- args[3]

ref <- read.fasta(ref_fasta, as.string = TRUE)

rvComp_seq <- strComp(ref[[1]][1])

align <- pairwiseAlignment(toupper(gR), toupper(ref[[1]][1]), type="global-local")
alignRevComp <- pairwiseAlignment(toupper(gR), toupper(rvComp_seq), type="global-local")

if (score(align) > score(alignRevComp)){
    write.fasta(names = names(ref), sequences = ref[[1]][1], file.out=ref_out)
} else {
    write.fasta(names = names(ref), sequences = rvComp_seq, file.out=ref_out)
}
