"""Read review-only WorldLink B stdout and require all expected stage sizes."""
import argparse
import json
from pathlib import Path
from dynamic_capture_oracle import compare
from legacy_autoresolve_oracle import constant, need, unique

def check(stdout):
    streams = {"b-expected": [], "b-live": []}
    for line in stdout.splitlines():
        if line.startswith("K6_CAPTURE "):
            _, name, raw = line.split(" ", 2)
            need(name in streams, f"unexpected B stream {name}")
            streams[name].append(json.loads(raw, object_pairs_hook=unique, parse_constant=constant))
    expected, actual = streams.values()
    compare("b", expected, actual)
    need([len(stage["buttons"]) for stage in expected] == [12, 30, 6, 18], "constructor stage counts")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stdout", type=Path)
    args = parser.parse_args()
    check(args.stdout.read_text(encoding="utf-8-sig"))
