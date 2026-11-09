"""Reserve evidence paths, freeze inputs and record actual process output."""

import argparse
import json
from pathlib import Path
import subprocess
import sys

from inventory import encode, sha256
from test_inventory import BASELINE, HERE, OLD, ORACLE, REPO, TOOL, write_new


def snapshot():
    paths = [Path(sys.executable), TOOL, HERE / "test_inventory.py", Path(__file__), ORACLE, OLD,
             HERE / "PLAN-v2.md", HERE / "PLAN-v3.md", HERE / "PLAN-v4.md",
             HERE / "REVIEW-PLAN-v2.md", HERE / "REVIEW-PLAN-v4.md", HERE / ".gdignore"]
    if BASELINE.exists():
        paths.append(BASELINE)
    paths.extend(sorted((REPO / "core" / "battle").rglob("*.gd")))
    return {str(p): sha256(p.read_bytes()) for p in paths}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["prepare", "test"])
    parser.add_argument("name")
    args = parser.parse_args()
    if not args.name.isascii() or not args.name.replace("-", "").isalnum():
        parser.error("name must contain ASCII letters, numbers, or hyphens")
    directory = HERE / args.name
    try:
        directory.mkdir()
    except OSError as error:
        print(f"evidence directory reservation: {error}", file=sys.stderr)
        return 2
    if args.mode == "prepare":
        if BASELINE.exists():
            print("baseline already exists", file=sys.stderr)
            return 2
        command = [sys.executable, "-B", str(TOOL), "collect", "--root", str(REPO)]
    else:
        command = [sys.executable, "-B", str(HERE / "test_inventory.py"), "--run-dir", str(directory / "suite")]

    before = snapshot()
    write_new(directory / "input-before.json", encode(before))
    result = subprocess.run(command, cwd=REPO, capture_output=True, check=False)
    after = snapshot()
    write_new(directory / "input-after.json", encode(after))
    write_new(directory / "stdout.bin", result.stdout)
    write_new(directory / "stderr.bin", result.stderr)
    oracle_exact = None
    if args.mode == "prepare" and result.returncode == 0:
        oracle_exact = json.loads(result.stdout)["files"] == json.loads(ORACLE.read_bytes())["files"]
    record = {"argv": command, "cwd": str(REPO), "python_version": sys.version,
              "actual_exit": result.returncode, "input_stable": before == after,
              "before_sha256": sha256(encode(before)), "after_sha256": sha256(encode(after)),
              "oracle_exact": oracle_exact}
    write_new(directory / "run.json", encode(record))
    sys.stdout.buffer.write(result.stdout if args.mode == "test" else encode(record))
    sys.stderr.buffer.write(result.stderr)
    if before != after or oracle_exact is False:
        return 2
    if args.mode == "prepare" and oracle_exact:
        write_new(BASELINE, result.stdout)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
