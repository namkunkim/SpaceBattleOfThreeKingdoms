"""Evidence runner for the thirteen named P03 checks."""

import argparse
import copy
import json
from pathlib import Path
import subprocess
import sys

from inventory import FORMAT, encode, sha256


HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
TOOL = HERE / "inventory.py"
ORACLE = HERE / "oracle-20261107.json"
BASELINE = HERE / "declaration-baseline.json"
OLD = HERE / "oracle-candidate-v2.json"
SOURCE = "core/battle/example.gd"
EXAMPLE = b"class_name Example\nextends RefCounted\nvar alpha: int = 1\nvar beta := 2\n"


def write_new(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("xb") as file:
        file.write(data)


def hash_inputs(root, baseline):
    files = [Path(sys.executable), TOOL, Path(__file__).resolve(), ORACLE, OLD, BASELINE]
    if baseline:
        files.append(baseline)
    files.extend(sorted((root / "core" / "battle").rglob("*.gd")))
    return {str(p): sha256(p.read_bytes()) for p in files}


class Runner:
    def __init__(self, directory):
        self.directory = directory
        self.invocations = 0
        self.cases = []

    def invoke(self, label, root, expect=0, baseline=None, cwd=REPO, injection=None, extra=()):
        self.invocations += 1
        run = self.directory / f"call-{self.invocations:02}"
        run.mkdir()
        command = [sys.executable, "-B"]
        if injection:
            command += ["-c", injection]
        else:
            command.append(str(TOOL))
        command += ["check" if baseline else "collect", "--root", str(root)]
        if baseline:
            command += ["--baseline", str(baseline)]
        command += extra
        before = hash_inputs(root, baseline)
        process = subprocess.run(command, cwd=cwd, capture_output=True, check=False)
        after = hash_inputs(root, baseline)
        write_new(run / "stdout.bin", process.stdout)
        write_new(run / "stderr.bin", process.stderr)
        write_new(run / "run.json", encode({
            "label": label, "expected_exit": expect, "actual_exit": process.returncode,
            "argv": command, "cwd": str(cwd), "python_version": sys.version,
            "input_manifest_sha256_before": sha256(encode(before)),
            "input_manifest_sha256_after": sha256(encode(after)),
            "before": before, "after": after,
        }))
        assert before == after, label
        assert process.returncode == expect, (label, process.returncode, process.stderr)
        if expect == 2:
            assert not process.stdout and process.stderr, label
            return process.stderr
        assert not process.stderr, (label, process.stderr)
        return process.stdout

    def fixture(self, label, data, path=SOURCE):
        root = self.directory / "fixtures" / label
        write_new(root / path, data)
        return root

    def parsed(self, label, data, path=SOURCE):
        root = self.fixture(label, data, path)
        return json.loads(self.invoke(label, root))

    def drift(self, label, data, baseline):
        root = self.fixture(label, data)
        return json.loads(self.invoke(label, root, 1, baseline))["changes"][0]

    def test(self, name, function):
        start = self.invocations
        function()
        self.cases.append({"name": name, "processes": self.invocations - start})
        print(f"PASS {name}", flush=True)


def test_all(runner):
    r = runner

    def members():
        data = b"class_name BattleState\nextends RefCounted\nclass Missile:\n\tvar id := 0\nstatic var count := 1\nfunc test():\n\tvar local := 2\n"
        got = r.parsed("members-inner", data, "core/battle/battle_state.gd")["files"][0]["members"]
        assert got == [
            {"scope": "BattleState.Missile", "name": "id", "static": False, "line": 4, "raw": "\tvar id := 0"},
            {"scope": "BattleState", "name": "count", "static": True, "line": 5, "raw": "static var count := 1"},
        ]
    r.test("p03_01_members_and_inner_scope", members)

    def strings():
        raw = r"""var alpha := "var x # \" escaped" # var beta"""
        data = ('# var fake\n' + raw + '\nfunc f():\n\tvar text := "var hidden"\n').encode()
        got = r.parsed("strings", data)["files"][0]["members"]
        assert len(got) == 1 and got[0]["name"] == "alpha" and got[0]["raw"] == raw
    r.test("p03_02_strings_comments", strings)

    def multiline():
        raw = 'var table: Dictionary = {\n\t"items": [1, "# : get = fake", {"x": 4}], # tail\n}'
        got = r.parsed("multiline", (raw + "\n").encode())["files"][0]["members"]
        assert len(got) == 1 and got[0]["raw"] == raw
    r.test("p03_03_multiline_initializer", multiline)

    baseline = r.directory / "fixtures" / "sample-baseline.json"
    literal = {"format": FORMAT, "files": [{"path": SOURCE, "sha256": sha256(EXAMPLE), "members": [
        {"scope": "Example", "name": "alpha", "static": False, "line": 3, "raw": "var alpha: int = 1"},
        {"scope": "Example", "name": "beta", "static": False, "line": 4, "raw": "var beta := 2"},
    ]}]}
    write_new(baseline, encode(literal))

    def added():
        assert r.drift("added", EXAMPLE + b"var gamma := 3\n", baseline)["added"] == [["Example", "gamma"]]
    r.test("p03_04_added_member", added)

    def removed():
        assert r.drift("removed", EXAMPLE.replace(b"var beta := 2\n", b""), baseline)["removed"] == [["Example", "beta"]]
    r.test("p03_05_removed_member", removed)

    def type_init_order():
        assert r.drift("type", EXAMPLE.replace(b"int", b"float"), baseline)["changed"] == [["Example", "alpha"]]
        assert r.drift("initializer", EXAMPLE.replace(b"= 1", b"= 3"), baseline)["changed"] == [["Example", "alpha"]]
        swapped = b"class_name Example\nextends RefCounted\nvar beta := 2\nvar alpha: int = 1\n"
        change = r.drift("order", swapped, baseline)
        assert change["order_changed"] and not change["changed"]
    r.test("p03_06_type_initializer_order", type_init_order)

    def file_changes():
        extra = "core/battle/zero.gd"
        root = r.fixture("new-file", EXAMPLE)
        write_new(root / extra, b"extends RefCounted\n")
        assert json.loads(r.invoke("new-file", root, 1, baseline))["changes"] == [{"path": extra, "file": "added"}]
        root = r.fixture("removed-file", b"extends RefCounted\n", extra)
        augmented = copy.deepcopy(literal)
        augmented["files"].append({"path": extra, "sha256": sha256(b"extends RefCounted\n"), "members": []})
        before = r.directory / "fixtures" / "two-files-baseline.json"
        write_new(before, encode(augmented))
        assert json.loads(r.invoke("removed-file", root, 1, before))["changes"] == [{"path": SOURCE, "file": "removed"}]
    r.test("p03_07_new_removed_file", file_changes)

    def local_drift():
        change = r.drift("local", EXAMPLE + b"func f():\n\tvar local = 9\n", baseline)
        assert change["sha_drift"] and not any(change[key] for key in ("added", "removed", "changed", "order_changed"))
    r.test("p03_08_local_only_code_drift", local_drift)

    def unsupported():
        examples = {
            "annotation-inline": b"@export var hidden := 1\n",
            "annotation-split": b"@export\nvar hidden := 1\n",
            "new-inner": b"class New:\n\tvar hidden := 1\n",
            "getter": b"var a: int:\n\tget:\n\t\treturn 1\n",
            "setter": b"var a := 0:\n\tset(value):\n\t\ta = value\n",
            "unknown": b"unexpected member\n",
            "triple": b'var a := """\nvar hidden := 1\n"""\n',
            "unclosed-string": b'var a := "unfinished\n',
            "unclosed-delimiter": b"var a := [1, 2\n",
            "wrong-delimiter": b"var a := [1, 2}\n",
            "unfinished-var": b"var a :=\n",
            "backslash": b"var a := 1 " + bytes([92]) + b"\n\t+ 2\n",
            "duplicate-source-member": b"var a := 1\nvar a := 2\n",
            "inline-typed-getter": b"var a: int = 0: get = _get\n",
            "inline-inferred-setter": b"var a := 0: set = _set\n",
            "inline-typed-uninitialized-getter": b"var a: int: get = _get\n",
            "inline-untyped-uninitialized-setter": b"var a: set = _set\n",
            "same-line-members": b"var a := 0; var b := 1\n",
        }
        for label, data in examples.items():
            r.invoke(label, r.fixture(label, data), 2)
        function = b"func f():\n\tvar local := 1 " + bytes([92])
        valid = function + b"\n\t\t+ 2\nvar member := 4\n"
        assert [m["name"] for m in r.parsed("function-continuation", valid)["files"][0]["members"]] == ["member"]
        for label, tail in (
            ("function-dangling", b""),
            ("function-blank-next", b"\n\n\t\t+ 2\n"),
            ("function-comment-next", b"\n\t\t# + 2\n"),
            ("function-nonterminal", b" + 2\n"),
        ):
            r.invoke(label, r.fixture(label, function + tail), 2)
    r.test("p03_09_unsupported_syntax", unsupported)

    def baseline_errors():
        root = r.fixture("baseline-errors", EXAMPLE)
        duplicate = copy.deepcopy(literal)
        duplicate["files"][0]["members"][1].update(name="alpha")
        missing = copy.deepcopy(literal)
        del missing["files"][0]["members"][0]["raw"]
        path_duplicate = copy.deepcopy(literal)
        path_duplicate["files"].extend(path_duplicate["files"][:])
        for name, data in (("broken-json", b"{"), ("duplicate-identity", encode(duplicate)),
                           ("missing-key", encode(missing)), ("duplicate-path", encode(path_duplicate))):
            broken = r.directory / "fixtures" / f"{name}.json"
            write_new(broken, data)
            r.invoke(name, root, 2, broken)
    r.test("p03_10_malformed_baseline", baseline_errors)

    def read_only():
        root = r.fixture("readonly", EXAMPLE)
        r.invoke("readonly-normal", root, 0, baseline)
        malformed = r.fixture("invalid-utf8", b"\xff")
        r.invoke("invalid-utf8", malformed, 2, baseline)
        preamble = f"import sys; sys.path.insert(0, {str(HERE)!r}); import inventory as i\n"
        for label, exception in (("missing-after-list", "FileNotFoundError"), ("unreadable", "PermissionError")):
            script = preamble + f"""
read = i.read_plain
def broken(path):
    if path.suffix == '.gd':
        raise {exception}('injected {label}')
    return read(path)
i.read_plain = broken
raise SystemExit(i.main())
"""
            assert label.encode() in r.invoke(label, root, 2, baseline, injection=script)
        script = preamble + """
read = i.read_plain
reads = 0
def changed(path):
    global reads
    data = read(path)
    if path.suffix == '.gd':
        reads += 1
        if reads == 2:
            return data + b'# simulated different bytes'
    return data
i.read_plain = changed
raise SystemExit(i.main())
"""
        assert b"source bytes changed" in r.invoke("sha-change", root, 2, baseline, injection=script)
        occupied = r.directory / "fixtures" / "occupied.out"
        write_new(occupied, b"keep this exact output")
        r.invoke("unsupported-output-argument", root, 2, baseline, extra=("--output", str(occupied)))
        assert occupied.read_bytes() == b"keep this exact output"
        occupied_dir = r.directory / "fixtures" / "occupied-dir"
        occupied_dir.mkdir()
        write_new(occupied_dir / "stdout.bin", b"previous output")
        r.invoke("existing-evidence-directory", root, 2, injection=(
            f"import runpy,sys; sys.path.insert(0, {str(HERE)!r}); sys.argv = [{str(Path(__file__).resolve())!r}, "
            f"'--run-dir', {str(occupied_dir)!r}]; runpy.run_path(sys.argv[0],run_name='__main__')"
        ))
        assert list(occupied_dir.iterdir()) == [occupied_dir / "stdout.bin"]
        assert (occupied_dir / "stdout.bin").read_bytes() == b"previous output"
    r.test("p03_11_readonly_failure", read_only)

    def deterministic():
        root = r.fixture("deterministic", EXAMPLE)
        first = r.invoke("deterministic-first", root)
        assert first == r.invoke("deterministic-second", root)
        assert first == r.invoke("foreign-cwd", root, cwd=r.directory)
    r.test("p03_12_deterministic_and_foreign_cwd", deterministic)

    def current():
        expected = json.loads(ORACLE.read_bytes())["files"]
        got = json.loads(r.invoke("current-source-oracle", REPO))["files"]
        assert len(got) == 31 and sum(len(f["members"]) for f in got) == 294
        assert got == expected
        assert json.loads(r.invoke("current-source-baseline", REPO, 0, BASELINE)) == {"equal": True, "changes": []}
        historic = r.directory / "fixtures" / "historic-baseline.json"
        write_new(historic, encode({"format": FORMAT, "files": json.loads(OLD.read_bytes())["files"]}))
        assert json.loads(r.invoke("historical-baseline-drift", REPO, 1, historic))["changes"] == [
            {"path": "core/battle/operation_private_state.gd", "sha_drift": True,
             "added": [], "removed": [], "changed": [], "order_changed": False},
            {"path": "core/battle/operation_runtime_adapter.gd", "file": "added"},
        ]
    r.test("p03_13_current_source_crosscheck", current)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    directory = args.run_dir.absolute()
    try:
        directory.mkdir()
    except OSError as error:
        print(f"evidence directory reservation: {error}", file=sys.stderr)
        return 2
    runner = Runner(directory)
    before = hash_inputs(REPO, None)
    try:
        test_all(runner)
        assert len(runner.cases) == 13
    finally:
        after = hash_inputs(REPO, None)
        write_new(directory / "suite.json", encode({
            "named_cases": runner.cases, "process_invocations": runner.invocations,
            "before": before, "after": after, "python_version": sys.version,
            "stable": before == after,
        }))
    assert before == after
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
