import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

from windows_job import CREATE_SUSPENDED, LauncherJob

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
BODY = ENGINE.with_name("Godot_v4.7.2-stable_win64.exe")
CACHE = ROOT / ".godot/global_script_class_cache.cfg"
PROJECT = ROOT / "project.godot"
NAMES = [
    "correct_pending_and_suffix", "duplicate_pending_in_suffix",
    "reordered_or_omitted_suffix", "consumer_outlives_restore",
]
PLAN_SHA = "8852b8c89a2217d1967bef431fba6913b66fc0d4bcec10652c19f271d4a345af"


def write_json(path, value):
    with path.open("x", encoding="utf-8") as file:
        json.dump(value, file, indent=2, ensure_ascii=False)
        file.write("\n")


def resource(relative):
    path = ROOT / relative
    if path.resolve() != path or not path.is_file():
        raise ValueError(f"missing or noncanonical resource: res://{relative}")
    return path


def sources():
    cache = CACHE.read_text(encoding="utf-8-sig")
    mappings = re.findall(r'"path":\s*"res://([^"]+)"', cache)
    if not mappings or len(mappings) != cache.count('"path":'):
        raise ValueError("class map contains empty or unresolved paths")
    project_paths = re.findall(r'"\*?res://([^"]+)"', PROJECT.read_text(encoding="utf-8-sig"))
    data = sorted((ROOT / "data").rglob("*.json"))
    fixed = [
        ENGINE, BODY, CACHE, PROJECT, HERE / "launch.py", HERE / "windows_job.py",
        HERE / "PLAN.md", HERE / "REVIEW-PLAN-TERRA-V2.md",
        resource((HERE / "probe.gd").relative_to(ROOT).as_posix()),
        resource("data/profiles/poc_corridor.json"), resource("data/bundle-layout.json"),
    ]
    references = json.loads((HERE / "READ-INPUT-SHA256.json").read_text(encoding="utf-8-sig"))
    fixed += [ROOT / entry["path"] for entry in references]
    paths = fixed + [resource(x) for x in mappings + project_paths] + data
    paths += sorted((ROOT / "core/battle").rglob("*.gd"))
    return sorted(set(paths), key=str)


def hashes(paths):
    values = {}
    errors = []
    for path in paths:
        try:
            with path.open("rb") as file:
                sha = hashlib.file_digest(file, "sha256").hexdigest()
                values[str(path)] = {"sha256": sha, "bytes": file.tell()}
        except OSError as exc:
            errors.append(str(exc))
    return values, errors


def snapshot(folder, phase):
    for label, args in [
        ("status", ["status", "--porcelain=v1", "-uall", "-z"]),
        ("head", ["rev-parse", "HEAD"]),
    ]:
        result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, timeout=30)
        (folder / f"{phase}-{label}.bin").write_bytes(result.stdout)
        (folder / f"{phase}-{label}-stderr.bin").write_bytes(result.stderr)
        if result.returncode:
            raise RuntimeError(f"git {label} exited {result.returncode}")
    return (folder / f"{phase}-head.bin").read_bytes()


