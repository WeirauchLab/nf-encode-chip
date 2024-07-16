#!/usr/bin/env python
import argparse
import glob
import json
import multiqc
from multiqc.plots import table
from multiqc.plots import linegraph
from multiqc import config
import csv
import os

parser = argparse.ArgumentParser()
parser.add_argument("--config", type=str)
args = parser.parse_args()

spp_xcorr_pattern = "data/spp_xcor/*.csv"
idr_rep_stats_pattern = "data/encode_reproducibility_stats/idr/*.json"
overlap_rep_stats_pattern = "data/encode_reproducibility_stats/overlap/*.json"
homer_findmotifsgenome_pattern = "data/homer/findMotifsGenome/*.tsv"
lib_qc_pattern = "data/lib_qc/*.lib_qc.tsv"

# Load MultiQC config
# if args.config:
#    multiqc.load_config(args.config)

# Parse known logs
multiqc.parse_logs("data", config_files=[args.config])

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
spp_xcorr_data = {}
for spp_xcorr_file in glob.glob(spp_xcorr_pattern):
    with open(spp_xcorr_file) as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["sample_id"] not in spp_xcorr_data:
                spp_xcorr_data[row["sample_id"]] = {}
            spp_xcorr_data[row["sample_id"]][float(row["shift"])] = float(
                row["correlation"]
            )

spp_xcorr_plot = linegraph.plot(
    data=spp_xcorr_data,
    pconfig={"id": "spp_xcorr_plot", "title": "Cross-Correlation Statistics"},
)

spp_xcorr_module = multiqc.BaseMultiqcModule(
    name="Cross-Correlation",
    anchor="spp_xcorr",
    comment="Cross correlation",
)
spp_xcorr_module.add_section(
    name="Cross-Correlation Statistics",
    plot=spp_xcorr_plot,
    anchor="spp_xcorr_section",
)
multiqc.report.modules.append(spp_xcorr_module)

# ENCODE IDR statistics
idr_rep_stats_data = {}
for rep_stats_file in glob.glob(idr_rep_stats_pattern):
    with open(rep_stats_file) as f:
        rep_stats_dict = json.load(f)
        sample_id = rep_stats_dict["sample"]
        del rep_stats_dict["sample"]
        idr_rep_stats_data[sample_id] = rep_stats_dict

idr_rep_stats_plot = table.plot(
    data=idr_rep_stats_data,
    pconfig={
        "id": "encode_reproducibility_stats_idr",
        "title": "Reproducibility Statistics (IDR)",
    },
    headers={
        "Nt": {"title": "Nt"},
        "Np": {"title": "Np"},
        "Conservative Peaks": {"title": "Conservative Peaks"},
        "Optimal Peaks": {"title": "Optimal Peaks"},
        "Rescue Ratio": {"title": "Rescue Ratio", "format": "{:,.3f}"},
        "Consistency Ratio": {
            "title": "Consistency Ratio",
            "format": "{:,.3f}",
        },
        "Reproducibility": {"title": "Reproducibility"},
    },
)

