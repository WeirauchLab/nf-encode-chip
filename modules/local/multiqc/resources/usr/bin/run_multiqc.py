#!/usr/bin/env python
import argparse
import glob
import multiqc
from multiqc.plots import table
from multiqc.plots import linegraph
from multiqc import config
import csv
import os
from homer_custom import Homer
from encode_reproducibility import EncodeReproducibility
from spp_xcorr import SppXCorr

parser = argparse.ArgumentParser()
parser.add_argument("--config", type=str)
args = parser.parse_args()

spp_xcorr_pattern = "data/spp_xcor/*.csv"
idr_rep_stats_pattern = "data/encode_reproducibility_stats/idr/*.json"
overlap_rep_stats_pattern = "data/encode_reproducibility_stats/overlap/*.json"
lib_qc_pattern = "data/lib_qc/*.lib_qc.tsv"

# Load MultiQC config
# if args.config:
#    multiqc.load_config(args.config)

# Parse known logs
multiqc.parse_logs("data")

# ----------------- Custom MultiQC modules -----------------
# Library QC
lib_qc_data = {}
for lib_qc_file in glob.glob(lib_qc_pattern):
    with open(lib_qc_file) as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            sample_id = lib_qc_file.replace(".lib_qc.tsv", "")
            sample_id = os.path.basename(sample_id)
            lib_qc_data[sample_id] = row

lib_qc_table = table.plot(
    data=lib_qc_data,
    pconfig={
        "id": "encode_lib_qc_tbl",
        "title": "Library Complexity (ENCODE)",
    },
    headers={
        "total_fragments": {"title": "Total Fragments"},
        "distinct_fragments": {"title": "Distinct Fragments"},
        "positions_with_one_read": {"title": "Positions with 1 Read"},
        "positions_with_two_reads": {"title": "Positions with 2 Reads"},
        "nrf": {"title": "NRF"},
        "pbc1": {"title": "PBC1"},
        "pbc2": {"title": "PBC2"},
    },
)

encode_lib_qc = multiqc.BaseMultiqcModule(
    name="Library Complexity (ENCODE)", anchor="encode_lib_qc"
)
encode_lib_qc.add_section(
    name="Library Complexity",
    plot=lib_qc_table,
    anchor="encode_lib_qc_section",
    description="""
                **NRF** = Non-Redundant Fraction\n
                **PBC1** = PCR Bottlenecking Coefficient 1\n
                **PBC2** = PCR Bottlenecking Coefficient 2\n
                \n
                NRF should be greater than 0.8\n
                PBC1 is considered to be the primary measure
                according to ENCODE.\n
                They set out the following thresholds:\n
                - 0-0.5: severe bottlenecking\n
                - 0.5-0.8: moderate bottlenecking\n
                - 0.8-0.9: mild bottlenecking\n
                - 0.9-1.0: no bottlenecking\n
                \n
                The PBC2 is the ratio of genomic locations with
                EXACTLY one read pair over the genomic locations with
                EXACTLY two read pairs.\n
                The PBC2 should be significantly greater than 1.
                """,
    helptext="""
            The coefficients are calculated as follows:\n
            - Total Fragments = total number of reads used\n
            - Distinct Fragments = Number of distinct fragments detected\n
            - NRF = number of distinct reads / total number of reads\n
            - PBC1 = number of genomic positions with only one read
            / number of distinct genomic positions\n
            - PBC2 = number of genomic positions with exactly one read /
            number of genomic positions with exactly two reads\n
            """,
)
encode_lib_qc.general_stats_addcols(lib_qc_data)

multiqc.report.modules.append(encode_lib_qc)


# ENCODE xcorr
multiqc.report.modules.append(SppXCorr())

# ENCODE IDR statistics
multiqc.report.modules.append(EncodeReproducibility())

# Custom HOMER module
multiqc.report.modules.append(Homer())


# Write the report
multiqc.write_report(filename="multiqc_report.html", force=True)