def main(name):
    folder = HERE / name
    folder.mkdir()
    manifest = folder / "input-before.json"
    command = [str(ENGINE), "--headless", "--path", str(ROOT), "--script",
               "res://" + (HERE / "probe.gd").relative_to(ROOT).as_posix()]
    output = folder / "stdout.bin"
    errors = folder / "stderr.bin"
    preflight = []
    try:
        start_head = snapshot(folder, "start")
        paths = sources()
        before, preflight = hashes(paths)
        write_json(manifest, before)
        confirmed, confirm_errors = hashes(sources())
        preflight.extend(confirm_errors)
        if before != confirmed:
            preflight.append("preflight input set or hashes changed")
        if before.get(str(HERE / "PLAN.md"), {}).get("sha256") != PLAN_SHA:
            preflight.append("reviewed plan digest mismatch")
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        preflight.append(str(exc))
    if preflight:
        write_json(folder / "run.json", {"preflight_errors": preflight, "actual_exit": None, "gate_passed": False})
        print(preflight)
        return 2

    process = None
    job_accounting = None
    launch_error = None
    timed_out = False
    start = time.monotonic()
    try:
        with LauncherJob() as job, output.open("xb") as out, errors.open("xb") as err:
            process = subprocess.Popen(command, cwd=ROOT, stdout=out, stderr=err, creationflags=CREATE_SUSPENDED)
            try:
                job.assign_and_resume(process.pid)
            except OSError:
                if job.assigned:
                    job.terminate()
                else:
                    process.kill()
                process.wait(timeout=5)
                raise
            try:
                process.wait(timeout=60)
            except subprocess.TimeoutExpired:
                timed_out = True
                job.terminate()
                process.wait(timeout=5)
            deadline = time.monotonic() + 5
            job_accounting = job.accounting()
            while job_accounting["active"] and time.monotonic() < deadline:
                time.sleep(0.02)
                job_accounting = job.accounting()
    except (OSError, subprocess.TimeoutExpired) as exc:
        launch_error = str(exc)

    after, after_errors = hashes(paths)
    try:
        if sources() != paths:
            after_errors.append("input set changed")
        end_head = snapshot(folder, "end")
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        after_errors.append(str(exc))
        end_head = None
    write_json(folder / "input-after.json", after)
    raw = b"\n".join(path.read_bytes() if path.exists() else b"" for path in (output, errors))
    diagnostics = {
        label: len(re.findall(pattern, raw, re.M | re.I))
        for label, pattern in {
            "script_error": rb"^SCRIPT ERROR:", "error": rb"^ERROR:",
            "warning": rb"^WARNING:", "objectdb": rb"ObjectDB",
            "leak": rb"\bleak(?:ed|s)?\b", "resources": rb"resources? still in use",
        }.items()
    }
    markers = [line.decode("utf-8", errors="replace") for line in raw.splitlines()
               if line.startswith((b"CASE_START ", b"CHECK ", b"CASE_END "))]
    expected = []
    ids = []
    for case in NAMES:
        expected.append(f"CASE_START {case}")
        for number in range(1, 9):
            id_ = f"{case}:{number}"
            ids.append(id_)
            expected.append(f"CHECK {id_} PASS")
        expected.append(f"CASE_END {case}")
    summary = [line[len(b"PROBE_RESULT "):] for line in raw.splitlines() if line.startswith(b"PROBE_RESULT ")]
    try:
        result = json.loads(summary[0]) if len(summary) == 1 else {}
    except ValueError:
        result = {}
    identity = bool(process and isinstance(result.get("engine_pid"), int)
                    and result["engine_pid"] != process.pid
                    and Path(result.get("engine_path", "")).resolve() == BODY.resolve())
    own_prefix = HERE.relative_to(ROOT).as_posix().encode() + b"/"
    status_delta = []
    if end_head is not None:
        status_start = set((folder / "start-status.bin").read_bytes().split(b"\0"))
        status_end = set((folder / "end-status.bin").read_bytes().split(b"\0"))
        status_delta = sorted(entry.decode("utf-8", errors="replace")
                              for entry in status_start ^ status_end
                              if entry and not entry[3:].startswith(own_prefix))
    stable = before == after and not after_errors and start_head == end_head and not status_delta
    job_clear = bool(job_accounting and job_accounting["active"] == 0 and job_accounting["total"] >= 2)
    actual_exit = process.returncode if process else None
    marker_pass = markers == expected and result.get("ids") == ids and result.get("checks") == 32
    hard_stop = bool(launch_error or timed_out or not job_clear or not stable)
    passed = bool(actual_exit == 0 and not hard_stop and not any(diagnostics.values())
                  and identity and marker_pass and result.get("ok") is True)
    report = {
        "argv": command, "actual_exit": actual_exit, "timeout_exit": 124 if timed_out else None,
        "timed_out": timed_out, "launch_error": launch_error, "accounting": job_accounting,
        "launcher_pid": process.pid if process else None, "elapsed": time.monotonic() - start,
        "input_count": len(before), "input_stable": stable, "input_after_errors": after_errors,
        "outside_status_delta": status_delta,
        "engine_identity_matches": identity, "diagnostics": diagnostics, "exact_markers": marker_pass,
        "result": result, "hard_stop": hard_stop, "gate_passed": passed,
    }
    write_json(folder / "run.json", report)
    print(json.dumps(report, indent=2))
    return 0 if passed else (2 if hard_stop else 1)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
