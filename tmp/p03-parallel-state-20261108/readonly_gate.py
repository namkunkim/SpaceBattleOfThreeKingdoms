import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SOURCES = tuple(f"core/battle/{name}.gd" for name in ("battle_state", "fleet_state", "tick_clock", "battle_rng"))
CASES = {
    "baseline": (0, {}),
    "omission": (1, {0: ("var _idx_n := -1\n", "")}),
    "rename": (1, {1: ("var target_id := -1\n", "var target_id_probe := -1\n")}),
    "missing": (2, {}),
    "nested": (1, {0: ("class Missile:\n", "class MissileProbe:\n")}),
    "ignored": (0, {0: ("func clock_s() -> float:\n",
                        "# var root_comment_probe := 0\nfunc clock_s() -> float:\n\tvar local_probe := 0\n")}),
    "duplicate": (2, {1: ("var target_id := -1\n", "var target_id := -1\nvar target_id := -1\n")}),
}
DECLARATION = re.compile(r"var ([A-Za-z_]\w*)(?=\s*(?:[:=]|$))")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def expected_oracle():
    rows = []
    for line in (HERE / "STATE-LEDGER-S1.md").read_text(encoding="utf-8-sig").splitlines():
        match = re.match(r"^\| (\w+) \| \x60([^\x60]+)\x60 \|", line)
        if match:
            owner, fields = match.groups()
            source = SOURCES[{"BattleState": 0, "Missile": 0, "Swarm": 0,
                              "FleetState": 1, "TickClock": 2, "BattleRng": 3}[owner]]
            rows.extend((source, owner, name) for name in fields.split(","))
    if len(rows) != 172 or len(set(rows)) != 172:
        raise ValueError("invalid independent ledger")
    return sorted(rows)


def candidate_text(source, mutation):
    text = (ROOT / source).read_text(encoding="utf-8-sig")
    if mutation:
        before, after = mutation
        if text.count(before) != 1:
            raise ValueError(f"ambiguous mutation: {source}")
        text = text.replace(before, after)
    return text


def input_paths(case):
    if case == "missing":
        return [SOURCES[0], "tmp/p03-parallel-state-20261108/cases/absent.gd", *SOURCES[2:]]
    return [
        f"tmp/p03-parallel-state-20261108/cases/{case}/{Path(path).name}"
        if index in CASES[case][1] else path for index, path in enumerate(SOURCES)
    ]


def frozen_paths():
    return sorted({
        *SOURCES, *(path for case in CASES if case != "missing" for path in input_paths(case)),
        *(str(path.relative_to(ROOT)).replace("\\", "/") for path in (
            HERE / "readonly_gate.py", HERE / "oracle-approved.json",
            HERE / "STATE-LEDGER-S1.md", HERE / "READONLY-PREPLAN.sha256",
        )),
    })


def prepare():
    for line in (HERE / "READONLY-PREPLAN.sha256").read_text(encoding="utf-8-sig").splitlines():
        sha, path = line.split("  ", 1)
        if digest(ROOT / path) != sha:
            raise ValueError(f"pre-plan drift: {path}")
    save(HERE / "oracle-approved.json", expected_oracle())
    for case, (_, changes) in CASES.items():
        for index, mutation in changes.items():
            candidate = ROOT / input_paths(case)[index]
            candidate.parent.mkdir(parents=True, exist_ok=True)
            candidate.write_text(candidate_text(SOURCES[index], mutation), encoding="utf-8", newline="\n")
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    manifest = HERE / "readonly-manifest.json"
    save(manifest, {
        "files": [{"path": path, "sha256": digest(ROOT / path)} for path in frozen_paths()],
        "python": {"path": sys.executable, "sha256": digest(Path(sys.executable))},
        "head": head,
    })
    print(digest(manifest))


def validate_manifest(manifest, sha):
    if digest(manifest) != sha:
        raise ValueError("manifest hash mismatch")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    seen = set()
    for item in data["files"]:
        path = item["path"].replace("\\", "/")
        if path.casefold() in seen or path not in frozen_paths():
            raise ValueError(f"duplicate or unexpected path: {path}")
        seen.add(path.casefold())
        if digest(ROOT / path) != item["sha256"]:
            raise ValueError(f"input hash mismatch: {path}")
    if seen != {path.casefold() for path in frozen_paths()}:
        raise ValueError("manifest paths missing")
    if sys.executable != data["python"]["path"] or digest(Path(sys.executable)) != data["python"]["sha256"]:
        raise ValueError("Python executable drift")
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    if head != data["head"]:
        raise ValueError("HEAD drift")


