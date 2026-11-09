import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PLAN = HERE.parent / "PRIORITY-HANDOFF.md"
APPROVED = "5fc813b2611c47cc8f4d6c50b73b823c4e6bad230fa5676868cac23f45364f1f"
MATRIX = HERE / "boundary-matrix.json"
ORACLE = HERE / "oracle.json"
MANIFEST = HERE / "manifest.json"
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
CASES = {"normal": 0, "row_omission": 1, "cursor_misclassification": 1, "missing_anchor": 2}
DISPOSITIONS = {"SUPPORTED_EVIDENCE", "REJECTED_EVIDENCE", "POLICY_REQUIRED", "UNCLASSIFIED"}


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write(path, value):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, indent=2, ensure_ascii=False)
        stream.write("\n")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(*args):
    return subprocess.check_output(["git", "-c", "core.longpaths=true", *args], cwd=ROOT, env=ENV)


def anchors(matrix):
    for row in matrix["rows"]:
        for cell in row["cells"]:
            yield cell["path"], cell["line"]
    yield matrix["cursor_attempt_03"]["path"], None
    yield matrix["a06"]["path"], None


def source(path):
    resolved = (ROOT / path).resolve(strict=True)
    if not resolved.is_relative_to(ROOT) or not resolved.is_file():
        raise ValueError(f"invalid anchor {path}")
    return resolved


def snapshot():
    if sha(PLAN) != APPROVED:
        raise ValueError("plan SHA mismatch")
    paths = [
        PLAN, HERE.parent / "REVIEW-PRIORITY-PLAN.md", MATRIX, ORACLE, HERE / "A06-ACCEPTANCE.md",
        HERE / "run_gate.py", Path(sys.executable), *(HERE / f"cases/{name}.json" for name in CASES if name != "normal"),
        *(source(path) for path in sorted({path for path, _ in anchors(read(MATRIX))})),
    ]
    items = {}
    for path in paths:
        name = path.resolve(strict=True).as_posix()
        if name.casefold() in items:
            raise ValueError(f"duplicate path: {name}")
        items[name.casefold()] = {"path": name, "sha256": sha(path), "size": path.stat().st_size}
    return {"head": git("rev-parse", "HEAD").decode().strip(), "files": items}


def prepare():
    cases = HERE / "cases"
    cases.mkdir()
    candidate = read(MATRIX)
    candidate["rows"] = [row for row in candidate["rows"] if row["id"] != "QUEUE_RETURN"]
    write(cases / "row_omission.json", candidate)
    candidate = read(MATRIX)
    candidate["cursor_attempt_03"]["disposition"] = "SUPPORTED_EVIDENCE"
    write(cases / "cursor_misclassification.json", candidate)
    candidate = read(MATRIX)
    candidate["rows"][0]["cells"][0]["path"] = "tmp/p03-parallel-state-20261108/boundary-closure/cases/absent.md"
    write(cases / "missing_anchor.json", candidate)
    write(MANIFEST, snapshot())
    print(sha(MANIFEST))


def inspect(case):
    matrix = read(MATRIX if case == "normal" else HERE / f"cases/{case}.json")
    oracle = read(ORACLE)
    for path, line in anchors(matrix):
        anchor = source(path)
        if line is not None and not 0 < line <= len(anchor.read_text(encoding="utf-8-sig").splitlines()):
            raise ValueError(f"invalid anchor line {path}:{line}")
    ids = [row["id"] for row in matrix["rows"]]
    if len(ids) != len(set(ids)):
        raise ValueError("duplicate row ID")
    cells = [cell for row in matrix["rows"] for cell in row["cells"]]
    if any([cell["column"] for cell in row["cells"]] != oracle["columns"] for row in matrix["rows"]):
        raise ValueError("invalid boundary columns")
    if any(cell["disposition"] not in DISPOSITIONS or cell["evidence"] not in {"STATIC", "OBSERVATION"}
           or not cell["note"] for cell in cells):
        raise ValueError("invalid disposition or evidence")
    required = oracle["row_ids"]
    cursor = matrix["cursor_attempt_03"]["disposition"]
    difference = {
        "missing_rows": sorted(set(required) - set(ids)),
        "added_rows": sorted(set(ids) - set(required)),
        "row_order": ids == [row for row in required if row in ids],
        "cursor_attempt_03": None if cursor == oracle["cursor_attempt_03"] else cursor,
        "a06_matches": all(matrix["a06"][key] == value for key, value in oracle["combination"].items()),
    }
    print(json.dumps({"difference": difference, "rows": len(ids), "cells": len(cells)}))
    return int(bool(difference["missing_rows"] or difference["added_rows"] or difference["cursor_attempt_03"]
                    or not difference["row_order"] or not difference["a06_matches"]))


def suite(out, expected_sha):
    out = out.resolve()
    out.relative_to(HERE)
    out.mkdir()
    before = snapshot()
    if sha(MANIFEST) != expected_sha or before != read(MANIFEST):
        raise ValueError("manifest SHA or inputs mismatch")
    write(out / "input-before.json", before)
    before_git = git("status", "--porcelain=v1", "-z", "--untracked-files=all")
    (out / "git-before.z").write_bytes(before_git)
    results = {}
    for case, expected in CASES.items():
        command = [sys.executable, str(Path(__file__)), "--case", case]
        child = subprocess.run(command, cwd=ROOT, capture_output=True)
        (out / f"{case}.stdout").write_bytes(child.stdout)
        (out / f"{case}.stderr").write_bytes(child.stderr)
        passed = child.returncode == expected
        if expected == 2:
            passed = passed and not child.stdout and b"absent.md" in child.stderr
        else:
            difference = {"missing_rows": ["QUEUE_RETURN"] if case == "row_omission" else [],
                          "added_rows": [], "row_order": True, "a06_matches": True,
                          "cursor_attempt_03": "SUPPORTED_EVIDENCE" if case == "cursor_misclassification" else None}
            count = 11 if case == "row_omission" else 12
            observed = json.loads(child.stdout) if child.stdout else None
            passed = passed and not child.stderr and observed == {"difference": difference, "rows": count, "cells": count * 4}
        results[case] = {"command": command, "actual_exit": child.returncode, "expected_exit": expected, "passed": passed}
    after = snapshot()
    write(out / "input-after.json", after)
    after_git = git("status", "--porcelain=v1", "-z", "--untracked-files=all")
    (out / "git-after.z").write_bytes(after_git)
    status_changes = set(before_git.decode().split("\0")) ^ set(after_git.decode().split("\0"))
    write(out / "git-comparison.json", {"changed": sorted(status_changes)})
    stable_inputs = before == after and sha(MANIFEST) == expected_sha
    passed = stable_inputs and all(row["passed"] for row in results.values())
    write(out / "suite.json", {"passed": passed, "stable_inputs": stable_inputs, "inputs": len(before["files"]), "cases": results})
    return int(not passed)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prepare", action="store_true")
    parser.add_argument("--case", choices=CASES)
    parser.add_argument("--manifest-sha256")
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    if args.prepare:
        prepare()
        return 0
    if args.case:
        return inspect(args.case)
    return suite(args.out, args.manifest_sha256)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        print(f"input or execution error: {error}", file=sys.stderr)
        sys.exit(2)

