from datetime import datetime
import hashlib
import json

from launch import HERE, write_json
from preservation_exit import trace_evidence, freeze
from preservation_preflight import TRACE_PARENTS

folder = HERE / "synthetic-exit-fixture"
folder.mkdir()
mode = folder / "gate-k1" / "before-world-clean"
trace_parent = mode / "roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces"
trace_parent.mkdir(parents=True)
logs = trace_parent.parent / "logs"
logs.mkdir()
candidate = folder / "candidate-k1/before"
candidate.mkdir(parents=True)
own = folder / "reserved"
own.mkdir()
trace = trace_parent / "battle-2026-11-08T18-10-20-4008-1.jsonl"
trace.write_text('{"kind":"session_start","wall_time":"2026-11-08T18:10:20"}\n', encoding="utf-8")
digest = hashlib.sha256(trace.read_bytes()).hexdigest()
record = {"type": "file", "bytes": trace.stat().st_size, "sha256": digest}
relative = str(trace.relative_to(trace_parent.parent))
write_json(mode / "command.json", {"env": {"APPDATA": str(mode / "roaming"), "LOCALAPPDATA": str(mode / "local")},
                                  "args": ["godot", "--path", str(candidate)], "user_before": {}})
write_json(mode / "process.json", {"engine_pid": 4008, "user_after": {relative: digest}})
(logs / "godot.log").write_text(f"[TRACE] {trace.as_posix()}\n", encoding="utf-8")
window = datetime(2026, 11, 8, 18, 10, 19), datetime(2026, 11, 8, 18, 10, 21)

def evidence(pids, times=window):
    return trace_evidence(trace, record, own, pids, *times, trace_parents=(trace_parent,))

results = {
    "matched_independent_command_process_log_trace": bool(evidence({999})),
    "own_pid_rejected": evidence({4008}) is None,
    "unavailable_own_pid_rejected": evidence(set()) is None,
    "outside_window_rejected": evidence({999}, (window[1], window[1])) is None,
    "archive_frozen": freeze([trace])[str(trace)] == record,
}
process_path = mode / "process.json"
process_path.write_text(json.dumps({"user_after": {relative: digest}}), encoding="utf-8")
results["missing_independent_pid_rejected"] = evidence({999}) is None
process_path.write_text(json.dumps({"engine_pid": 4008, "user_after": {relative: "bad"}}), encoding="utf-8")
results["mismatched_trace_hash_rejected"] = evidence({999}) is None
try:
    freeze([folder / "missing"])
except (OSError, ValueError):
    results["missing_protected_root_rejected"] = True
else:
    results["missing_protected_root_rejected"] = False
actual = sorted(TRACE_PARENTS[0].glob("battle-*.jsonl"))[0]
actual_mode = actual.parent.parents[4]
actual_manifest = json.loads((actual_mode / "process.json").read_text(encoding="utf-8"))
results["actual_P02_process_manifest_lacks_independent_pid"] = "engine_pid" not in actual_manifest
write_json(HERE / "PRESERVATION-EXIT-SYNTHETIC.json", results)
assert all(results.values()), results
print(json.dumps(results))