def declarations(path, source):
    outer = None
    nested = None
    found = {}
    for number, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        stripped = line.lstrip()
        if not stripped or stripped.startswith("#"):
            continue
        prefix = line[:len(line) - len(stripped)]
        if set(prefix) - {"\t"}:
            raise ValueError(f"unsupported indentation: {source}:{number}")
        if not prefix:
            nested = None
            if stripped.startswith("class_name "):
                if outer is not None:
                    raise ValueError(f"duplicate class_name: {source}:{number}")
                outer = stripped.split()[1]
                continue
            nested_class = re.fullmatch(r"class ([A-Za-z_]\w*):", stripped)
            if nested_class:
                nested = nested_class.group(1)
                continue
        if not stripped.startswith("var ") or (prefix and not (prefix == "\t" and nested)):
            continue
        match = DECLARATION.match(stripped.split("#", 1)[0])
        if not match or not outer:
            raise ValueError(f"unsupported declaration: {source}:{number}")
        key = (source, nested or outer, match.group(1))
        if key in found:
            raise ValueError(f"duplicate declaration: {'/'.join(key)} lines {found[key]},{number}")
        found[key] = number
    if not outer:
        raise ValueError(f"class_name missing: {source}")
    return set(found)


def inspect(case, oracle):
    actual = set()
    for logical, path in zip(SOURCES, input_paths(case)):
        actual.update(declarations(ROOT / path, logical))
    result = {"missing": sorted(oracle - actual), "added": sorted(actual - oracle)}
    print(json.dumps(result))
    return int(bool(result["missing"] or result["added"]))


def differences(case, oracle):
    if case == "omission":
        return {"missing": [[SOURCES[0], "BattleState", "_idx_n"]], "added": []}
    if case == "rename":
        return {"missing": [[SOURCES[1], "FleetState", "target_id"]],
                "added": [[SOURCES[1], "FleetState", "target_id_probe"]]}
    if case == "nested":
        old = sorted(item for item in oracle if item[1] == "Missile")
        return {"missing": [list(item) for item in old],
                "added": [[item[0], "MissileProbe", item[2]] for item in old]}
    return {"missing": [], "added": []}


def suite(args, oracle):
    out = args.out.resolve()
    out.relative_to(HERE / "runs")
    out.mkdir(parents=True, exist_ok=False)
    validate_manifest(args.manifest, args.manifest_sha256)
    results = {}
    for case, (code, mutations) in CASES.items():
        for index, mutation in mutations.items():
            candidate = ROOT / input_paths(case)[index]
            if candidate.read_text(encoding="utf-8") != candidate_text(SOURCES[index], mutation):
                raise ValueError(f"candidate content mismatch: {candidate}")
        command = [sys.executable, str(Path(__file__).resolve()), "--case", case]
        completed = subprocess.run(command, cwd=ROOT, capture_output=True)
        (out / f"{case}.stdout").write_bytes(completed.stdout)
        (out / f"{case}.stderr").write_bytes(completed.stderr)
        matched = completed.returncode == code
        if code == 2:
            diagnostic = "absent.gd" if case == "missing" else "duplicate declaration: core/battle/fleet_state.gd/FleetState/target_id"
            matched = matched and not completed.stdout and diagnostic.encode() in completed.stderr
        else:
            matched = matched and not completed.stderr and json.loads(completed.stdout) == differences(case, oracle)
        results[case] = {"command": command, "expected_exit": code, "actual_exit": completed.returncode, "match": matched}
    validate_manifest(args.manifest, args.manifest_sha256)
    save(out / "suite.json", results)
    return int(not all(result["match"] for result in results.values()))


def main():
    parser = argparse.ArgumentParser()
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--prepare", action="store_true")
    action.add_argument("--run-cases", action="store_true")
    action.add_argument("--case", choices=CASES)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--manifest-sha256")
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    if args.prepare:
        prepare()
        return 0
    oracle = {tuple(item) for item in json.loads((HERE / "oracle-approved.json").read_text(encoding="utf-8"))}
    if args.case:
        return inspect(args.case, oracle)
    return suite(args, oracle)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"input or execution error: {error}", file=sys.stderr)
        sys.exit(2)

