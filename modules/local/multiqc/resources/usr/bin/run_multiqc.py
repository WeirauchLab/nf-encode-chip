#!/usr/bin/env python
import multiqc
from multiqc.plots import table
import glob
import json

print(multiqc.__version__)

multiqc.parse_logs("data")

idr_rep_stats_pattern = "data/encode_reproducibility_stats/idr/*.json"

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
encode_reproducibility_module.add_section(
    name="Overlap Statistics",
    plot=idr_rep_stats_plot,
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
