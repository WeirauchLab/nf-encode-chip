from multiqc.base_module import BaseMultiqcModule
import logging
import glob
import os
from multiqc.plots import table
from multiqc import config


log = logging.getLogger("multiqc")


class HomerFindMotifsGenome(BaseMultiqcModule):
    def __init__(self):
        super(HomerFindMotifsGenome, self).__init__(
            name="HOMER",
            target="homer",
            anchor="homer",
            href="",
            info="",
        )
        config_sp = getattr(config.sp, "homer/findMotifsGenome", {})
        file_pattern = config_sp.get("fn", "data/homer/findMotifsGenome/*.tsv")
        clean_str = config_sp.get("clean_str", "_knownResults.tsv")

        self.data = dict()
        found_files = [f for f in glob.iglob(file_pattern, recursive=True)]
        for f in found_files:
            self.parse_file(f, clean_str)

        log.info(
            "Found {} homer/findMotifsGenomes reports".format(len(self.data))
        )

        self.write_data_file(self.data, "multiqc_homer_findmotifsgenome")

        self.add_section(
            description="This plot shows some numbers, and how they relate.",
            helptext="""
            This longer description explains what exactly the numbers mean
            and supports markdown formatting. This means that we can do _this_:

            * Something important
            * Something else important
            * Best of all - some `code`

            Doesn't matter if this is copied from documentation - makes it
            easier for people to find quickly.
            """,
            plot=table.plot(
                data=self.data,
                pconfig={
                    "id": "homer_findmotifsgenome",
                    "title": "HOMER Known Motifs",
                },
            ),
        )

    def parse_file(self, f, clean_str):
        # Read only the first two lines
        with open(f, "r") as file:
            lines = [next(file).strip() for _ in range(2)]
        if len(lines) < 2:
            log.warn(f"File {f} does not contain at least two lines. Skipping.")
            return

        # Use the first line as keys and the second as values
        keys = lines[0].strip().split("\t")
        values = lines[1].strip().split("\t")

        # Ensure the number of keys matches the number of values
        if len(keys) != len(values):
            log.warn(
                f"Mismatch in number of keys and values in file {f}. Skipping."
            )
            return

        # Create a dictionary from keys and values
        data = dict(zip(keys, values))
        if "id" in data:
            del data["id"]
        sample_id = os.path.basename(f).replace(clean_str, "")
        # Add the data to the main dictionary
        self.data[sample_id] = data
