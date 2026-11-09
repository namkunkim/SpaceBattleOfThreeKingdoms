import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PLAN = HERE.parent / "PLAN-POLICY-OWNERSHIP.md"
LEDGER = HERE / "POLICY-LEDGER.json"
ORACLE = HERE / "oracle.json"
MANIFEST = HERE / "manifest.json"
SCOPE = HERE / "SOURCES.sha256"
APPROVED = "779db574ceb41547f594a03e2a5c6ff630853d87bfb88d71d698dbf5966a120b"
EIGHTH = "tmp/p02-eighth-20261108/SESSION-HANDOFF-INCOMPLETE.md"
MATRIX = HERE.parent / "boundary-closure/boundary-matrix.json"
MATRIX_HASH = "9e18e4604e0b369496ae21bdfaca14956e7555900698b5ee0d843b14319c8b1f"
CASES = {"normal": 0, "row_omission": 1, "eighth_misclassification": 1, "missing_anchor": 2}
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
    if len(paths) != 37:
        raise ValueError("source denominator mismatch")
    return paths


def snapshot():
    if sha(PLAN) != APPROVED or sha(MATRIX) != MATRIX_HASH:
        raise ValueError("plan or baseline SHA mismatch")
    paths = [
        *source_set(), PLAN, HERE.parent / "REVIEW-PLAN-POLICY-OWNERSHIP.md", LEDGER, ORACLE, SCOPE,
        HERE / "P02-OWNERSHIP.md", HERE / "run_gate.py", Path(sys.executable),
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
    candidate["rows"] = [row for row in candidate["rows"]
                         if (row["id"], row["column"]) != ("POST_FILTERED_DRAIN", "ui_publish")]
    write(cases / "row_omission.json", candidate)
    candidate = read(LEDGER)
    eighth = next(row for row in candidate["evidence_ranking"] if row["path"] == EIGHTH)
    eighth["status"] = "CONTRACT_ACCEPTED"
    write(cases / "eighth_misclassification.json", candidate)
    candidate = read(LEDGER)
    candidate["rows"][0]["anchors"][0]["path"] = "tmp/p03-parallel-state-20261108/policy-ownership/cases/absent.md"
    write(cases / "missing_anchor.json", candidate)
    write(MANIFEST, snapshot())
    print(sha(MANIFEST))


def inspect(case):
    ledger = read(LEDGER if case == "normal" else HERE / f"cases/{case}.json")
    oracle = read(ORACLE)
    scope = source_set()
    packages = {}
    for pack in ledger["packages"]:
        key = pack["id"]
        alternatives = pack["alternatives"]
        if (key in packages or pack["adopted"] is not False or len(alternatives) < 2
                or len({row["choice"] for row in alternatives}) != len(alternatives)
                or not all(row["choice"] and row["impact"] for row in alternatives)
                or not all(pack[item] for item in ("axis", "lead", "decision_owner", "acceptance"))):
            raise ValueError(f"invalid package {key}")
        packages[key] = pack
    if list(packages) != oracle["packages"]:
        raise ValueError("choice package denominator")
    observed = []
    for row in ledger["rows"]:
        observed.append((row["id"], row["column"], row["baseline"]))
        if (not row["decided"] or not row["investigate"]
                or not all(row["ownership"].get(k) for k in ("current", "proposed", "joint"))
                or not row["anchors"] or any(key not in packages for key in row["user_choice"])
                or not row["user_choice"] and not row.get("choice_note")):
            raise ValueError(f"incomplete disposition: {row['id']}/{row['column']}")
        for anchor in row["anchors"]:
            if source(anchor["path"]) not in scope or not anchor["relation"]:
                raise ValueError(f"undocumented source: {anchor['path']}")
    keys = [(row[0], row[1]) for row in observed]
    if len(keys) != len(set(keys)):
        raise ValueError("duplicate ledger cell")
    for evidence in ledger["evidence_ranking"]:
        if source(evidence["path"]) not in scope:
            raise ValueError("evidence outside freeze")
    expected = {tuple(row) for row in oracle["rows"]}
    baseline = read(MATRIX)
    current = {(row["id"], cell["column"], cell["disposition"]) for row in baseline["rows"]
               for cell in row["cells"] if cell["disposition"] in {"POLICY_REQUIRED", "UNCLASSIFIED"}}
    if expected != current or len(expected) != 35:
        raise ValueError("oracle and baseline mismatch")
    eighth = next(row for row in ledger["evidence_ranking"] if row["path"] == EIGHTH)
    difference = {
        "missing": sorted(expected - set(observed)), "added": sorted(set(observed) - expected),
        "eighth_status": None if eighth["status"] == oracle["p02_eighth"] else eighth["status"],
    }
    print(json.dumps({"difference": difference, "rows": len(observed), "packages": len(packages)}))
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
            passed = passed and not child.stdout and b"absent.md" in child.stderr
        else:
            difference = {
                "missing": [["POST_FILTERED_DRAIN", "ui_publish", "UNCLASSIFIED"]] if case == "row_omission" else [],
                "added": [], "eighth_status": "CONTRACT_ACCEPTED" if case == "eighth_misclassification" else None,
            }
            payload = json.loads(child.stdout) if child.stdout else None
            passed = passed and not child.stderr and payload == {
                "difference": difference, "rows": 34 if case == "row_omission" else 35, "packages": 6,
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

