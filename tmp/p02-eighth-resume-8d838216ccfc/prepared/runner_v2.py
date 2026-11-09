"""One-shot launch harness for a separately approved manifest. This package is blocked."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

sys.dont_write_bytecode = True
from overlays_v2 import overlays

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RUNS = HERE / "run-once"

def sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()

def read(path):
    return json.loads(path.read_bytes())

def write(path, value):
    with path.open("x", encoding="utf-8") as f:
        json.dump(value, f, ensure_ascii=False, indent=2)

def validate_file(path, meta):
    if path.is_symlink() or path.stat().st_size != meta["bytes"] or sha(path) != meta["sha256"]:
        raise RuntimeError(f"input drift: {path}")

def within(base, path):
    resolved = path.resolve()
    if not resolved.is_relative_to(base.resolve()):
        raise RuntimeError(f"out of bounds: {path}")
    return path

def stage(job, manifest, lanes):
    source = Path(job["source"])
    project = within(RUNS, Path(job["cwd"]))
    lane = job["lane"]
    project.mkdir(parents=True)
    changes = overlays(source, lane, job["case_id"])
    expected = job["test_only_overlays"]
    if set(changes) != set(expected):
        raise RuntimeError("overlay set differs")
    for rel, meta in lanes[lane].items():
        src = within(source, source / rel)
        dst = within(project, project / rel)
        validate_file(src, meta)
        dst.parent.mkdir(parents=True, exist_ok=True)
        if rel in changes:
            validate_file(src, expected[rel]["before"])
            dst.write_bytes(changes[rel])
            validate_file(dst, {"bytes":expected[rel]["after_bytes"], "sha256":expected[rel]["after_sha256"]})
        else:
            shutil.copyfile(src, dst)
            validate_file(dst, meta)
    for rel in manifest["supplemental_rel_paths"]:
        src = within(ROOT, ROOT / rel)
        dst = within(project, project / rel)
        if dst.exists():
            if sha(src) != sha(dst):
                raise RuntimeError(f"supplemental conflict: {rel}")
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src,dst)
    for rel in manifest["replica_output_dirs"]:
        within(project, project / rel).mkdir(parents=True, exist_ok=True)
    if job["probe"]:
        rel = job["exact_argv"][job["exact_argv"].index("--script") + 1].removeprefix("res://")
        dst = within(project, project / rel)
        if dst.exists():
            raise RuntimeError(f"probe collision: {dst}")
        shutil.copyfile(job["probe"], dst)
        validate_file(dst, manifest["dependencies"][job["probe"]])
    for key in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME"):
        within(RUNS, Path(job["environment_overrides"][key])).mkdir(exist_ok=True)
    if job["returning_settings"]:
        cfg = within(RUNS, Path(job["settings_destination"]))
        cfg.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(job["returning_settings"], cfg)
        validate_file(cfg, manifest["dependencies"][job["returning_settings"]])
    return project

def artifacts(directory):
    return {str(p.relative_to(directory)): {"sha256":sha(p), "bytes":p.stat().st_size}
            for p in directory.rglob("*") if p.is_file() and not p.is_symlink() and "project" not in p.relative_to(directory).parts}

def compare_workspace(manifest):
    for path, meta in manifest["dependencies"].items():
        validate_file(Path(path), meta)
    execution = read(Path(manifest["project_source_lanes"]))["lanes"]
    for rel, meta in execution["live"].items():
        validate_file(ROOT / rel, meta)
    return execution

def index_assertions(path):
    checks = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("K6_SUITE_ASSERT "):
            label, value = json.loads(line.removeprefix("K6_SUITE_ASSERT "))
            checks.append({"id":label,"ok":value})
        elif line.startswith("ASSERT "):
            label, value = line.removeprefix("ASSERT ").rsplit(" ",1)
            checks.append({"id":label,"ok":value.lower() == "true"})
    return [dict(item, ordinal=i + 1) for i,item in enumerate(checks)]

def launch(job, project, total_deadline):
    out = Path(job["stdout"])
    err = Path(job["stderr"])
    stop = RUNS / "STOP"
    env = os.environ | job["environment_overrides"]
    limit = min(total_deadline, time.monotonic() + job["timeout_seconds"])
    with out.open("xb") as stdout, err.open("xb") as stderr:
        options = {} if job["row_id"] in (15, 16) else {"creationflags": subprocess.CREATE_NO_WINDOW}
        child = subprocess.Popen(job["exact_argv"], cwd=project, env=env, stdout=stdout, stderr=stderr, **options)
        write(Path(job["artifact_root"]) / "launch.json", {"pid": child.pid, "start_epoch_ns": time.time_ns(), "argv":job["exact_argv"]})
        reason = None
        try:
            while child.poll() is None:
                if stop.exists() or time.monotonic() >= limit:
                    reason = "stop-requested" if stop.exists() else "timeout"
                    break
                time.sleep(0.1)
        finally:
            if child.poll() is None:
                # On Windows use an independently reviewed child-tree cleanup before launch approval.
                child.kill()
            child.wait(timeout=job["kill_wait_seconds"])
    return {"exit":child.returncode,"interruption":reason,"assertions":index_assertions(out)}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest", type=Path)
    ap.add_argument("approval", type=Path)
    args = ap.parse_args()
    manifest = read(args.manifest)
    if manifest["status"] != "APPROVED_K6_ONCE" or manifest.get("gates_open"):
        raise SystemExit("Blocked review package. No process started.")
    approval = read(args.approval)
    if approval["status"] != "INDEPENDENT_ACCEPT_AND_ORCHESTRATOR_AUTHORIZE" or approval["manifest_sha256"] != sha(args.manifest):
        raise SystemExit("Independent acceptance and authorization do not match the manifest.")
    if RUNS.exists():
        raise SystemExit("Run directory exists. No restart or overwrite.")
    if manifest["timing"]["serial_cap_seconds"] > 21600:
        raise SystemExit("Serial time budget exceeds contract.")
    jobs = manifest["jobs"]
    if any(j["row_id"] in (15,16) for j in jobs):
        raise SystemExit("This harness still lacks the approved OS GUI provenance and console child-tree supervision. No process started.")
    if sorted({r for job in jobs for r in job["row_ids"]}) != list(range(1,22)):
        raise SystemExit("The complete 21-row denominator is required.")
    lanes = compare_workspace(manifest)
    RUNS.mkdir()
    deadline = time.monotonic() + 21600
    for job in jobs:
        if (RUNS / "STOP").exists():
            break
        compare_workspace(manifest)
        project = stage(job, manifest, lanes)
        result = launch(job, project, deadline)
        result["artifacts"] = artifacts(Path(job["artifact_root"]))
        write(Path(job["artifact_root"]) / "result.json", result)
        compare_workspace(manifest)
        if result["interruption"] or result["exit"] not in job["expected_exit"]:
            break

if __name__ == "__main__":
    main()
