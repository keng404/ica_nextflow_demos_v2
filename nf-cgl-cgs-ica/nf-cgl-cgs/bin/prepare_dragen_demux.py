#!/usr/bin/env python3

import argparse
import os
import csv
import sys
import pandas as pd
import xml.etree.ElementTree as ET

__version__ = "1.0.0"


def checkfile(file_path):
    """Check if a file exists at the given path."""
    if not os.path.exists(file_path):
        raise argparse.ArgumentTypeError(f"The file {file_path} does not exist.")
    return file_path


def fileexists(file_path):
    """Check if a file exists at the given path."""
    if os.path.exists(file_path):
        raise argparse.ArgumentTypeError(f"The outfile {file_path} exists!")
    return file_path


def reverse_complement(seq):
    # reverse complement the DNA sequence:
    return seq.translate(str.maketrans("ATCG", "TAGC"))[::-1]


def parse_runinfo(rundir):
    runinfo_path = os.path.join(rundir, "RunInfo.xml")
    # check if this path exists:
    if not os.path.exists(runinfo_path):
        raise ValueError("RunInfo.xml file not found in the specified directory")

    # locate the RunParameters.xml file and check if it exists:
    runparams_path = os.path.join(rundir, "RunParameters.xml")
    # check if this path exists:
    if not os.path.exists(runparams_path):
        raise ValueError("RunParameters.xml file not found in the specified directory")

    tree = ET.parse(runparams_path)
    root = tree.getroot()
    runinfo = {}
    runinfo["RunID"] = root.find("RunId").text

    # this checks for NovaSeq Xplus run parameters and obtains them
    plannedReads = root.findall(".//PlannedReads")
    if len(plannedReads) > 0:  # if >0 then we know its Xplus data
        for el in plannedReads[0].findall("Read"):
            runinfo[el.attrib["ReadName"] + "Cycles"] = int(el.attrib["Cycles"])

        runinfo["FlowCellType"] = root.find("FlowCellType").text
        runinfo["InstrumentType"] = root.find("InstrumentType").text
        runinfo["Instrument"] = root.find("InstrumentSerialNumber").text
        runinfo["Side"] = root.find("Side").text

        # fine the serial number of the flowcell:
        consumInfo = root.findall("ConsumableInfo")
        if len(consumInfo) > 0:
            for el in root.findall("ConsumableInfo")[0].findall("ConsumableInfo"):
                el2 = el.find("Type")
                if el2 is not None:
                    if el2.text == "FlowCell":
                        runinfo["FlowCellType"] = el.find("Mode").text
                        runinfo["Flowcell"] = el.find("SerialNumber").text
                        runinfo["FlowCellLotNumber"] = el.find("LotNumber").text
                    elif el2.text == "Reagent":
                        runinfo["ReagentLotNumber"] = el.find("LotNumber").text

        tree = ET.parse(runinfo_path)
        root = tree.getroot()
        runinfo_reads = root.findall(".//Read")
        runinfo["Index1Reverse"] = "N"
        runinfo["Index2Reverse"] = "N"
        if runinfo_reads[1].attrib["IsReverseComplement"] == "Y":
            runinfo["Index1Reverse"] = "Y"
        if runinfo_reads[2].attrib["IsReverseComplement"] == "Y":
            runinfo["Index2Reverse"] = "Y"

    # in case we're processing older NovaSeq 6000 data
    else:
        runinfo["Read1Cycles"] = int(root.find(".//Read1NumberOfCycles").text)
        runinfo["Read2Cycles"] = int(root.find(".//Read2NumberOfCycles").text)
        runinfo["Index1Cycles"] = int(root.find(".//IndexRead1NumberOfCycles").text)
        runinfo["Index2Cycles"] = int(root.find(".//IndexRead2NumberOfCycles").text)
        runinfo["Flowcell"] = root.find(".//FlowCellSerialBarcode").text

        runinfo["FlowCellType"] = "UNKNOWN"
        runinfo["FlowCellType"] = "UNKNOWN"
        runinfo["InstrumentType"] = "UNKNOWN"
        runinfo["Instrument"] = "UNKNOWN"
        runinfo["Side"] = "UNKNOWN"
        runinfo["Index1Reverse"] = "N"
        runinfo["Index2Reverse"] = "Y"

    return runinfo


