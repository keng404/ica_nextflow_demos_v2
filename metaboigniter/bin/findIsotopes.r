#!/usr/bin/env Rscript
options(stringAsfactors = FALSE, useFancyQuotes = FALSE)
# This script is used to do isotope detection using CAMERA
# Taking the command line arguments
args <- commandArgs(trailingOnly = TRUE)

if(length(args)==0)stop("No file has been specified! Please select a file for performing findIsotopes!\n")
require(xcms)
require(CAMERA)
previousEnv<-NA
output<-NA
maxcharge<-3
for(arg in args)
{
  argCase<-strsplit(x = arg,split = "=")[[1]][1]
  value<-strsplit(x = arg,split = "=")[[1]][2]
  if(argCase=="input")
  {
    previousEnv=as.character(value)
  }
  if(argCase=="maxcharge")
  {
    maxcharge=as.numeric(value)
  }
  if(argCase=="output")
  {
    output=as.character(value)
  }

}
if(is.na(previousEnv) | is.na(output)) stop("Both input and output need to be specified!\n")

load(file = previousEnv)

toIsoCharac<-get(varNameForNextStep)

xcmsSetIsoCharac<-findIsotopes(toIsoCharac,maxcharge = maxcharge)

preprocessingSteps<-c(preprocessingSteps,"findIsotopes")

varNameForNextStep<-as.character("xcmsSetIsoCharac")
save(list = c("xcmsSetIsoCharac","preprocessingSteps","varNameForNextStep"),file = output)
