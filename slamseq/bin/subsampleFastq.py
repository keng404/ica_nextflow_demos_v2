#!/usr/bin/env python

# Copyright (c) 2020 Tobias Neumann

from __future__ import print_function
import sys

import Bio
import Bio.SeqIO
from Bio.Seq import Seq

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter, SUPPRESS

 # Info
usage = "Subsample fastq file"
version = "1.0"

# Main Parsers
parser = ArgumentParser(description=usage)

parser.add_argument("-f", "--fastq", type=str, required=True, dest="fastqFile", help="Fastq")
parser.add_argument("-i", "--ids", type=str, required=True, dest="idsFile", help="File with read IDs")

args = parser.parse_args()

readIds = list()

with open(args.idsFile,'r') as f:
    for line in f:
        id = line.rstrip()
        readIds.append(id)

for record in Bio.SeqIO.parse(args.fastqFile, 'fastq'):
    readName = str(record.id)
    if readName in readIds:
        Bio.SeqIO.write(record, sys.stdout, 'fastq')