encode_reproducibility_module = multiqc.BaseMultiqcModule(
    name="Encode Reproducibility",
    anchor="encode_reproducibility",
    comment="Reproducibility statistics for ENCODE ChIP-seq samples.",
)
encode_reproducibility_module.add_section(
    name="IDR Statistics",
    plot=idr_rep_stats_plot,
    anchor="encode_reproducibility_stats_idr_section",
    description="""
**Nt**                = Best no. of peaks passing IDR threshold by comparing
true replicates\n
**Np**                = Best no. of peaks passing IDR threshold by comparing
pseudoreplicates\n
**Conservative**      = file containing the best peak number when comparing
true replicate pairs\n
**Optimal**           = peak file with the most peaks when comparing Nt and Np\n
**Rescue Ratio**      = max(Nt, Np) / min(Nt, Np)\n
**Consistency Ratio** = max(Peaks) / min(Peaks)
""",
    helptext="""Nt is established by comparing pairs of true replicates against
    each other and transferring the results to the pooled peak set.
    If you have 2 replicates, it would just be
    - 'rep1 vs rep2'
    if you have 3 or more, it would be:
    - 'rep1 vs rep2'
    - 'rep1 vs rep3'
    - 'rep2 vs rep3'
    and so on. The comparison the best number of peaks is then selected as Nt.
    Np is established the same way, but it will only ever have 2 pseudoreps.
    The rescue ratio is the ratio of these two peak sets and tries to represent
    how well the pseudoreplicates can recapitulate the true replicates.
    Consistency ratio estimates how consistent the peak sets are across the
    replicates. If one replicate has a lot more peaks than the other, this will
    ratio will increase, which could be indicative of a failed replicate.
    """,
)

overlap_rep_stats_data = {}
for rep_stats_file in glob.glob(overlap_rep_stats_pattern):
    with open(rep_stats_file) as f:
        rep_stats_dict = json.load(f)
        sample_id = rep_stats_dict["sample"]
        del rep_stats_dict["sample"]
        overlap_rep_stats_data[sample_id] = rep_stats_dict

overlap_rep_stats_plot = table.plot(
    data=overlap_rep_stats_data,
    pconfig={
        "id": "encode_reproducibility_stats_overlap",
        "title": "Overlap statistics",
    },
    headers={
        "Nt": {"title": "Nt"},
        "Np": {"title": "Np"},
        "Conservative Peaks": {"title": "Conservative Peaks"},
        "Optimal Peaks": {"title": "Optimal Peaks"},
        "Rescue Ratio": {"title": "Rescue Ratio", "format": "{:,.3f}"},
        "Consistency Ratio": {
            "title": "Consistency Ratio",
            "format": "{:,.3f}",
        },
        "Reproducibility": {"title": "Reproducibility"},
    },
)

encode_reproducibility_module.add_section(
    name="Overlap Statistics",
    plot=overlap_rep_stats_plot,
    anchor="encode_reproducibility_stats_overlap_section",
    description="""
**Nt**                = Best no. of overlapping peaks when comparing true
replicates against the pooled replicate\n
**Np**                = Best no. of overlapping peaks when comparing
pseudoreplicates against the pooled replicate\n
**Conservative**      = file containing the best peak number when comparing
true replicate pairs\n
**Optimal**           = peak file with the most peaks when comparing
Nt and Np\n
**Rescue Ratio**      = max(Nt, Np) / min(Nt, Np)\n
**Consistency Ratio** = max(Peaks) / min(Peaks)
""",
)
multiqc.report.modules.append(encode_reproducibility_module)

homer_findmotifsgenome_data = {}
for res in glob.glob(homer_findmotifsgenome_pattern):
    with open(res) as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            sample_id = row["id"]
            del row["id"]
            homer_findmotifsgenome_data[sample_id] = row
            break

homer_findmotifsgenome_plot = table.plot(
    data=homer_findmotifsgenome_data,
    pconfig={
        "id": "homer_findmotifsgenome_table",
        "title": "HOMER Known Motifs",
    },
)
homer_findmotifsgenome_module = multiqc.BaseMultiqcModule(
    name="HOMER findMotifsGenome",
    anchor="homer_findmotifsgenome",
    comment="Top motif results reported by HOMER.",
)

homer_findmotifsgenome_module.add_section(
    name="Known Motifs",
    plot=homer_findmotifsgenome_plot,
    anchor="homer_findmotifsgenome_known",
    description="""Top motif results reported by HOMER.
    The table shows the top motif for each sample when
    scanning known motifs.""",
)
multiqc.report.modules.append(homer_findmotifsgenome_module)


# Write the report
multiqc.write_report(
    filename="multiqc_report.html", force=True, config_files=[args.config]
)
