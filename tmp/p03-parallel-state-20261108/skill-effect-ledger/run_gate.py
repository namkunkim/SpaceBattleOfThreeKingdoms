import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SCOPE = HERE.parent / "SKILL-EFFECT-SCOPE.sha256"
PLAN = HERE.parent / "PLAN-SKILL-EFFECT-LEDGER.md"
APPROVED = "b4fc7e70ed51d5d72ed2150feb0bffa6d51d00afeb812c21d2716a1199eab1b6"
SCENARIO = "data/scenarios/red_cliffs_208_realtime.json"
PATTERN = re.compile(r"\b(?:sim\.)?skills\.[A-Za-z_]\w*")
REMOVED = ("core/battle/detection.gd", 94)
CASES = {"normal": 0, "effect_omission": 1, "caller_omission": 1, "missing_input": 2}
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS="0")


def unique_pairs(items):
    result = {}
    for key, value in items:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"), object_pairs_hook=unique_pairs)


def write_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, indent=2, ensure_ascii=False)
        stream.write("\n")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(*args):
    return subprocess.check_output(["git", "-c", "core.longpaths=true", *args], cwd=ROOT, env=ENV)


def source_paths():
    found = {}
    for line in SCOPE.read_text(encoding="utf-8-sig").splitlines():
        expected, name = line.split("  ", 1)
        name = name.replace("\\", "/")
        if name.casefold() in found or not (ROOT / name).resolve().is_relative_to(ROOT):
            raise ValueError(f"invalid or duplicate source path: {name}")
        found[name.casefold()] = name
        if sha(ROOT / name) != expected:
            raise ValueError(f"source drift: {name}")
    if len(found) != 94 or SCENARIO not in found or sum(p.endswith(".gd") for p in found) != 93:
        raise ValueError("source scope denominator")
    return sorted(found.values())


def records(path):
    result = []
    ids = set()
    for skill in read_json(path)["realtime_rules"]["special_skills"]["skills"]:
        identifier = skill["id"]
        if identifier in ids:
            raise ValueError(f"duplicate skill ID: {identifier}")
        ids.add(identifier)
        result.append([identifier, skill["effects"]])
    return result


def lexical(paths):
    rows = []
    for path in paths:
        if not path.endswith(".gd"):
            continue
        for line_no, line in enumerate((ROOT / path).read_text(encoding="utf-8-sig").splitlines(), 1):
            matches = PATTERN.findall(line)
            if matches:
                rows.append({"path": path, "line": line_no, "text": line.strip(), "accesses": matches})
    return rows


def freeze():
    paths = [
        *(ROOT / path for path in source_paths()), SCOPE, PLAN,
        HERE.parent / "REVIEW-PLAN-SKILL-EFFECT-LEDGER.md", Path(sys.executable),
        HERE / "oracle.json", HERE / "run_gate.py", HERE / "TRACE.md",
        HERE / "cases/effect_omission.json", HERE / "cases/caller_omission.json",
    ]
    if sha(PLAN) != APPROVED:
        raise ValueError("plan SHA not approved")
    output = {}
    for path in paths:
        resolved = path.resolve(strict=True).as_posix()
        if resolved.casefold() in output:
            raise ValueError(f"duplicate manifest entry: {resolved}")
        output[resolved.casefold()] = {"path": resolved, "sha256": sha(path), "size": path.stat().st_size}
    return {"head": git("rev-parse", "HEAD").decode().strip(), "files": output}


def prepare():
    paths = source_paths()
    base = read_json(ROOT / SCENARIO)
    skills = base["realtime_rules"]["special_skills"]["skills"]
    match = [row for row in skills if row["id"] == "SK-U-GUANYU"]
    if len(match) != 1 or match[0]["effects"].pop("assault_bp") != 3000:
        raise ValueError("invalid source mutation anchor")
    cases = HERE / "cases"
    cases.mkdir(exist_ok=False)
    write_json(cases / "effect_omission.json", base)
    candidates = lexical(paths)
    filtered = [row for row in candidates if (row["path"], row["line"]) != REMOVED]
    if len(filtered) != len(candidates) - 1:
        raise ValueError("invalid candidate mutation anchor")
    write_json(cases / "caller_omission.json", filtered)
    manifest = HERE / "manifest.json"
    write_json(manifest, freeze())
    print(sha(manifest))


def flatten(rows):
    return [(identifier, key, value) for identifier, effects in rows for key, value in effects.items()]


