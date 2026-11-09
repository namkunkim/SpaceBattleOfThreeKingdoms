import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PLAN = HERE.parent / "PLAN-UI-CALLPATHS.md"
LEDGER = HERE / "UI-CALLPATHS.json"
ORACLE = HERE / "oracle.json"
BASELINE = HERE.parent / "policy-ownership/POLICY-LEDGER.json"
MANIFEST = HERE / "manifest.json"
SCOPE = HERE / "SOURCES.sha256"
APPROVED = "46c944ba0545ece0f3dec8953b6a2bc1f0c16c6c64c63cac3ebcf87130e249f3"
BASELINE_SHA = "f7d1d32f63f4c97e533e39fc1fce8ba9ca4f6896ec7c863017461b25dec89cdd"
CASES = {"normal": 0, "row_omission": 1, "busy_misclassification": 1, "missing_anchor": 2}
LAYERS = {"CURRENT_SOURCE", "OBSERVED_LIMITED_RUNTIME", "PRODUCT_CALL_NOT_FOUND_IN_SCOPE", "UNVERIFIED"}
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS="0")


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


def source(raw):
    path = (ROOT / raw).resolve(strict=True)
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"invalid source: {raw}")
    return path


def source_set():
    paths = set()
    for row in SCOPE.read_text(encoding="utf-8-sig").splitlines():
        expected, raw = row.split("  ", 1)
        path = source(raw)
        if path in paths or sha(path) != expected:
            raise ValueError(f"source duplicate or changed: {raw}")
        paths.add(path)
    production = (HERE / "PRODUCTION-SCOPE.txt").read_text(encoding="utf-8-sig").splitlines()
    if len(paths) != 104 or len(production) != 95 or len(set(production)) != 95:
        raise ValueError("source denominator")
    if {source(raw) for raw in production} != {path for path in paths if path.suffix in {".gd", ".tscn"}}:
        raise ValueError("production scope mismatch")
    lexical = (HERE / "LEXICAL-CALLS.txt").read_text(encoding="utf-8-sig").splitlines()
    if len(lexical) != 32:
        raise ValueError("lexical denominator")
    return paths


def snapshot():
    if sha(PLAN) != APPROVED or sha(BASELINE) != BASELINE_SHA:
        raise ValueError("plan or baseline SHA mismatch")
    paths = [
        *source_set(), PLAN, HERE.parent / "REVIEW-PLAN-UI-CALLPATHS.md", LEDGER, ORACLE, SCOPE,
        HERE / "PRODUCTION-SCOPE.txt", HERE / "LEXICAL-CALLS.txt", HERE / "run_gate.py", Path(sys.executable),
        *(HERE / f"cases/{name}.json" for name in CASES if name != "normal"),
    ]
    frozen = {}
    for path in paths:
        name = path.resolve(strict=True).as_posix()
        if name.casefold() in frozen:
            raise ValueError(f"duplicate path: {name}")
        frozen[name.casefold()] = {"path": name, "sha256": sha(path), "size": path.stat().st_size}
    return {"head": git("rev-parse", "HEAD").decode().strip(), "files": frozen}


def prepare():
    cases = HERE / "cases"
    cases.mkdir()
    candidate = read(LEDGER)
    candidate["rows"] = [row for row in candidate["rows"] if row["id"] != "QUEUE_RETURN"]
    write(cases / "row_omission.json", candidate)
    candidate = read(LEDGER)
    busy = next(row for row in candidate["rows"] if row["id"] == "BUSY_OR_CLOSED")
    busy["product_ui_restore_verified"] = True
    write(cases / "busy_misclassification.json", candidate)
    candidate = read(LEDGER)
    candidate["rows"][0]["evidence"][0]["path"] = "tmp/p03-parallel-state-20261108/ui-callpaths/cases/absent.gd"
    write(cases / "missing_anchor.json", candidate)
    write(MANIFEST, snapshot())
    print(sha(MANIFEST))


def inspect(case):
    ledger = read(LEDGER if case == "normal" else HERE / f"cases/{case}.json")
    oracle = read(ORACLE)
    scope = source_set()
    observed = []
    for row in ledger["rows"]:
        observed.append((row["id"], row["column"]))
        if not all(row[key] for key in ("path", "visibility", "ownership", "joint", "evidence")):
            raise ValueError(f"incomplete row: {row['id']}")
        if type(row["product_ui_restore_verified"]) is not bool or row["new_user_choice"] is not False:
            raise ValueError(f"invalid scope/choice: {row['id']}")
        for anchor in row["evidence"]:
            if anchor["layer"] not in LAYERS or not anchor["claim"]:
                raise ValueError(f"invalid evidence: {row['id']}")
            path = (HERE / "LEXICAL-CALLS.txt") if anchor["path"] == "LEXICAL-CALLS.txt" else source(anchor["path"])
            if path not in scope and path != HERE / "LEXICAL-CALLS.txt":
                raise ValueError(f"undocumented source: {anchor['path']}")
            line = anchor["line"]
            if line is not None and not 0 < line <= len(path.read_text(encoding="utf-8-sig").splitlines()):
                raise ValueError(f"invalid line: {anchor['path']}:{line}")
    if len(observed) != len(set(observed)):
        raise ValueError("duplicate cell")
    expected = {(row, oracle["column"]) for row in oracle["rows"]}
    baseline = {(row["id"], row["column"]) for row in read(BASELINE)["rows"] if not row["user_choice"]}
    if expected != baseline or len(expected) != 8:
        raise ValueError("oracle and baseline mismatch")
    busy = next(row for row in ledger["rows"] if row["id"] == "BUSY_OR_CLOSED")
    difference = {
        "missing": sorted(expected - set(observed)), "added": sorted(set(observed) - expected),
        "busy_verified": None if busy["product_ui_restore_verified"] == oracle["busy_product_ui_restore_verified"]
        else busy["product_ui_restore_verified"],
    }
    print(json.dumps({"difference": difference, "rows": len(observed)}))
    return int(any(difference.values()))


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
            passed = passed and not child.stdout and b"absent.gd" in child.stderr
        else:
            difference = {"missing": [["QUEUE_RETURN", "ui_publish"]] if case == "row_omission" else [],
                          "added": [], "busy_verified": True if case == "busy_misclassification" else None}
            payload = json.loads(child.stdout) if child.stdout else None
            passed = passed and not child.stderr and payload == {
                "difference": difference, "rows": 7 if case == "row_omission" else 8,
            }
        results[case] = {"command": command, "actual_exit": child.returncode, "expected_exit": expected, "passed": passed}
    after = snapshot()
    write(out / "input-after.json", after)
    after_git = git("status", "--porcelain=v1", "-z", "--untracked-files=all")
    (out / "git-after.z").write_bytes(after_git)
    status_changes = set(before_git.decode().split("\0")) ^ set(after_git.decode().split("\0"))
    write(out / "git-comparison.json", {"changed": sorted(status_changes)})
    stable = before == after and sha(MANIFEST) == expected_sha
    passed = stable and all(row["passed"] for row in results.values())
    write(out / "suite.json", {"passed": passed, "stable_inputs": stable, "inputs": len(before["files"]), "cases": results})
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

