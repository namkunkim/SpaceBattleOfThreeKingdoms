import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OLD = ROOT / "tmp/p03-host-clock-ui-20261108"
JOB_PATH = ROOT / "tmp/p03-command-suffix-20261107/windows_job.py"
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
BODY = ENGINE.with_name(ENGINE.name.replace("_console", ""))
DIRS = ("assets", "core", "data", "hud", "input", "scenes", "scripts", "view")
NAMES = ("same_initial_host_state", "actual_first_frame_phase_fork",
         "prepare_rejection_preserves_prior_host", "clean_teardown_and_exact_gate")


def digest(path):
    with path.open("rb") as stream:
        return {"size": path.stat().st_size, "sha256": hashlib.file_digest(stream, "sha256").hexdigest()}


def git(*args):
    return subprocess.check_output(["git", "-c", "core.longpaths=true", "--no-optional-locks", *args], cwd=ROOT)


def manifest(paths):
    return {str(p): digest(p) for p in sorted(set(paths))}


def dump(path, value):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)


def gate(attempt):
    out = HERE / f"attempt-{attempt:02d}"
    out.mkdir()
    project = out / "project"
    project.mkdir()
    (project / ".gdignore").touch()
    (out / ".gdignore").touch()
    canonical = [ROOT / "project.godot"]
    for name in DIRS:
        canonical.extend(p for p in (ROOT / name).rglob("*") if p.is_file())
    previous = [OLD / name for name in ("before.json", "after.json", "exits.txt", "host_clock.gd", "preserve.log", "reset.log")]
    frozen = canonical + previous + [HERE / name for name in ("PLAN.md", "REVIEW-PLAN.md", "host_clock_probe.gd", "run_gate.py")]
    frozen += [ENGINE, BODY, Path(sys.executable), JOB_PATH]
    cache = OLD / ".godot"
    for p in (cache / "imported").rglob("*"):
        if p.is_file():
            frozen.append(p)
    frozen += [cache / "global_script_class_cache.cfg", cache / "uid_cache.bin"]
    before = manifest(frozen)
    dump(out / "inputs-before.json", before)
    head = git("rev-parse", "HEAD")
    index = git("diff", "--cached", "--name-only", "-z")
    status = git("status", "--porcelain=v1", "-z")
    for name, data in (("head-before.txt", head), ("index-before.z", index), ("status-before.z", status)):
        (out / name).write_bytes(data)
    for p in canonical:
        destination = project / p.relative_to(ROOT)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(p, destination)
        if digest(destination) != before[str(p)]:
            raise RuntimeError(f"copy differs from frozen source: {p}")
    for p in frozen:
        if p.is_relative_to(cache):
            destination = project / ".godot" / p.relative_to(cache)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(p, destination)
            if digest(destination) != before[str(p)]:
                raise RuntimeError(f"copy differs from frozen isolated cache: {p}")
    runner = project / "host_clock_probe.gd"
    shutil.copyfile(HERE / runner.name, runner)
    project_inputs = manifest(p for p in project.rglob("*") if p.is_file())
    dump(out / "project-inputs.json", project_inputs)
    spec = importlib.util.spec_from_file_location("windows_job_p03", JOB_PATH)
    job_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(job_module)
    appdata = out / "appdata"
    appdata.mkdir()
    env = os.environ.copy()
    env.update(APPDATA=str(appdata), LOCALAPPDATA=str(appdata), PYTHONDONTWRITEBYTECODE="1")
    args = [str(ENGINE), "--headless", "--path", str(project), "--script", "res://host_clock_probe.gd"]
    dump(out / "command.json", args)
    start = time.monotonic()
    timed_out = False
    sys.dont_write_bytecode = True
    with (out / "stdout.txt").open("xb") as stdout, (out / "stderr.txt").open("xb") as stderr:
        with job_module.LauncherJob() as job:
            proc = subprocess.Popen(args, stdout=stdout, stderr=stderr, env=env,
                                    cwd=project, creationflags=0x4 | 0x08000000)
            try:
                job.assign_and_resume(proc.pid)
            except Exception:
                proc.kill()
                proc.wait(timeout=10)
                raise
            try:
                code = proc.wait(timeout=90)
            except subprocess.TimeoutExpired:
                timed_out = True
                job.terminate()
                code = proc.wait(timeout=10)
            account = job.accounting()
    after = manifest(frozen)
    dump(out / "inputs-after.json", after)
    project_after = {name: digest(Path(name)) for name in project_inputs}
    dump(out / "project-inputs-after.json", project_after)
    head_after = git("rev-parse", "HEAD")
    index_after = git("diff", "--cached", "--name-only", "-z")
    for name, data in (("head-after.txt", head_after), ("index-after.z", index_after),
                       ("status-after.z", git("status", "--porcelain=v1", "-z"))):
        (out / name).write_bytes(data)
    stdout = (out / "stdout.txt").read_text(encoding="utf-8", errors="replace")
    stderr = (out / "stderr.txt").read_text(encoding="utf-8", errors="replace")
    parsed = {}
    for prefix in ("ENGINE", "HOST_CLOCK_RESULT"):
        matching = [line.removeprefix(prefix + " ") for line in stdout.splitlines() if line.startswith(prefix + " ")]
        if len(matching) == 1:
            parsed[prefix] = json.loads(matching[0])
    expected_error = "ERROR: [FleetBattle3D] invalid_candidate_profile at profile.ally"
    logs = (stdout + "\n" + stderr).splitlines()
    diagnostics = [line.strip() for line in logs if "ERROR:" in line or "WARNING:" in line or "leaked" in line.lower()]
    summary = parsed.get("HOST_CLOCK_RESULT", {})
    engine = parsed.get("ENGINE", {})
    pass_gate = (
        code == 0 and not timed_out and account["active"] == 0 and account["total"] == 2
        and Path(engine.get("path", "")).resolve() == BODY.resolve()
        and isinstance(engine.get("pid"), int) and engine["pid"] != proc.pid
        and [row["name"] for row in summary.get("checks", [])] == list(NAMES)
        and summary.get("pass") is True
        and diagnostics == [expected_error, expected_error]
        and before == after and project_inputs == project_after and head == head_after and index == index_after
    )
    result = {
        "pass": pass_gate, "actual_exit": code, "timed_out": timed_out,
        "elapsed_seconds": time.monotonic() - start,
        "launcher_pid": proc.pid, "job": account, "engine": engine, "diagnostics": diagnostics,
        "checks": summary.get("checks", []), "source_input_count": len(before),
        "source_sha_unchanged": before == after, "project_sha_unchanged": project_inputs == project_after,
        "head_index_unchanged": head == head_after and index == index_after,
    }
    dump(out / "result.json", result)
    print(json.dumps(result, ensure_ascii=False))
    return 0 if pass_gate else 1


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    attempt = int(sys.argv[1])
    if not 3 <= attempt <= 6:
        raise SystemExit("K6 allows attempts 03 through 06")
    raise SystemExit(gate(attempt))
