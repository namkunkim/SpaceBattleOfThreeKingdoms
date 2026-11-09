"""Freeze the draft W1-W5 inputs. No launcher or engine is called."""
from hashlib import sha256
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parent
workspace = root.parents[3]
python = Path(sys.executable).resolve()
broker = workspace / "tmp/p02-eighth-resume-8d838216ccfc/prepared/owned_job_v3.py"
console = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
gui = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe")
inputs = (python, broker, console, gui, root / "minimal/project.godot", root / "minimal/probe.gd", Path(__file__))
manifest = {
    "status": "REVIEW_ONLY_NON_EXECUTABLE",
    "no_product_resources": True,
    "frozen_sources": {str(p): sha256(p.read_bytes()).hexdigest() for p in inputs},
    "missing_gates": [
        "sandbox-backed filesystem write confinement and pre/post reparse boundary",
        "outer/inner supervisor executable and independent Job/process HANDLE recorder",
        "actual environment and controller argv",
        "independent review",
    ],
    "cases": [],
}
for name, mode, block, hard, inner in [
    ("W1", "normal", None, 40, 30),
    ("W2", "wait", None, 40, 15),
    ("W3", None, "staging", 8, None),
    ("W4", "normal", "postverify", 8, 6),
    ("W5", None, "actual-nested-policy-only", 8, None),
]:
    stage = root / "never-run-with-draft" / name
    project = stage / "project"
    environment = {k: str(stage / v) for k,v in {
        "APPDATA":"roaming", "LOCALAPPDATA":"local", "XDG_DATA_HOME":"roaming",
        "XDG_CONFIG_HOME":"config", "XDG_CACHE_HOME":"cache", "TEMP":"temp", "TMP":"temp",
    }.items()}
    argv = None if mode is None else [str(console), "--headless", "--path", str(project), "--script", "res://probe.gd", "--", mode]
    manifest["cases"].append({
        "id": name, "blocking_phase": block, "cwd": str(project), "env_overrides": environment,
        "engine_argv": argv, "stdout": str(stage / "engine.stdout"), "stderr": str(stage / "engine.stderr"),
        "hard_seconds_from_before_staging": hard, "engine_seconds_from_barrier": inner,
        "inner_cleanup_seconds": 5, "external_drain_verification_seconds": 5,
        "expected_user_data_dir": str(stage / "roaming/Godot/app_userdata/P02WatchdogNonProduct"),
    })
(root / "WATCHDOG-DRAFT-INPUTS.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf8",newline="\n")
