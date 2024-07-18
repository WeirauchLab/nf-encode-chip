from multiqc.base_module import BaseMultiqcModule
import logging
import glob
from multiqc.plots import linegraph
from multiqc import config
import csv

log = logging.getLogger("multiqc")


class SppXCorr(BaseMultiqcModule):
    def __init__(self):
        super(SppXCorr, self).__init__(
            name="Cross-Correlation",
            target="spp_xcorr",
            anchor="spp_xcorr",
            href="",
            info="",
        )

        self.data = self.parse_files()
        if self.data:
            self.plot_xcorr()

    def plot_xcorr(self):
        self.write_data_file(self.data, "multiqc_spp_xcorr")
        self.add_section(
            name="Cross-Correlation Statistics",
            anchor="spp_xcorr_section",
            plot=linegraph.plot(
                data=self.data,
                pconfig={
                    "id": "spp_xcorr_plot",
                    "title": "Cross-Correlation Statistics",
                },
            ),
        )

    def parse_files(self):
        output = {}
        config_sp = getattr(config.sp, "spp/xcorr", {})
        file_pattern = config_sp.get("fn", "data/spp_xcor/*.csv")
        files = [f for f in glob.iglob(file_pattern, recursive=True)]
        log.info("Found {} spp/xcorr reports".format(len(files)))
        for file in files:
            log.debug(f"Reading {file}")
            with open(file, "r") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    sample_id = row["sample_id"]
                    if sample_id not in output:
                        output[sample_id] = {}
                    key = float(row["shift"])
                    value = float(row["correlation"])
                    output[sample_id][key] = value
        return output
