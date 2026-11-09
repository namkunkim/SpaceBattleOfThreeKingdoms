"""Drive the production integrated gate with a synthetic process, never Godot."""
import json
from pathlib import Path
from unittest.mock import patch

import launch_preserved as gate

fixtures = gate.HERE / "integrated-gate-fixture-v3"
fixtures.mkdir()
sample = fixtures / "protected.txt"
sample.write_text("baseline", encoding="utf-8")
base = [gate.HERE / "PLAN.md", gate.REVISION, sample]
results = {}
sibling = gate.HERE / "synthetic-existing-sibling.txt"


class FakeJob:
    def __enter__(self):
        return self

    def __exit__(self, *_):
        pass

    def assign_and_resume(self, pid):
        assert pid == 111

    def accounting(self):
        return {"active": 0, "total": 2}


class FakeProcess:
    pid = 111
    returncode = 0

    def __init__(self, argv, cwd, stdout, stderr, env, creationflags):
        prefix = Path(env["APPDATA"]).parent
        assert Path(env["APPDATA"]).is_dir()
        assert all(Path(env[key]).is_relative_to(prefix) for key in ("APPDATA", "LOCALAPPDATA", "TMP", "TEMP"))
        rows = []
        ids = []
        for name in gate.NAMES:
            rows.append(f"CASE_START {name}")
            for index in range(1, 9):
                id_ = f"{name}:{index}"
                ids.append(id_)
                rows.append(f"CHECK {id_} PASS")
            rows.append(f"CASE_END {name}")
        rows.append("PROBE_RESULT " + json.dumps({
            "engine_pid": 222, "engine_path": str(gate.BODY), "ok": True, "ids": ids, "checks": 32,
        }))
        stdout.write(("\n".join(rows) + "\n").encode())
        if active_case == "changed":
            sample.write_text("changed", encoding="utf-8")
        if active_case == "deleted":
            sample.unlink()
        if active_case == "unexpected":
            (fixtures / "new.txt").write_text("new", encoding="utf-8")
        if active_case == "own_sibling_changed":
            sibling.write_text("changed", encoding="utf-8")
        if active_case == "own_sibling_created":
            (gate.HERE / "synthetic-unreserved-sibling.txt").write_text("new", encoding="utf-8")
        if active_case == "own_attempt_unreserved":
            (prefix / "unexpected.txt").write_text("new", encoding="utf-8")
        if active_case == "exit_failure":
            self.returncode = 1

    def wait(self, timeout):
        return self.returncode


def fake_snapshot(folder, phase):
    for suffix in ("status.bin", "status-stderr.bin"):
        (folder / f"{phase}-{suffix}").write_bytes(b"")
    return b"same-head"


for active_case in ("stable", "changed", "deleted", "unexpected", "exit_failure", "own_sibling_changed", "own_sibling_created", "own_attempt_unreserved"):
    sibling.write_text("baseline", encoding="utf-8")
    sample.write_text("baseline", encoding="utf-8")
    name = f"synthetic-v3-gate-{active_case}"
    with patch.object(gate, "sources", return_value=base), patch.object(gate, "protection_roots", return_value=[fixtures]), \
         patch.object(gate, "snapshot", side_effect=fake_snapshot), patch.object(gate, "LauncherJob", FakeJob), \
         patch.object(gate.subprocess, "Popen", FakeProcess):
        exit_code = gate.main(name)
    data = json.loads((gate.HERE / name / "run.json").read_text())
    results[active_case] = {
        "gate": data["gate_passed"], "hard_stop": data["hard_stop"], "actual_exit": data["actual_exit"],
        "synthetic_gate_exit": exit_code,
    }
    assert data["gate_passed"] == (active_case == "stable"), (active_case, data)
    assert data["hard_stop"] == (active_case in {"changed", "deleted", "unexpected", "own_sibling_changed", "own_sibling_created", "own_attempt_unreserved"}), (active_case, data)

with patch.object(gate.subprocess, "Popen", side_effect=AssertionError("process must not start")):
    try:
        gate.main("synthetic-v3-gate-stable")
    except FileExistsError:
        results["reservation_collision"] = True
    else:
        raise AssertionError("existing reservation accepted")

gate.write_json(gate.HERE / "PRESERVATION-INTEGRATED-V3-SYNTHETIC.json", results)
print(json.dumps(results))
