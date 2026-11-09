"""Run one P03 headless attempt with an immutable evidence directory."""

import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

from windows_job import CREATE_SUSPENDED, LauncherJob

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
ENGINE_BODY = ENGINE.with_name("Godot_v4.7.2-stable_win64.exe")
CACHE = ROOT / ".godot/global_script_class_cache.cfg"
CACHE_SHA = "0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1"


def write(path, data):
    with path.open("xb") as handle:
        handle.write(data)


def record(path, data):
    write(path, (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def hashes():
    paths = [ENGINE, ENGINE_BODY, CACHE, ROOT / "project.godot", Path(__file__), HERE / "windows_job.py",
             HERE / ".gdignore", HERE / "dictionary_value_type.gd", HERE / "PLAN.md", HERE / "REVIEW-PLAN.md"]
    paths += [ROOT / name for name in ("data/bundle-layout.json", "data/profiles/poc_corridor.json",
                                     "data/profiles/combat_m3.json")]
    paths += sorted((ROOT / "core/battle").rglob("*.gd"))
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
    parser.add_argument("attempt", type=int, choices=range(1, 7))
    parser.add_argument("--timeout-probe", action="store_true")
    args = parser.parse_args()
    attempt = HERE / f"attempt-{args.attempt:02}"
    attempt.mkdir()
    before = hashes()
    record(attempt / "input-before.json", before)
    write(attempt / "runner.gd.txt", (HERE / "dictionary_value_type.gd").read_bytes())
    if before[str(CACHE)]["sha256"] != CACHE_SHA:
        record(attempt / "run.json", {"executed": False, "reason": "class_cache_mismatch"})
        return 2
    version = subprocess.run([str(ENGINE), "--version"], capture_output=True, cwd=ROOT, timeout=10)
    write(attempt / "engine-version.stdout", version.stdout)
    write(attempt / "engine-version.stderr", version.stderr)
    if version.returncode or not version.stdout.startswith(b"4.7.2"):
        record(attempt / "run.json", {"executed": False, "reason": "engine_version", "actual_exit": version.returncode})
        return 2
    script = "res://" + (HERE / "dictionary_value_type.gd").relative_to(ROOT).as_posix()
    command = [str(ENGINE), "--headless", "--path", str(ROOT), "--script", script]
    if args.timeout_probe:
        command += ["--", "--p03-timeout-probe"]
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
                                       creationflags=CREATE_SUSPENDED)
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
                process.wait(timeout=3 if args.timeout_probe else 30)
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
    record(attempt / "input-after.json", after)
    combined = stdout + b"\n" + stderr
    diagnostics = {name: len(re.findall(expression, combined, re.MULTILINE)) for name, expression in
                   {"script_error": rb"^SCRIPT ERROR:", "error": rb"^ERROR:", "warning": rb"^WARNING:",
                    "objectdb": rb"ObjectDB", "resources_at_exit": rb"resources? still in use"}.items()}
    result = payload(stdout, b"P03_VALUE_TYPE_RESULT ")
    probe = payload(stdout, b"P03_TIMEOUT_PROBE ")
    clean = not any(diagnostics.values())
    engine = probe if args.timeout_probe else result
    engine_matches = bool(process and engine and type(engine.get("engine_pid")) is int
                          and engine["engine_pid"] > 0 and engine["engine_pid"] != process.pid
                          and isinstance(engine.get("engine_path"), str)
                          and Path(engine["engine_path"]).resolve() == ENGINE_BODY.resolve())
    if cleanup is not None:
        cleanup["launcher_reaped"] = process_ended(process.pid)
        cleanup["engine_reaped"] = process_ended(engine["engine_pid"]) if engine_matches else None
    job_clean = bool(job_accounting and job_accounting["active"] == 0 and job_accounting["total"] >= 2)
    actual_exit = process.returncode if process else None
    probe_passed = bool(args.timeout_probe and timed_out and engine_matches and result is None
                        and launch_error is None and before == after and actual_exit not in (None, 0)
                        and job_clean and cleanup["ok"] and cleanup["launcher_reaped"]["ended"]
                        and cleanup["engine_reaped"]["ended"])
    passed = (not args.timeout_probe and not timed_out and actual_exit == 0 and before == after and clean and result
              and launch_error is None and job_clean
              and engine_matches and result["ok"] is True and len(set(result["cases"])) == 3 and result["value_metadata_contract"] in {"MATCH", "MISMATCH"})
    record(attempt / "run.json", {"executed": primary_thread is not None, "argv": command, "cwd": str(ROOT),
        "engine_version": version.stdout.decode().strip(), "actual_exit": actual_exit,
        "launcher_pid": process.pid if process else None, "engine_identity_matches": engine_matches,
        "launcher_primary_thread": primary_thread, "launch_error": launch_error, "job_accounting": job_accounting,
        "timed_out": timed_out, "elapsed_seconds": elapsed, "input_stable": before == after, "input_count": len(before),
        "timeout_probe": probe, "timeout_probe_passed": probe_passed, "cleanup": cleanup,
        "diagnostics": diagnostics, "runner": result, "gate_passed": bool(passed)})
    sys.stdout.buffer.write(stdout)
    sys.stderr.buffer.write(stderr)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
