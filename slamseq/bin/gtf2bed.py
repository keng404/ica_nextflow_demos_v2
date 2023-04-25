#!/usr/bin/env python

# MIT License
#
# Copyright (c) Tobias Neumann, 2019
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Convert gtf file to 3'UTR bed file

from __future__ import print_function
import sys, os, re, tempfile

if len(sys.argv) != 2:
    print("Supply only one gtf file!",sys.stderr)
    sys.exit(-1)

gtfFile = sys.argv[1]

sources = dict()
entryDict = dict()

temp = tempfile.NamedTemporaryFile(delete=False, mode='w')

with open(gtfFile, 'r') as f:
    for line in f:
        chr, source, feature, start, end, score, strand, frame, attributes = line.rstrip().split('\t')
        attributeDict = dict()
        attributes = attributes.split(";")
        for attribute in attributes:
            attribute = re.sub("^\s*","",attribute)
            attribute = re.sub(r"\"","",attribute)
            if attribute != "":
                key, value = attribute.split(' ')
                attributeDict[key] = value
        if not attributeDict['transcript_id'] in entryDict:
            entryDict[attributeDict['transcript_id']] = list()
        entryDict[attributeDict['transcript_id']].append(line.rstrip())

        sources[source] = 0

for tx in entryDict:
    for entry in entryDict[tx]:
        print(entry, file=temp)

temp.close()

