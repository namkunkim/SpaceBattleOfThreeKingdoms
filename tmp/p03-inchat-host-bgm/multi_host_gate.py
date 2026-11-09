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
OLD = ROOT / "tmp/p03-host-clock-ui-20261108/.godot/imported"
JOB = ROOT / "tmp/p03-command-suffix-20261107/windows_job.py"
CONSOLE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
BODY = CONSOLE.with_name(CONSOLE.name.replace("_console", ""))
ASSET = "assets/audio/music/stars_stripes.ogg"


def digest(p):
    with p.open("rb") as stream:
        return {"size": p.stat().st_size, "sha256": hashlib.file_digest(stream, "sha256").hexdigest()}


def snapshot(paths):
    return {str(p): digest(p) for p in sorted(set(paths))}


def write_json(p, value):
    with p.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)


def git(*args):
    return subprocess.check_output(["git", "-c", "core.longpaths=true", "--no-optional-locks", *args], cwd=ROOT)


def git_record(out, phase):
    head = git("rev-parse", "HEAD")
    index = git("diff", "--cached", "--name-only", "-z")
    status = git("status", "--porcelain=v1", "-z")
    for name, data in (("head", head), ("index", index), ("status", status)):
        (out / f"{name}-{phase}.raw").write_bytes(data)
    return head, index, status


