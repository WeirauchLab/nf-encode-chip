#!/usr/bin/env python
import argparse
import logging
import os
import glob
import hashlib
import base64
import re

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
log = logging.getLogger(__name__)


class Hub:
    def __init__(self, name, genome="<FILL IN>", email="<FILL IN>"):
        self.name = name
        self.genome = genome
        self.email = email

    def parse_hub(self):
        hub_strings = [
            f"hub {self.name}",
            f"shortLabel {self.name[:17]}",
            f"longLabel {self.name}",
            "useOneFile on",
            f"email {self.email}",
            "",
            f"genome {self.genome}",
            "",
        ]
        return "\n".join(hub_strings)


class HashMixin:
    def path_to_alphanum_hash(self, file_path, length=12):
        # Create a SHA256 hash of the file path
        hash_object = hashlib.sha256(file_path.encode())
        hash_digest = hash_object.digest()

        # Use base64 encoding to convert to alphanumeric
        b64_encoded = base64.b64encode(hash_digest).decode()

        # Remove any non-alphanumeric characters
        alphanum_hash = "".join(c for c in b64_encoded if c.isalnum())

        # Ensure the hash starts with a letter
        if not alphanum_hash[0].isalpha():
            alphanum_hash = "a" + alphanum_hash[1:]

        # Truncate or pad to desired length
        return alphanum_hash[:length].ljust(length, "a")


class Track(HashMixin):
    def __init__(
        self,
        name,
        big_data_url,
        track_type,
        visibility="hide",
        parent=None,
        color=None,
    ):
        self.name = self.path_to_alphanum_hash(big_data_url, 12)
        self.big_data_url = big_data_url
        self.track_type = track_type
        self.short_label = name[:17]
        self.long_label = name
        self.visibility = visibility
        self.parent = parent
        self.color = color

    def parse_track(self):
        track_strings = [
            f"track {self.name}",
            f"bigDataUrl {self.big_data_url}",
            f"type {self.track_type}",
            f"shortLabel {self.short_label}",
            f"longLabel {self.long_label}",
            f"visibility {self.visibility}",
        ]
        if self.parent:
            track_strings.insert(1, f"parent {self.parent}")
        if self.color:
            track_strings.append(f"color {self.color}")
        return "\n".join(track_strings)

    def set_parent(self, parent):
        self.parent = parent


class SuperTrack:
    def __init__(self, name):
        self.name = name
        self.short_label = name
        self.long_label = name
        self.tracks = []

    def parse_track(self):
        track_strings = [
            f"track {self.name}",
            "superTrack on show",
            f"shortLabel {self.short_label}",
            f"longLabel {self.long_label}",
        ]
        return "\n".join(track_strings)

    def parse_supertrack(self):
        supertrack_strings = []
        supertrack_strings.append(self.parse_track())
        for track in self.tracks:
            supertrack_strings.append(track.parse_track())
        return "\n\n".join(supertrack_strings)

    def add_track(self, track):
        track.set_parent(self.name)
        self.tracks.append(track)

    def __str__(self):
        return f"{self.name} {self.label} {self.trackdb}"


def find_files(pattern):
    files = [file for file in glob.iglob(pattern, recursive=True)]
    return files


def collect_files(directory, pattern="*.bw|*.bigwig"):
    files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if re.match(pattern, file):
                files.append(os.path.join(root, file))
    return files


def main(args):
    track_strings = []

    hub = Hub(name=args.hub, genome=args.genome)
    track_strings.append(hub.parse_hub())

    if args.bigbed:
        supertrack = SuperTrack("bigbed_supertrack")
        files = collect_files("data", "*.bb")
        for file in files:
            base_name = os.path.basename(file)
            file_id = os.path.splitext(base_name)[0]
            entry = Track(
                name=file_id, big_data_url=file, track_type="bigBed 6 +"
            )
            supertrack.add_track(entry)
        track_strings.append("#################################")
        track_strings.append(supertrack.parse_supertrack())
    if args.bigwig:
        supertrack = SuperTrack("bigwig_supertrack")
        files = collect_files("data", "*.bw|*.bigwig")
        for file in files:
            base_name = os.path.basename(file)
            file_id = os.path.splitext(base_name)[0]
            entry = Track(name=file_id, big_data_url=file, track_type="bigWig")
            supertrack.add_track(entry)
        track_strings.append("#################################")
        track_strings.append(supertrack.parse_supertrack())

    if track_strings:
        with open("hub.txt", "w") as f:
            f.write("\n".join(track_strings))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Create a trackDb.txt file for a track hub"
    )
    parser.add_argument(
        "--bigwig",
        action="store_true",
        default=False,
        help="enable search for bigwigs",
    )
    parser.add_argument(
        "--bigbed",
        action="store_true",
        default=False,
        help="enable search for bigwigs",
    )
    parser.add_argument("--genome", default="<FILL IN>", help="genome name")
    parser.add_argument("--hub", default="<FILL IN>", help="hub name")
    args = parser.parse_args()

    main(args)
