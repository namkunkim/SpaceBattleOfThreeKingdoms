"""Run one P03 headless attempt with an immutable evidence directory."""

import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from windows_job import CREATE_SUSPENDED, LauncherJob

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
ENGINE_BODY = ENGINE.with_name("Godot_v4.7.2-stable_win64.exe")
CACHE = ROOT / ".godot/global_script_class_cache.cfg"
EXPECTED_ASSERTIONS = {
    "candidate_bytes_preserved",
    "canonical_classes",
    "entire_public_capture_preserved",
    "exact_public_refusal",
    "fixture_active_with_pending_and_events",
    "fixture_public_actions",
    "fixture_public_capture",
    "immediate_logged_before_pending",
    "ordered_events_drained_with_original_prefix",
    "owner_and_sim_identity_ready_idle",
    "pending_logged_exactly_once_in_order",
    "positive_capture_and_advance",
    "positive_restore_exact_on_separate_owner",
    "scenario_only_packet_delta",
    "second_drain_empty",
    "three_distinct_owners",
    "tick_pending_and_ordered_events_preserved",
}
CACHE_SHA = "0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1"


def write(path, data):
    with path.open("xb") as handle:
        handle.write(data)


def record(path, data):
    write(path, (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def hashes():
    frozen = json.loads((HERE / "PLAN-INPUT-SHA.json").read_text(encoding="utf-8-sig"))
    paths = [Path(item["Path"]) for item in frozen]
    paths += [HERE / name for name in ("PLAN.md", "REVIEW-PLAN.md", "PLAN-INPUT-SHA.json",
                                       "PLAN-HEAD.txt", ".gdignore", "owner_probe.gd", "owner_gate.py",
                                       "PLAN-CYCLE-02.md", "REVIEW-PLAN-CYCLE-02.md")]
    return {str(path): {"size": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
            for path in paths}


def process_ended(pid):
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    kernel.OpenProcess.restype = wintypes.HANDLE
    kernel.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
    kernel.WaitForSingleObject.restype = wintypes.DWORD
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    handle = kernel.OpenProcess(0x100000, False, pid)  # SYNCHRONIZE
    if not handle:
        error = ctypes.get_last_error()
        return {"ended": error == 87, "open_error": error}  # ERROR_INVALID_PARAMETER means no such PID.
    try:
        wait_status = kernel.WaitForSingleObject(handle, 0)
        return {"ended": wait_status == 0, "wait_status": wait_status}
    finally:
        kernel.CloseHandle(handle)


def settle(process, job):
    deadline = time.monotonic() + 5
    accounting = job.accounting()
    while (process.poll() is None or accounting["active"] != 0) and time.monotonic() < deadline:
        time.sleep(0.02)
        accounting = job.accounting()
    return accounting


def payload(stdout, marker):
    lines = [line[len(marker):] for line in stdout.splitlines() if line.startswith(marker)]
    return json.loads(lines[0]) if len(lines) == 1 else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("attempt", type=int, choices=range(1, 4))
    args = parser.parse_args()
    attempt = HERE / "cycle-02" / f"attempt-{args.attempt:02}"
    attempt.mkdir()
    before = hashes()
    head_before = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT).decode().strip()
    record(attempt / "input-before.json", before)
    write(attempt / "runner.gd.txt", (HERE / "owner_probe.gd").read_bytes())
    frozen = json.loads((HERE / "PLAN-INPUT-SHA.json").read_text(encoding="utf-8-sig"))
    mismatches = [item["Path"] for item in frozen if before[item["Path"]]["sha256"].upper() != item["Hash"]]
    if mismatches or head_before != (HERE / "PLAN-HEAD.txt").read_text(encoding="utf-8-sig").strip():
        record(attempt / "run.json", {"executed": False, "reason": "plan_baseline_changed", "mismatches": mismatches})
        return 2
    if before[str(CACHE)]["sha256"] != CACHE_SHA:
        record(attempt / "run.json", {"executed": False, "reason": "class_cache_mismatch"})
        return 2
    version = subprocess.run([str(ENGINE), "--version"], capture_output=True, cwd=ROOT, timeout=10)
    write(attempt / "engine-version.stdout", version.stdout)
    write(attempt / "engine-version.stderr", version.stderr)
    if version.returncode or not version.stdout.startswith(b"4.7.2"):
        record(attempt / "run.json", {"executed": False, "reason": "engine_version", "actual_exit": version.returncode})
        return 2
    script = "res://" + (HERE / "owner_probe.gd").relative_to(ROOT).as_posix()
    command = [str(ENGINE), "--headless", "--path", str(ROOT), "--script", script]
    data = attempt / "userdata"
    data.mkdir()
    env = os.environ.copy()
    env.update(APPDATA=str(data), LOCALAPPDATA=str(data), XDG_DATA_HOME=str(data))
    timed_out = False
    cleanup = None
    launch_error = None
    job_accounting = None
    primary_thread = None
    process = None
    started = time.monotonic()
    try:
        with LauncherJob() as job, (attempt / "stdout.bin").open("xb") as stdout_file, (attempt / "stderr.bin").open("xb") as stderr_file:
            process = subprocess.Popen(command, cwd=ROOT, stdout=stdout_file, stderr=stderr_file,
                                       creationflags=CREATE_SUSPENDED, env=env)
            try:
                primary_thread = job.assign_and_resume(process.pid)
            except OSError:
                if job.assigned:
                    cleanup = job.terminate()
                    job_accounting = settle(process, job)
                else:
                    process.kill()
                    process.wait(timeout=5)
                raise
            try:
                process.wait(timeout=30)
            except subprocess.TimeoutExpired:
                timed_out = True
                cleanup = job.terminate()
            job_accounting = settle(process, job)
    except (OSError, subprocess.TimeoutExpired) as error:
        launch_error = str(error)
    elapsed = time.monotonic() - started
    log_paths = [attempt / "stdout.bin", attempt / "stderr.bin"]
    for path in log_paths:
        if not path.exists():
            write(path, b"")
    stdout, stderr = (path.read_bytes() for path in log_paths)
    after = hashes()
    head_after = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT).decode().strip()
    record(attempt / "input-after.json", after)
    combined = stdout + b"\n" + stderr
    diagnostics = {name: len(re.findall(expression, combined, re.MULTILINE)) for name, expression in
                   {"script_error": rb"^SCRIPT ERROR:", "error": rb"^ERROR:", "warning": rb"^WARNING:",
                    "objectdb": rb"ObjectDB", "resources_at_exit": rb"resources? still in use"}.items()}
    result = payload(stdout, b"P03_OWNER_CONTRACT_RESULT ")
    clean = not any(diagnostics.values())
    engine = result
    engine_matches = bool(process and engine and type(engine.get("engine_pid")) is int
                          and engine["engine_pid"] > 0 and engine["engine_pid"] != process.pid
                          and isinstance(engine.get("engine_path"), str)
                          and Path(engine["engine_path"]).resolve() == ENGINE_BODY.resolve())
    if cleanup is not None:
        cleanup["launcher_reaped"] = process_ended(process.pid)
        cleanup["engine_reaped"] = process_ended(engine["engine_pid"]) if engine_matches else None
    job_clean = bool(job_accounting and job_accounting["active"] == 0 and job_accounting["total"] >= 2)
    actual_exit = process.returncode if process else None
    passed = (not timed_out and actual_exit == 0 and before == after and head_before == head_after and clean
              and launch_error is None and job_clean and engine_matches and result["ok"] is True
              and set(result["assertions"]) == EXPECTED_ASSERTIONS and all(value is True for value in result["assertions"].values())
              and set(result["observations"]) == {"rejection", "positive"})
    record(attempt / "run.json", {"executed": primary_thread is not None, "argv": command, "cwd": str(ROOT),
        "engine_version": version.stdout.decode().strip(), "actual_exit": actual_exit,
        "launcher_pid": process.pid if process else None, "engine_identity_matches": engine_matches,
        "launcher_primary_thread": primary_thread, "launch_error": launch_error, "job_accounting": job_accounting,
        "timed_out": timed_out, "elapsed_seconds": elapsed, "head_before": head_before, "head_after": head_after, "input_stable": before == after, "input_count": len(before),
        "userdata": str(data), "cleanup": cleanup,
        "diagnostics": diagnostics, "runner": result, "gate_passed": bool(passed)})
    sys.stdout.buffer.write(stdout)
    sys.stderr.buffer.write(stderr)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())

