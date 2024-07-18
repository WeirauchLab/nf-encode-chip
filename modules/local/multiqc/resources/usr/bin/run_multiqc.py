#!/usr/bin/env python
import argparse
import multiqc
from homer_custom import Homer
from encode_reproducibility import EncodeReproducibility
from spp_xcorr import SppXCorr
from encode_libqc import EncodeLibQC

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

# ENCODE lib complexity
multiqc.report.modules.append(EncodeLibQC())

# ENCODE xcorr
multiqc.report.modules.append(SppXCorr())

# ENCODE IDR statistics
multiqc.report.modules.append(EncodeReproducibility())

# Custom HOMER module
multiqc.report.modules.append(Homer())


# Write the report
multiqc.write_report(filename="multiqc_report.html", force=True)
