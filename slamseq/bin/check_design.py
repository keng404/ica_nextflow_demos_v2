#!/usr/bin/env python

#######################################################################
#######################################################################
## Skeleton copied on March 25, 2020 from nf-core/atacseq
#######################################################################
#######################################################################

from __future__ import print_function

import os
import sys
import requests
import argparse

############################################
############################################
## FUNCTIONS
############################################
############################################

def file_base_name(file_name):
    if '.' in file_name:
        separator_index = file_name.index('.')
        base_name = file_name[:separator_index]
        return base_name
    else:
        return file_name

def path_base_name(path):
    file_name = os.path.basename(path)
    return file_base_name(file_name)

############################################
############################################
## PARSE ARGUMENTS
############################################
############################################

Description = 'Reformat nfcore/slamseq design file and check its contents.'
Epilog = "Example usage: python check_design.py <DESIGN_FILE_IN> <DESIGN_FILE_OUT>"

argParser = argparse.ArgumentParser(description=Description, epilog=Epilog)

## REQUIRED PARAMETERS
argParser.add_argument('DESIGN_FILE_IN', help="Input design file.")
argParser.add_argument('DESIGN_FILE_OUT', help="Output design file.")
args = argParser.parse_args()

############################################
############################################
## MAIN FUNCTION
############################################
############################################

ERROR_STR = 'ERROR: Please check design file'

HEADER = ['group', 'condition', 'control', 'reads']
EXTHEADER = ['group', 'condition', 'control', 'reads','name','type','time']

fout = open(args.DESIGN_FILE_OUT,'w')

with open(args.DESIGN_FILE_IN, 'r') as f:
    header = next(f)

    header = header.rstrip().split("\t")

    if header != HEADER and header != EXTHEADER:
        print("{} header: {} != {}".format(ERROR_STR,','.join(header),','.join(HEADER)))
        sys.exit(1)

    fout.write("\t".join(EXTHEADER) + "\n")

    regularDesign = False

    if len(header) == 7:
        regularDesign = True

    for line in f:
        fields = line.rstrip().split("\t")
        group = fields[0]
        condition = fields[1]
        control = fields[2]
        reads = fields[3]

        if regularDesign and len(fields) == 7:
            name = fields[4]
            type = fields[5]
            time = fields[6]
        else :
            name = ""
            type = ""
            time = ""

        if name == "":
            name = path_base_name(reads)
        if type == "":
            type = "pulse"
        if time == "":
            time = "0"

        if type != "pulse" and type != "chase":
            print("{} type needs to be either 'pulse' or 'chase'!\nLine: '{}'".format(ERROR_STR,line.strip()))
            sys.exit(1)

        if control != "0" and control != "1":
            print("{} control needs to be either '0' or '1'!\nLine: '{}'".format(ERROR_STR,line.strip()))
            sys.exit(1)

        ## CHECK REPLICATE COLUMN IS INTEGER
        if not time.isdigit():
            print("{}: Time needs to be an integer!\nLine: '{}'".format(ERROR_STR,line.strip()))
            sys.exit(1)

        if reads[-9:] != '.fastq.gz' and reads[-6:] != '.fq.gz':
            print("{}: Reads FastQ file has incorrect extension (has to be '.fastq.gz' or 'fq.gz') - {}\nLine: '{}'".format(ERROR_STR,fastq,line.strip()))
            sys.exit(1)

        fout.write("\t".join([group, condition, control, reads, name, type, time]) + "\n")

fout.close()