# main function:
def main():
    # parse arguments:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-r", "--rundir", type=checkfile, help="Path to the Illumina run folder"
    )
    parser.add_argument(
        "-s", "--samplesheet", type=checkfile, help="Path to the samplesheet"
    )
    parser.add_argument(
        "-c",
        "--checkindexes",
        action="store_true",
        default=False,
        help="Reverse complement indexes according to the RunInfo.",
    )
    parser.add_argument(
        "-v", "--version", action="version", version="%(prog)s: " + __version__
    )

    args = parser.parse_args()

    # get the run info
    runinfo = parse_runinfo(args.rundir)

    # create samplesheet
    # read the samplesheet into a dataframe:
    df = pd.read_csv(args.samplesheet, header=0)

    # rename columns in df called lane and id to Lane and Sample:
    df.rename(columns={"Content_Desc": "Sample_ID"}, inplace=True)

    # Split the 'index' column into 'Index' and 'Index2'
    df[["Index", "Index2"]] = df["Index"].str.split("-", expand=True)

    # if index1_direction is reverse, then reverse complement the DNA sequence:
    if args.checkindexes and runinfo["Index1Reverse"] == "Y":
        df["Index"] = df["Index"].apply(reverse_complement)

    # if index2_direction is reverse, then reverse complement the DNA sequence:
    if args.checkindexes and runinfo["Index2Reverse"] == "Y":
        df["Index2"] = df["Index2"].apply(reverse_complement)

    # make cycle string
    if runinfo["Index1Cycles"] < 19:
        print(f"Number of cycles needs to be >=19, its {runinfo['Index1Cycles']}")
        sys.exit()

    cycle_str = "Y" + str(runinfo["Read1Cycles"]) + ";I10U9"
    if runinfo["Index1Cycles"] > 19:
        cycle_str = cycle_str + "N" + str(runinfo["Index1Cycles"] - 19)

    cycle_str = cycle_str + ";I10"
    if runinfo["Index2Cycles"] > 10:
        cycle_str = cycle_str + "N" + str(runinfo["Index2Cycles"] - 10)

    cycle_str = cycle_str + ";Y" + str(runinfo["Read2Cycles"])

    # Initialize a list to store rows
    rows_list = []

    # Iterate through each row and split the Lane values
    for index, row in df.iterrows():
        lanes = map(int, str(row["Lane"]).split(","))
        for lane in lanes:
            rows_list.append(
                {
                    "Lane": lane,
                    "Sample_ID": row["Sample_ID"],
                    "Index": row["Index"],
                    "Index2": row["Index2"],
                }
            )

    # Create a DataFrame from the list of rows
    df_output = pd.DataFrame(rows_list)

    # # Select and order the required columns
    # df_output = df[['Lane', 'Sample_ID', 'Index', 'Index2']]

    # Write the header for the output file
    outfile = open(runinfo["RunID"] + ".demux_samplesheet.csv", "w")
    outfile.write("[Header]\nFileFormatVersion,2\n\n")
    outfile.write(
        f"[BCLConvert_Settings]\nAdapterBehavior,trim\nAdapterRead1,AGATCGGAAGAGCACACGTCTGAAC\nAdapterRead2,AGATCGGAAGAGCGTCGTGTAGGGA\nOverrideCycles,{cycle_str}\n\n"
    )
    outfile.write("[BCLConvert_Data]\n")

    # Append the processed data to the file
    df_output.to_csv(outfile, mode="a", header=True, index=False)
    outfile.close()

    # Write the runinfo dict to a json file named after the batch:
    with open(runinfo["Flowcell"] + ".runinfo.csv", "w", newline="") as cfile:
        writer = csv.writer(cfile)
        writer.writerow(runinfo.keys())
        writer.writerow(runinfo.values())


if __name__ == "__main__":
    main()