def main(attempt, mode):
    out = HERE / f"attempt-{attempt:02d}-{mode}"
    out.mkdir()
    (out / ".gdignore").touch()
    project = out / "project"
    project.mkdir()
    dirs = ("assets", "core", "data", "hud", "input", "scenes", "scripts", "view")
    canonical = [ROOT / "project.godot"]
    for name in dirs:
        canonical.extend(p for p in (ROOT / name).rglob("*") if p.is_file())
    cache = OLD.parent
    assets = {p.relative_to(ROOT).as_posix(): p for p in canonical}
    assets.update({".godot/" + p.relative_to(cache).as_posix(): p for p in OLD.rglob("*") if p.is_file()})
    assets.update({".godot/" + n: cache / n for n in ("global_script_class_cache.cfg", "uid_cache.bin")})
    assets["multi_host_probe.gd"] = HERE / "multi_host_probe.gd"
    sources = list(assets.values()) + [
        CONSOLE, BODY, JOB, Path(sys.executable), HERE / "multi_host_gate.py",
        HERE / "PLAN.md", HERE / "REVIEW-PLAN-6SOL.md", HERE / "PLAN-HOST-LIFETIME.md",
        HERE / "REVIEW-HOST-LIFETIME-PLAN-6SOL.md",
        HERE / "PLAN-HOST-PLAYBACK-GUARD.md", HERE / "REVIEW-PLAYBACK-GUARD-PLAN-6SOL.md",
        HERE / "PLAN-MULTI-HOST-LIFETIME.md", HERE / "REVIEW-MULTI-HOST-PLAN-6SOL.md",
    ]
    for path in ("attempt-01-load-only", "attempt-02-play"):
        sources.extend(HERE / path / name for name in ("result.json", "stdout.txt", "stderr.txt", "project-before.json"))
    for previous_host in ["attempt-03-legacy-host"] + ["attempt-04-legacy-host"] + (["attempt-05-multi-legacy"] if attempt == 6 else []):
        sources.extend(HERE / previous_host / name
                       for name in ("result.json", "stdout.txt", "stderr.txt", "project-before.json"))
    for i in (4, 5, 6):
        sources.extend(ROOT / f"tmp/p03-inchat-host-clock/attempt-{i:02d}/{name}"
                       for name in ("stdout.txt", "stderr.txt", "result.json"))
    original = snapshot(sources)
    write_json(out / "original-before.json", original)
    head, index, status = git_record(out, "before")
    for name, src in assets.items():
        dst = project / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        if digest(dst) != original[str(src)]:
            raise RuntimeError(f"copy diverged: {name}")
    relative = {p.relative_to(project).as_posix(): p for p in project.rglob("*") if p.is_file()}
    inputs = {name: digest(p) for name, p in relative.items()}
    write_json(out / "project-before.json", inputs)
    if attempt == 6:
        base = json.loads((HERE / "attempt-05-multi-legacy/project-before.json").read_text(encoding="utf-8"))
        if inputs != base:
            raise RuntimeError("project input SHA differs from legacy control")
    spec = importlib.util.spec_from_file_location("bgm_job", JOB)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    appdata = out / "appdata"
    appdata.mkdir()
    env = os.environ.copy()
    env.update(APPDATA=str(appdata), LOCALAPPDATA=str(appdata))
    args = [str(CONSOLE), "--headless", "--verbose", "--path", str(project), "--script", "res://multi_host_probe.gd", "--", mode]
    write_json(out / "command.json", args)
    timed_out = False
    with (out / "stdout.txt").open("xb") as stdout, (out / "stderr.txt").open("xb") as stderr:
        with module.LauncherJob() as job:
            proc = subprocess.Popen(args, cwd=project, stdout=stdout, stderr=stderr, env=env,
                                    creationflags=0x4 | 0x08000000)
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
            accounting = job.accounting()
            deadline = time.monotonic() + 5
            while accounting["active"] and time.monotonic() < deadline:
                time.sleep(0.05)
                accounting = job.accounting()
    source_after = snapshot(sources)
    project_after = {name: digest(p) for name, p in relative.items()}
    new_head, new_index, new_status = git_record(out, "after")
    write_json(out / "original-after.json", source_after)
    write_json(out / "project-after.json", project_after)
    rawout = (out / "stdout.txt").read_text(encoding="utf-8", errors="replace")
    rawerr = (out / "stderr.txt").read_text(encoding="utf-8", errors="replace")
    def records(prefix):
        return [json.loads(line.removeprefix(prefix + " ")) for line in rawout.splitlines() if line.startswith(prefix + " ")]

    engines = records("ENGINE")
    engine = engines[0] if len(engines) == 1 else {}
    music = records("MUSIC")
    retire = records("RETIRE")
    base = records("BASE")
    first = records("FIRST")
    probe = records("HOST_CLOCK_RESULT")
    diagnosis = [line.strip() for line in (rawout + "\n" + rawerr).splitlines() if "ERROR:" in line or "WARNING:" in line]
    expected_error = "ERROR: [FleetBattle3D] invalid_candidate_profile at profile.ally"
    malformed_count = diagnosis.count(expected_error)
    diagnosis = [line for line in diagnosis if line != expected_error]
    leaks = [line for line in rawout.splitlines() if line.startswith("Leaked instance: ")]
    resources = [line for line in rawout.splitlines() if line.startswith("Resource still in use: ")]
    exact_types = sorted(line.split(": ")[1].split(":")[0] for line in leaks)
    exact_leak = (
        exact_types == sorted(["OggPacketSequence", "AudioStreamOggVorbis", "OggPacketSequencePlayback", "AudioStreamPlaybackOggVorbis"])
        and len(resources) == 2 and all(ASSET in line for line in resources)
        and len(diagnosis) == 2 and any("4 ObjectDB instances" in line for line in diagnosis)
        and any("2 resources still in use" in line for line in diagnosis)
    )
    clean = not diagnosis and not leaks and not resources
    waits = 0 if mode == "multi-legacy" else 12
    expected_check_names = [
        "same_initial_host_state", "actual_first_frame_phase_fork",
        "prepare_rejection_preserves_prior_host", "clean_teardown_and_exact_gate",
    ]
    valid_events = (
        engine.get("mode") == mode and malformed_count == 2
        and len(music) == len(retire) == 4 and len(base) == len(first) == len(probe) == 1
        and all(all(row.get(k) is True for k in ("ogg", "playing", "playback")) for row in music)
        and [(row["phase"], row["reject"]) for row in music] == [(0.0, True), (0.0, False), (0.75, True), (0.75, False)]
        and all(row["frames_before_clear"] == waits and row["playing_after_stop"] is False
                and all(row.get(k) is True for k in ("stop_attached", "tree_clock_stable", "cleared", "freed")) for row in retire)
        and probe[0]["pass"] is True
        and [row["name"] for row in probe[0]["checks"]] == expected_check_names
        and all(row["pass"] is True for row in probe[0]["checks"])
    )
    events = {"music": music, "retire": retire, "base": base, "first": first, "probe": probe}
    if mode == "multi-ordered":
        control = json.loads((HERE / "attempt-05-multi-legacy/result.json").read_text(encoding="utf-8"))
        valid_events &= (
            control["diagnostic_gate"] == "PASS" and control["observation"] == "EXACT_OGG_LEAK"
            and all(control["events"][key] == events[key] for key in ("music", "base", "first", "probe"))
            and control["engine"]["driver"] == engine["driver"]
        )
    ok = (
        code == 0 and not timed_out and accounting["active"] == 0
        and accounting["total"] >= 2 and Path(engine.get("path", "")).resolve() == BODY.resolve()
        and isinstance(engine.get("pid"), int) and engine["pid"] != proc.pid and valid_events
        and (clean or exact_leak)
        and original == source_after and inputs == project_after and head == new_head and index == new_index
    )
    result = {
        "diagnostic_gate": "PASS" if ok else "FAIL", "product_gate": "NOT_RUN",
        "observation": "CLEAN" if clean else "EXACT_OGG_LEAK" if exact_leak else "UNEXPECTED_DIAGNOSTIC",
        "mode": mode, "actual_exit": code, "timeout": timed_out, "job": accounting,
        "launcher_pid": proc.pid, "engine": engine, "events": events, "diagnostics": diagnosis,
        "expected_malformed_count": malformed_count,
        "leaked_instances": leaks, "resources_still_in_use": resources, "input_count": len(original),
        "source_stable": original == source_after, "project_stable": inputs == project_after,
        "head_index_stable": head == new_head and index == new_index, "status_unchanged": status == new_status,
    }
    write_json(out / "result.json", result)
    print(json.dumps(result, ensure_ascii=False))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    n, label = int(sys.argv[1]), sys.argv[2]
    if (n, label) not in [(5, "multi-legacy"), (6, "multi-ordered")]:
        raise SystemExit("approved host attempts: 05 multi-legacy, 06 multi-ordered only if warranted")
    raise SystemExit(main(n, label))