for annotationSource in sources:

    with open(temp.name, 'r') as f:
        geneToTx = dict()
        exon = dict()
        cds = dict()
        curTx = ""
        curGene = ""
        curStrand = ""
        txIter = 0
        curScore = "0"
        for line in f:
            chr, source, feature, start, end, score, strand, frame, attributes = line.rstrip().split('\t')

            if annotationSource != source:
                continue

            attributeDict = dict()
            attributes = attributes.split(";")
            for attribute in attributes:
                attribute = re.sub("^\s*","",attribute)
                attribute = re.sub(r"\"","",attribute)
                if attribute != "":
                    key, value = attribute.split(' ')
                    attributeDict[key] = value
            if curTx != attributeDict['transcript_id'] and curTx != "":

                cdsRank = cds.keys()
                exonRank = list(exon.keys())

                if len(cdsRank) == 0:
                    if (curStrand == "+") :
                        lastExon = max(exonRank)
                        print(exon[lastExon]['chr'],end="\t")
                        print(str(exon[lastExon]['start'] - 1),end="\t")
                        print(str(exon[lastExon]['end']),end="\t")
                        print(curTx,end="\t")
                        print(curScore,end="\t")
                        print(curStrand)
                    else :
                        firstExon = min(exonRank)
                        print(exon[firstExon]['chr'],end="\t")
                        print(str(exon[firstExon]['start'] - 1),end="\t")
                        print(str(exon[firstExon]['end']),end="\t")
                        print(curTx,end="\t")
                        print(curScore,end="\t")
                        print(curStrand)
                else :

                    if curStrand == "+" :

                        lastCDS = max(cdsRank)
                        lastCDSIndexInExon = exonRank.index(lastCDS)
                        splitExon = cds[lastCDS]
                        print(splitExon['chr'],end="\t")
                        print(str(splitExon['end']),end="\t")
                        print(str(exon[lastCDS]['end']),end="\t")
                        print(curTx,end="\t")
                        print(".",end="\t")
                        print(curStrand)
                        lastCDSIndexInExon += 1
                        while(lastCDSIndexInExon < len(exonRank)) :
                            print(exon[lastCDSIndexInExon]['chr'],end="\t")
                            print(str(exon[lastCDSIndexInExon]['start'] - 1),end="\t")
                            print(str(exon[lastCDSIndexInExon]['end']),end="\t")
                            print(curTx,end="\t")
                            print(curScore,end="\t")
                            print(curStrand)
                            lastCDSIndexInExon += 1
                    else :
                        firstCDS = min(cdsRank)
                        firstCDSIndexInExon = exonRank.index(firstCDS)
                        splitExon = cds[firstCDS]
                        print(splitExon['chr'],end="\t")
                        print(str(exon[firstCDSIndexInExon]['start'] - 1),end="\t")
                        print(str(splitExon['start'] - 1),end="\t")
                        print(curTx,end="\t")
                        print(curScore,end="\t")
                        print(curStrand)

                        firstCDSIndexInExon -= 1

                        while(firstCDSIndexInExon >= 0) :
                            print(exon[firstCDSIndexInExon]['chr'],end="\t")
                            print(str(exon[firstCDSIndexInExon]['start'] - 1),end="\t")
                            print(str(exon[firstCDSIndexInExon]['end']),end="\t")
                            print(curTx,end="\t")
                            print(curScore,end="\t")
                            print(curStrand)
                            firstCDSIndexInExon -= 1

                cds = dict()
                exon = dict()
                txIter = 0

            curTx = attributeDict['transcript_id']
            curGene = attributeDict['gene_id']
            curStrand = strand
            curScore = score

            if feature == "exon" :
                exon[txIter] = dict()
                exon[txIter]['chr'] = chr
                exon[txIter]['start'] = int(start)
                exon[txIter]['end'] = int(end)
                txIter += 1

            elif feature == "CDS" :
                if txIter == 0:
                    cds[txIter] = dict()
                    cds[txIter]['chr'] = chr
                    cds[txIter]['start'] = int(start)
                    cds[txIter]['end'] = int(end)
                elif chr != exon[txIter - 1]['chr']:
                    cds[txIter] = dict()
                    cds[txIter]['chr'] = chr
                    cds[txIter]['start'] = int(start)
                    cds[txIter]['end'] = int(end)
                elif int(start) >= exon[txIter - 1]['start'] and int(end) <= exon[txIter - 1]['end']:
                    cds[txIter - 1] = dict()
                    cds[txIter - 1]['chr'] = chr
                    cds[txIter - 1]['start'] = int(start)
                    cds[txIter - 1]['end'] = int(end)
                elif int(start) != exon[txIter - 1]['start'] and int(end) != exon[txIter - 1]['end']:
                    cds[txIter] = dict()
                    cds[txIter]['chr'] = chr
                    cds[txIter]['start'] = int(start)
                    cds[txIter]['end'] = int(end)
                else :
                    cds[txIter - 1] = dict()
                    cds[txIter - 1]['chr'] = chr
                    cds[txIter - 1]['start'] = int(start)
                    cds[txIter - 1]['end'] = int(end)

    cdsRank = cds.keys()
    exonRank = exon.keys()

    if len(cdsRank) == 0:
        if (curStrand == "+") :
            lastExon = max(exonRank)
            print(exon[lastExon]['chr'],end="\t")
            print(str(exon[lastExon]['start'] - 1),end="\t")
            print(str(exon[lastExon]['end']),end="\t")
            print(curTx,end="\t")
            print(curScore,end="\t")
            print(curStrand)
        else :
            firstExon = min(exonRank)
            print(exon[firstExon]['chr'],end="\t")
            print(str(exon[firstExon]['start'] - 1),end="\t")
            print(str(exon[firstExon]['end']),end="\t")
            print(curTx,end="\t")
            print(curScore,end="\t")
            print(curStrand)
    else :

        if curStrand == "+" :

            lastCDS = max(cdsRank)
            lastCDSIndexInExon = exonRank.index(lastCDS)
            splitExon = cds[lastCDS]
            print(splitExon['chr'],end="\t")
            print(str(splitExon['end']),end="\t")
            print(str(exon[lastCDS]['end']),end="\t")
            print(curTx,end="\t")
            print(curScore,end="\t")
            print(curStrand)
            lastCDSIndexInExon += 1
            while(lastCDSIndexInExon < len(exonRank)) :
                print(exon[lastCDSIndexInExon]['chr'],end="\t")
                print(str(exon[lastCDSIndexInExon]['start'] - 1),end="\t")
                print(str(exon[lastCDSIndexInExon]['end']),end="\t")
                print(curTx,end="\t")
                print(".",end="\t")
                print(curStrand)
                lastCDSIndexInExon += 1
        else :
            firstCDS = min(cdsRank)
            firstCDSIndexInExon = exonRank.index(firstCDS)
            splitExon = cds[firstCDS]
            print(splitExon['chr'],end="\t")
            print(str(exon[firstCDSIndexInExon]['start'] - 1),end="\t")
            print(str(splitExon['start'] - 1),end="\t")
            print(curTx,end="\t")
            print(curScore,end="\t")
            print(curStrand)

            firstCDSIndexInExon -= 1

            while(firstCDSIndexInExon >= 0) :
                print(exon[firstCDSIndexInExon]['chr'],end="\t")
                print(str(exon[firstCDSIndexInExon]['start'] - 1),end="\t")
                print(str(exon[firstCDSIndexInExon]['end']),end="\t")
                print(curTx,end="\t")
                print(curScore,end="\t")
                print(curStrand)
                firstCDSIndexInExon -= 1

    cds = dict()
    exon = dict()
    txIter = 0
