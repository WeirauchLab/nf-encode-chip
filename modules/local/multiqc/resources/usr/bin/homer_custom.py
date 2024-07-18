from multiqc.base_module import BaseMultiqcModule
import logging
import glob
import os
from multiqc.plots import table
from multiqc import config


log = logging.getLogger("multiqc")


class FindMotifsGenomeMixin:
    def parse_findMotifsGenome_data(self):
        output = {}
        config_sp = getattr(config.sp, "homer/findMotifsGenome", {})
        file_pattern = config_sp.get("fn", "data/homer/findMotifsGenome/*.tsv")
        clean_str = config_sp.get("clean_str", "_knownResults.tsv")

        files = [f for f in glob.iglob(file_pattern, recursive=True)]
        log.info("Found {} homer/findMotifsGenomes reports".format(len(files)))
        for f in files:
            log.debug(f"Reading {f}")
            with open(f, "r") as file:
                lines = [next(file).strip() for _ in range(2)]
            if len(lines) < 2:
                log.warn(
                    f"File {f} does not contain at least two lines. Skipping."
                )
                continue

            keys = lines[0].strip().split("\t")
            values = lines[1].strip().split("\t")

            if len(keys) != len(values):
                log.warn(f"Mismatch in number of keys and values in file {f}.")
                continue

            data = dict(zip(keys, values))
            if "id" in data:
                del data["id"]
            sample_id = os.path.basename(f).replace(clean_str, "")
            output[sample_id] = data
        return output

    def add_findMotifsGenome_section(self, data):
        self.write_data_file(data, "multiqc_homer_findmotifsgenome")
        self.add_section(
            name="findMotifsGenome",
            anchor="homer_custom_findmotifsgenome",
            description="""HOMER's `findMotifsGenome.pl` calculates the
            enrichment of motifs in peak files.""",
            helptext="""
            This table is generated after doing some post-processing of the
            standard HOMER output. Specifically, we add:

            * log10 of the p-value\n
            * rank column

            The log10 of the p-value is calculated because HOMER normally
            reports the natural log of the p-value. This is done by
            taking the natural log of the p-value column (log_p_value) and
            dividing by the natural log of 10.
            """,
            plot=table.plot(
                data=data,
                pconfig={
                    "id": "homer_findmotifsgenome",
                    "title": "HOMER Known Motifs",
                    "only_defined_headers": False,
                },
                headers={
                    "motif_name": {
                        "title": "Motif Name",
                        "description": "Name of the motif in the library file",
                    },
                    "consensus": {
                        "title": "Consensus",
                        "hidden": False,
                        "description": "Consensus sequence of the motif",
                    },
                    "p_value": {
                        "title": "P-value",
                        "hidden": True,
                        "scale": "Blues",
                        "format": "{:.2e}",
                        "description": """P-value threshold for enrichment.
                        This is a binned value and is
                        inaccurate past values of 1e-307!""",
                    },
                    "log_p_value": {
                        "title": "Log P-value",
                        "hidden": True,
                        "bars_zero_centrepoint": True,
                        "description": """Natural log of the p-value
                        reported by HOMER""",
                    },
                    "log10_p_value": {
                        "title": "log10 P-value",
                        "hidden": False,
                        "bars_zero_centrepoint": True,
                        "description": """HOMER normally reports the natural
                        log of the p-value, but we convert it to log10 for
                        easier interpretation.""",
                    },
                    "q_value": {
                        "title": "Q-value",
                        "hidden": False,
                        "format": "{:.2e}",
                        "description": """Q-value threshold for enrichment.""",
                    },
                    "n_of_target_sequences_with_motif": {
                        "title": "number target seq with motif",
                        "hidden": True,
                        "description": """Number of target sequences
                        with the motif""",
                    },
                    "pct_of_target_sequences_with_motif": {
                        "title": "% target seq with motif",
                        "hidden": False,
                        "description": """Percent of target sequences
                        with the motif""",
                    },
                    "n_of_background_sequences_with_motif": {
                        "title": "number background seq with motif",
                        "hidden": True,
                        "description": """Number of background sequences
                        with the motif""",
                    },
                    "pct_of_background_sequences_with_motif": {
                        "title": "% background seq with motif",
                        "hidden": False,
                        "description": """Percent of background sequences
                        with the motif""",
                    },
                    "rank": {
                        "title": "Rank",
                        "hidden": True,
                        "description": """Rank of the motif in results.""",
                    },
                },
            ),
        )


class Homer(BaseMultiqcModule, FindMotifsGenomeMixin):
    def __init__(self):
        super(Homer, self).__init__(
            name="HOMER",
            target="HOMER",
            anchor="homer_custom",
            href="http://homer.ucsd.edu/homer/index.html",
            info="",
        )

        self.data = {}

        self.data["findMotifsGenome"] = self.parse_findMotifsGenome_data()
        self.add_findMotifsGenome_section(self.data["findMotifsGenome"])
