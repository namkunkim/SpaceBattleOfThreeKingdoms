"""Rehash the original P03 denominator and separate concurrent path drift."""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import zlib

from inventory import sha256
from test_inventory import HERE, REPO, write_new


def git(*args):
    return subprocess.check_output(["git", *args], cwd=REPO)


def status_entries(raw):
    records = iter(raw.decode("utf-8").split("\0")[:-1])
    entries = {}
    for record in records:
        tag = record[:2]
        entries[record[3:]] = tag
        if "R" in tag or "C" in tag:
            entries[next(records)] = tag + " source"
    return entries


def compare_paths(old, new):
    prefix = HERE.relative_to(REPO).as_posix() + "/"
    result = {"p03_owned": [], "p02_observed": [], "other_external": []}
    p02_files = {"core/battle/operation_runtime_adapter.gd", "core/battle/operation_runtime_adapter.gd.uid",
                 "core/battle/operation_private_state.gd", "tests/autoresolve.gd",
                 "tests/p02_headless_adapter.gd", "tests/p02_headless_adapter.gd.uid",
                 "docs/battle-core/CHECKLIST-OPEN.md",
                 "docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md"}
    for path in sorted(set(new) - set(old)):
        if path.startswith(prefix):
            category = "p03_owned"
        elif path.startswith(("tmp/p02-", "tests/fixtures/p02/")) or "P02-FIRST-HEADLESS" in path or path in p02_files:
            category = "p02_observed"
        else:
            category = "other_external"
        result[category].append(path)
    return result


def load(path):
    return json.loads((HERE / path).read_bytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name")
    args = parser.parse_args()
    if not args.name.isascii() or not args.name.replace("-", "").isalnum():
        parser.error("invalid audit name")
    destination = HERE / args.name
    destination.mkdir()
    command = ("status", "--porcelain=v1", "-z", "--untracked-files=all")
    start = git(*command)
    base = load("baseline-files.json")
    resume = load("resume-20261107-audit.json")
    resume_entries = status_entries(zlib.decompress((HERE / "resume-20261107-status.z").read_bytes()))
    original_entries = status_entries((HERE / "baseline-status.z").read_bytes())
    changed, missing = [], []
    for row in base["files"]:
        file = REPO / row["path"]
        if not file.is_file():
            missing.append(row["path"])
            continue
        got = sha256(file.read_bytes())
        if got != row["sha256"]:
            changed.append({"path": row["path"], "old": row["sha256"], "current": got})
    frozen = load("attempt-03/input-after.json")
    drift = [name for name, digest in frozen.items()
             if not Path(name).is_file() or sha256(Path(name).read_bytes()) != digest]
    end = git(*command)
    current = status_entries(end)
    result = {
        "utc": datetime.now(timezone.utc).isoformat(), "baseline_count": len(base["files"]),
        "missing": missing, "changed": changed,
        "changed_already_at_resume": [entry for entry in changed if entry in resume["changed"]],
        "changed_after_resume_relative_to_frozen_baseline": [entry for entry in changed if entry not in resume["changed"]],
        "new_status_paths_since_baseline": compare_paths(original_entries, current),
        "new_status_paths_since_resume": compare_paths(resume_entries, current),
        "missing_status_paths_since_resume": sorted(set(resume_entries) - set(current)),
        "status_tags_changed_since_resume": [{"path": path, "before": resume_entries[path], "after": current[path]}
                                             for path in sorted(set(current) & set(resume_entries))
                                             if resume_entries[path] != current[path]],
        "frozen_attempt03_input_count": len(frozen), "frozen_attempt03_input_drift": drift,
        "branch": git("branch", "--show-current").decode().strip(),
        "head": git("rev-parse", "HEAD").decode().strip(),
        "index_paths": git("diff", "--cached", "--name-only").decode().splitlines(),
        "status_sha256_before": sha256(start), "status_sha256_after": sha256(end),
        "status_identical_during_hash": start == end,
    }
    write_new(destination / "preservation.json", (json.dumps(result, ensure_ascii=False, indent=2) + "\n").encode())
    write_new(destination / "status.z", zlib.compress(end))
    print(f"baseline={len(base['files'])} changed={len(changed)} missing={len(missing)} frozen={len(frozen)} drift={len(drift)}")
    for key, value in result["new_status_paths_since_resume"].items():
        print(f"new since resume {key}: {len(value)}")
    return int(bool(missing or drift or result["index_paths"] or start != end))


if __name__ == "__main__":
    raise SystemExit(main())
