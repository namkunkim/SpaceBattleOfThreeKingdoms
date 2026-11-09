"""Generate review-only manifest. Never launches Godot or stages a project."""
from collections import defaultdict
from pathlib import Path
import hashlib
import json
import sys

sys.dont_write_bytecode = True
from overlays_v2 import overlays, SUITES

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
HISTORY = ROOT / "tmp/p02-eighth-20261108"
P6 = ROOT / "tmp/p02-sixth-20261108"
SOURCES = HISTORY / "candidate-k1"
FROZEN = HERE.parent / "EXECUTION-INPUT-FREEZE.json"
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
WORK = HERE / "run-once"
RETURNING = P6 / "returning-settings.cfg"

def read_json(path):
    return json.loads(path.read_bytes())

def sha(content):
    return hashlib.sha256(content).hexdigest()

def identity(path):
    return {"path": str(path), "bytes": path.stat().st_size, "sha256": sha(path.read_bytes())}

rows = defaultdict(list)
jobs = []
dependencies = {}
freeze = read_json(FROZEN)["lanes"]
old = read_json(HISTORY / "k6-proposed-not-run/proposed-jobs.json")

def job(row, lane, case, probe, timeout, users=(), settings=None, gui=False, exits=(0,)):
    pid = f"{row:02d}-{lane}-{case}"
    dest = WORK / pid
    project = dest / "project"
    output = dest / "observations.gdvar"
    stage = "instrumented-k4" if lane == "instrumented" else lane
    source = SOURCES / stage
    rel = "res://_p02_k6_" + pid.replace("-", "_") + ".gd" if probe else f"res://tests/{case}.gd"
    args = [str(ENGINE)] + ([] if gui else ["--headless"]) + ["--path", str(project), "--script", rel]
    if users:
        args += ["--", *(str(x).replace("{raw}", str(output)).replace("{dir}", str(dest)) for x in users)]
    specific = overlays(source, lane, case)
    files = [p for p in (probe, settings) if p]
    if not probe:
        files.append(source / "tests" / (case + ".gd"))
    dep = [identity(p) for p in files]
    for x in dep:
        dependencies[x["path"]] = x
    rows[row].append(pid)
    env = {"APPDATA": str(dest / "roaming"), "LOCALAPPDATA": str(dest / "local"),
           "XDG_DATA_HOME": str(dest / "roaming"), "SBTK_SAFE_INSETS": "0,0,0",
           "P02_PROBE_MODE": "", "P02_K6_INITIAL_GUARD": ""}
    jobs.append({"process_id": pid, "row_id": row, "lane": lane, "case_id": case,
                 "exact_argv": args, "cwd": str(project), "environment_overrides": env,
                 "source": str(source), "project_input_identity": {"path":str(FROZEN), "lane":lane, "count":len(freeze[lane])},
                 "test_only_overlays": {n: {"before": identity(source / n), "after_sha256": sha(data), "after_bytes":len(data)}
                                        for n, data in specific.items()},
                 "dependency_files": dep, "probe": str(probe) if probe else None, "returning_settings": str(settings) if settings else None,
                 "settings_destination": str(dest / "roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/settings.cfg") if settings else None,
                 "stdout": str(dest / "stdout.raw"), "stderr": str(dest / "stderr.raw"), "raw":str(output) if "{raw}" in users else None,
                 "artifact_root":str(dest), "timeout_seconds":timeout, "kill_wait_seconds":10, "expected_exit":exits,
                 "ordered_dependencies": [jobs[-1]["process_id"]] if jobs else []})

for lane in ("before", "after"):
    for row, diff in enumerate(("입문","표준","상급","극한"),1):
        job(row,lane,"native",HERE/"native_v2.gd",320,(lane,"{raw}",diff))
    job(5,lane,"deployment",HERE/"deployment_v2.gd",150,("{raw}",),RETURNING)
    job(6,lane,"poc",HERE/"native_v2.gd",120,(lane,"{raw}","poc"))
    job(7,lane,"alias",HERE/"alias.gd",280,("{raw}",))
    rows[8].append(rows[7][-1])
    job(10,lane,"guard-active",HERE/"rejection_v2.gd",120,(lane,"guard-active","{raw}"),RETURNING)
    job(11,lane,"invalid-brief",HERE/"native_v2.gd",90,(lane,"{raw}","invalid-brief"))
    job(12,lane,"guard-initial",HERE/"rejection_v2.gd",120,(lane,"guard-initial","{raw}"),RETURNING)

