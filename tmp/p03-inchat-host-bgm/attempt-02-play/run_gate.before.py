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
CACHE = "stars_stripes.ogg-b59abb1eef986334bd1d3b3ab6e47e07"
PROJECT = 'config_version=5\n\n[application]\nconfig/name="P03MinimalBgm"\n'


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
    assets = {
        ASSET: ROOT / ASSET,
        ASSET + ".import": ROOT / (ASSET + ".import"),
        ".godot/imported/" + CACHE + ".md5": OLD / (CACHE + ".md5"),
        ".godot/imported/" + CACHE + ".oggvorbisstr": OLD / (CACHE + ".oggvorbisstr"),
        "bgm_probe.gd": HERE / "bgm_probe.gd",
    }
    sources = list(assets.values()) + [
        CONSOLE, BODY, JOB, Path(sys.executable), HERE / "run_gate.py", HERE / "PLAN.md",
        HERE / "REVIEW-PLAN-6SOL.md", ROOT / "hud/ui_kit/ui_sound.gd",
    ]
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
    (project / "project.godot").write_bytes(PROJECT.encode())
    relative = {p.relative_to(project).as_posix(): p for p in project.rglob("*") if p.is_file()}
    inputs = {name: digest(p) for name, p in relative.items()}
    write_json(out / "project-before.json", inputs)
    if attempt > 1:
        base = json.loads((HERE / "attempt-01-load-only/project-before.json").read_text(encoding="utf-8"))
        if inputs != base:
            raise RuntimeError("project input SHA differs from load-only control")
    spec = importlib.util.spec_from_file_location("bgm_job", JOB)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    appdata = out / "appdata"
    appdata.mkdir()
    env = os.environ.copy()
    env.update(APPDATA=str(appdata), LOCALAPPDATA=str(appdata))
    args = [str(CONSOLE), "--headless", "--verbose", "--path", str(project), "--script", "res://bgm_probe.gd", "--", mode]
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
                code = proc.wait(timeout=30)
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
    events = [json.loads(line.removeprefix("BGM ")) for line in rawout.splitlines() if line.startswith("BGM ")]
    names = ["engine", "loaded", "started", "observed", "stopped", "cleared", "freed", "probe_result"]
    if mode == "ordered-stop":
        names.insert(5, "mixer_wait")
    by_name = {event["event"]: event["fields"] for event in events}
    engine = by_name.get("engine", {})
    expected_play = mode != "load-only"
    loaded = by_name.get("loaded", {})
    started = by_name.get("started", {})
    observed = by_name.get("observed", {})
    diagnosis = [line.strip() for line in rawerr.splitlines() if "ERROR:" in line or "WARNING:" in line]
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
    valid_events = (
        [e["event"] for e in events] == names and engine.get("mode") == mode
        and all(loaded.get(k) is True for k in ("exists", "ogg", "attached"))
        and started.get("play_called") is expected_play and observed.get("playing") is expected_play
        and observed.get("has_playback") is expected_play and observed.get("frames") == 12
        and by_name.get("stopped", {}).get("attached") is True
        and by_name.get("cleared", {}).get("stream_null") is True
        and by_name.get("freed", {}).get("freed") is True
        and by_name.get("probe_result", {}).get("ok") is True
    )
    if mode == "ordered-stop":
        wait = by_name.get("mixer_wait", {})
        valid_events &= wait.get("attached") is True and wait.get("frames") == 12 and wait.get("seconds") == 0.25
    ok = (
        code == 0 and not timed_out and accounting["active"] == 0
        and accounting["total"] >= 2 and Path(engine.get("path", "")).resolve() == BODY.resolve()
        and isinstance(engine.get("pid"), int) and engine["pid"] != proc.pid and valid_events
        and (clean or expected_play and exact_leak)
        and original == source_after and inputs == project_after and head == new_head and index == new_index
    )
    result = {
        "diagnostic_gate": "PASS" if ok else "FAIL", "product_gate": "NOT_RUN",
        "observation": "CLEAN" if clean else "EXACT_OGG_LEAK" if exact_leak else "UNEXPECTED_DIAGNOSTIC",
        "mode": mode, "actual_exit": code, "timeout": timed_out, "job": accounting,
        "launcher_pid": proc.pid, "engine": engine, "events": events, "diagnostics": diagnosis,
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
    if (n, label) not in [(1, "load-only"), (2, "play"), (3, "ordered-stop")]:
        raise SystemExit("approved diagnostic attempts: 01 load-only, 02 play, 03 ordered-stop if warranted")
    raise SystemExit(main(n, label))
