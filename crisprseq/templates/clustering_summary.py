#!/usr/bin/env python

import gzip
import sys

from Bio import SeqIO

with gzip.open("$reads", "rt") as handle:
    clusters_count = len(list(SeqIO.parse(handle, "fastq")))

with open("$summary", "r") as summary:
    summary_lines = summary.readlines()

add_line = True
with open("$summary", "w") as output_file:
    for line in summary_lines:
        if "clustered-reads" not in line:
            output_file.write(line)
        else:
            output_file.write(f"clustered-reads, {clusters_count}\\n")
            add_line = False
    if add_line:
        output_file.write(f"clustered-reads, {clusters_count}\\n")
