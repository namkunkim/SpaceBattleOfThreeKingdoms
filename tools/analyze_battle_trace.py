"""Summarize a local battle JSONL trace. No third-party packages required."""
import argparse
import collections
import json
import os
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", type=Path, help="JSONL file; defaults to latest battle log")
    args = parser.parse_args()
    folder = Path(os.environ.get("APPDATA", Path.home())) / "Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces"
    paths = list(folder.glob("*.jsonl")) if args.path is None else [args.path]
    if not paths:
        parser.exit(1, f"No battle traces found in {folder}\n")
    path = max(paths, key=lambda p: p.stat().st_mtime)
    rows = []
    with path.open(encoding="utf-8") as stream:
        for number, line in enumerate(stream, 1):
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                print(f"Warning: skipped incomplete/invalid line {number}")
    print(f"Log: {path}")
    if not rows:
        parser.exit(1, "No complete records\n")
    print(f"Records: {len(rows)}; last simulation time: {rows[-1]['sim_ms'] / 1000:.1f}s")
    rejected = collections.Counter()
    current = None
    for row in rows:
        kind, data = row["kind"], row["data"]
        time = row["sim_ms"] / 1000
        if kind == "session_start":
            print(f"Profile: {data['profile']}; seed: {data['seed']}; difficulty: {data['difficulty']}")
        elif kind == "command_request":
            current = data["command"]
        elif kind == "command_blocked":
            print(f"{time:.1f}s UI blocked command: {data['reason']}")
        elif kind == "core_event" and data["event"]["kind"] == "rejected":
            event = data["event"]
            reason = str(event["value"])
            rejected[reason] += 1
            print(f"{time:.1f}s REJECTED {reason}; latest request={current}")
            ids = current.get("ids", []) if current else []
            for fleet in data["fleets"]:
                if fleet["id"] in ids or fleet["id"] == event["sq"]:
                    print(f"  {fleet['name']} id={fleet['id']} morale={fleet['morale_bp']} state={fleet['mstate']} "
                          f"forced={fleet['forced_retreat']} control={fleet['control']} "
                          f"pos={fleet['pos']} destination={fleet['move_to']} out={fleet['out']}")
        elif kind == "fleet_status":
            print(f"{time:.1f}s STATUS {data['name']}: morale={data['morale_bp']} state={data['mstate']} "
                  f"control={data['control']} commander={data['cmdr_state']} out={data['out']}")
        elif kind == "battle_end":
            print(f"{time:.1f}s END win={data['win']} reason={data['reason']}")
            print("  Settlement:", json.dumps(data["result"], ensure_ascii=False))
    print("Rejections:", dict(rejected))
    if not any(row["kind"] == "battle_end" for row in rows):
        print("No battle_end record: battle may still be running or was closed before settlement.")


if __name__ == "__main__":
    main()