def stable(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def inspect(case):
    paths = source_paths()
    oracle = read_json(HERE / "oracle.json")
    scenario_path = {"missing_input": HERE / "cases/absent.json",
                     "effect_omission": HERE / "cases/effect_omission.json"}.get(case, ROOT / SCENARIO)
    observed = records(scenario_path)
    actual_rows = read_json(HERE / "cases/caller_omission.json") if case == "caller_omission" else lexical(paths)
    expected_rows = sorted((path, line) for path, lines in oracle["callers"].items() for line in lines)
    found_rows = sorted((row["path"], row["line"]) for row in actual_rows)
    expected = flatten(oracle["effects"])
    found = flatten(observed)
    old = {(sid, key): stable(value) for sid, key, value in expected}
    new = {(sid, key): stable(value) for sid, key, value in found}
    if len(old) != len(expected) or len(new) != len(found) or len(set(found_rows)) != len(found_rows):
        raise ValueError("duplicate comparison keys")
    differences = {
        "missing_effects": sorted(old.keys() - new.keys()),
        "added_effects": sorted(new.keys() - old.keys()),
        "changed_effects": sorted(key for key in old.keys() & new.keys() if old[key] != new[key]),
        "missing_callers": sorted(set(expected_rows) - set(found_rows)),
        "added_callers": sorted(set(found_rows) - set(expected_rows)),
    }
    expected_order = [key for key in old if key in new]
    actual_order = [key for key in new if key in old]
    ordered = expected_order == actual_order and [row[0] for row in observed] == [row[0] for row in oracle["effects"]]
    print(json.dumps({"differences": differences, "order_matches": ordered,
                      "skills": len(observed), "effects": len(found),
                      "unique_effect_keys": len({key for _, key, _ in found}), "caller_rows": len(found_rows)},
                     ensure_ascii=True))
    return int(not ordered or any(differences.values()))


def run_suite(out, expected_sha):
    out = out.resolve()
    out.relative_to(HERE)
    out.mkdir(exist_ok=False)
    manifest = HERE / "manifest.json"
    before = freeze()
    if sha(manifest) != expected_sha or before != read_json(manifest):
        raise ValueError("manifest SHA or inputs mismatch")
    write_json(out / "input-before.json", before)
    before_git = git("status", "--porcelain=v1", "-z", "--untracked-files=all")
    (out / "git-before.z").write_bytes(before_git)
    results = {}
    for case, expected_exit in CASES.items():
        command = [sys.executable, str(Path(__file__)), "--case", case]
        process = subprocess.run(command, cwd=ROOT, capture_output=True)
        (out / f"{case}.stdout").write_bytes(process.stdout)
        (out / f"{case}.stderr").write_bytes(process.stderr)
        passed = process.returncode == expected_exit
        if expected_exit == 2:
            passed = passed and not process.stdout and b"absent.json" in process.stderr
        else:
            expected = dict.fromkeys(("missing_effects", "added_effects", "changed_effects", "missing_callers", "added_callers"), [])
            if case == "effect_omission":
                expected["missing_effects"] = [["SK-U-GUANYU", "assault_bp"]]
            if case == "caller_omission":
                expected["missing_callers"] = [list(REMOVED)]
            payload = json.loads(process.stdout) if process.stdout else {}
            counts = (19, 33 - (case == "effect_omission"), 24 - (case == "effect_omission"), 31 - (case == "caller_omission"))
            passed = (passed and not process.stderr and payload.get("order_matches") is True
                      and payload.get("differences") == expected
                      and tuple(payload.get(key) for key in ("skills", "effects", "unique_effect_keys", "caller_rows")) == counts)
        results[case] = {"command": command, "expected_exit": expected_exit, "actual_exit": process.returncode, "passed": passed}
    paths = source_paths()
    rows = lexical(paths)
    write_json(out / "lexical-rows.json", rows)
    observed = records(ROOT / SCENARIO)
    write_json(out / "effect-records.json", observed)
    after = freeze()
    write_json(out / "input-after.json", after)
    after_git = git("status", "--porcelain=v1", "-z", "--untracked-files=all")
    (out / "git-after.z").write_bytes(after_git)
    diff = set(after_git.decode().split("\0")) ^ set(before_git.decode().split("\0"))
    write_json(out / "git-comparison.json", {"changed": sorted(diff)})
    stable_inputs = before == after and sha(manifest) == expected_sha
    passed = stable_inputs and all(result["passed"] for result in results.values())
    write_json(out / "suite.json", {"passed": passed, "stable_inputs": stable_inputs, "inputs": len(after["files"]),
                                   "lexical_accesses": sum(len(row["accesses"]) for row in rows), "cases": results})
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
    return run_suite(args.out, args.manifest_sha256)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        print(f"input or execution error: {error}", file=sys.stderr)
        sys.exit(2)

