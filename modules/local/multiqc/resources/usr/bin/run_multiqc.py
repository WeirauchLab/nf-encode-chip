#!/usr/bin/env python
import glob
import json
import multiqc
import multiqc.core
import multiqc.multiqc
from multiqc.plots import table
from multiqc.plots import linegraph
import csv

spp_xcorr_pattern = "data/spp_xcor/*.csv"
idr_rep_stats_pattern = "data/encode_reproducibility_stats/idr/*.json"
overlap_rep_stats_pattern = "data/encode_reproducibility_stats/overlap/*.json"

# Parse known logs
multiqc.parse_logs("data")

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
**Nt**                = Best no. of peaks passing IDR threshold by comparing true replicates\n
**Np**                = Best no. of peaks passing IDR threshold by comparing pseudo replicates\n
**Conservative**      = file containing the best peak number when comparing true replicate pairs\n
**Optimal**           = peak file with the most peaks when comparing Nt and Np\n
**Rescue Ratio**      = max(Nt, Np) / min(Nt, Np)\n
**Consistency Ratio** = max(Peaks) / min(Peaks)
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
**Nt**                = Best no. of peaks passing IDR threshold by comparing true replicates\n
**Np**                = Best no. of peaks passing IDR threshold by comparing pseudo replicates\n
**Conservative**      = file containing the best peak number when comparing true replicate pairs\n
**Optimal**           = peak file with the most peaks when comparing Nt and Np\n
**Rescue Ratio**      = max(Nt, Np) / min(Nt, Np)\n
**Consistency Ratio** = max(Peaks) / min(Peaks)
""",
)

multiqc.report.modules.append(encode_reproducibility_module)

multiqc.write_report(filename="multiqc_report.html", force=True)