job(9,"after","contract",HERE/"rejection_v2.gd",120,("after","contract","{raw}"),RETURNING)

for row, case in ((9,"contract"),(10,"guard-active"),(13,"mode-active"),(13,"mode-initial")):
    job(row,"instrumented",case,HERE/"rejection_v2.gd",120,("instrumented",case,"{raw}"),RETURNING)

for lane in ("before","after","instrumented"):
    job(14,lane,"retry",HERE/"retry.gd",630,(lane,"{raw}"),RETURNING)

for lane in ("before","after"):
    for row, case in ((15,"gui-mouse"),(16,"gui-key")):
        # Nonce must be replaced by a one-time token before independent final freeze.
        job(row,lane,case,HERE/"gui.gd",480,(f"FREEZE_REQUIRED-{lane}-{case}","{dir}",case),RETURNING,True)
    for prior in (x for x in old["jobs"] if x["stage"] == lane):
        case = prior["case"]
        if case in ("native","alias","retry"):
            continue
        row = 17 if case == "world-complete" else 18 if case == "world-cancel" else 21 if case.startswith("world-") else 20 if case in ("battle_flow","autoresolve") else 19
        probe = Path(prior["probe"]) if prior["probe"] else None
        users = (case.split("-")[1],"{raw}") if row in (17,18) else ()
        job(row,lane,case,probe,320 if row in (17,18,21) else 400,users,Path(prior["user_config"]) if prior["user_config"] else None,exits=(0,1) if case == "world-clean" else (0,))

assert sorted(rows) == list(range(1,22))
for j in jobs:
    j["assertion_index"] = "ordinal and original label from K6_SUITE_ASSERT" if j["case_id"] in SUITES or j["row_id"] in (19, 20) else "ASSERT labels and typed records per ORACLES.md and ORACLES-V2.md"
    j["row_ids"] = [row for row, ids in sorted(rows.items()) if j["process_id"] in ids]
seconds = sum(j["timeout_seconds"] for j in jobs)
cleanup = sum(j["kill_wait_seconds"] for j in jobs)
reserve = 1200
assert seconds + cleanup + reserve <= 21600, (seconds,cleanup,reserve)

paths = [HERE / n for n in ("window_identity.py", "overlays.py", "make_manifest.py", "make_manifest_v2.py", "runner_v2.py", "overlays_v2.py", "derive_v2.py", "ORACLES.md", "ORACLES-V2.md")]
paths += [FROZEN, HERE.parent/"WORKSPACE-FREEZE.json", HERE.parent/"RESUME-PLAN.md",
          HERE.parent/"K6-EXECUTION-CONTRACT.md", HISTORY/"candidate-product.patch", SOURCES/"engine.json",
          ENGINE, ENGINE.with_name(ENGINE.name.replace("_console",""))]
paths += [ROOT / p for p in old["copy_supplemental_rel_paths"]]
for p in paths:
    d = identity(p)
    dependencies[d["path"]] = d
manifest = {"status": "BLOCKED_REVIEW_ONLY_NO_EXECUTION", "rows":dict(sorted(rows.items())), "jobs":jobs,
            "project_source_lanes":str(FROZEN), "dependencies":dependencies,
            "supplemental_rel_paths":old["copy_supplemental_rel_paths"],
            "replica_output_dirs":old["create_replica_output_dirs"],
            "timing":{"unique_processes":len(jobs),"external_timeouts":seconds,"cleanup":cleanup,"reserve":reserve,"serial_cap_seconds":seconds+cleanup+reserve},
            "gates_open":["independent re-review and authorization","GUI nonce and Sky/Win32 matching and provenance mechanism","final coverage and static probe review"]}
with (HERE / "MANIFEST-V2-REVIEW-ONLY.json").open("x", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
print(manifest["timing"])
