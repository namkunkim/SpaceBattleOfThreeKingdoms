"""Extract review-only capture records from raw stdout and compare Q/C pairs."""
import argparse
import json
import re
from pathlib import Path
from dynamic_capture_oracle import compare
from legacy_autoresolve_oracle import constant, load, need, unique

PREFIX = "K6_CAPTURE "
STREAMS = {"q": ("q-native", "q-product"), "c": ("c-source-native", "c-target-restore")}
TICKS = (16, 2, 1200, 621, 16, 1, 154, 154)
SERVICE_SEEDS = (0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295)

def extract(kind, raw):
    by_stream = {stream: [] for stream in STREAMS[kind]}
    for line in raw.splitlines():
        if not line.startswith(PREFIX):
            continue
        _, stream, payload = line.split(" ", 2)
        need(stream in by_stream, f"unexpected capture stream: {stream}")
        by_stream[stream].append(json.loads(payload, object_pairs_hook=unique, parse_constant=constant))
    return tuple(by_stream[stream] for stream in STREAMS[kind])

def frozen_keys(kind):
    if kind == "q":
        cases = [(s, f"{p}/{pol}") for s in (0, 7) for p in ("poc", "services") for pol in ("none", "attack5")]
        return [(s, p, t) for (s,p),stop in zip(cases,TICKS) for t in range(stop)]
    return [(s, phase, side) for s in SERVICE_SEEDS
            for state in ("estimated", "lost") for phase in (state, state+" repaired") for side in (0,1)]

def check(kind, expected, actual):
    compare(kind, expected, actual)
    if kind == "q":
        keys = [(r["seed"], r["case"], r["tick"]) for r in expected]
        payloads = (cmd["typed_tuple"] for r in expected for cmd in r["commands"])
    else:
        need(all(r["case"] == "detection" for r in expected), "C capture case")
        keys = [(r["seed"], r["phase"], r["side"]) for r in expected]
        payloads = (rec["typed_payload"] for r in expected for rec in r["records"])
    need(keys == frozen_keys(kind), f"{kind} frozen case/tick/phase/side sequence")
    need(all(re.fullmatch(r"(?:[0-9a-f]{2}){4,}", value) for value in payloads), "invalid Variant byte hex")

def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("kind", choices=STREAMS)
    cli.add_argument("stdout", type=Path)
    args = cli.parse_args()
    streams = extract(args.kind, args.stdout.read_text(encoding="utf-8-sig"))
    check(args.kind, *streams)
    print(f"{args.kind}: exact pairs for {len(streams[0])} required captures")

if __name__ == "__main__":
    main()
