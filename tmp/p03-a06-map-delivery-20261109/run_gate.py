import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from windows_job import CREATE_SUSPENDED, LauncherJob

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
BODY = ENGINE.with_name("Godot_v4.7.2-stable_win64.exe")
PLAN_HASH = "9b3f07115814f7851fd78e369274bb81dffe8e92a60b80de744b4b061e388dd3"
MANIFEST = HERE / "MANIFEST.json"
NAMES = ["normal_map_effect", "early_result_exit", "reentry_after_slot_consumed"]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(path, value):
    with path.open("x", encoding="utf-8") as file:
        json.dump(value, file, ensure_ascii=False, indent=2)
        file.write("\n")


def git(*args):
    return subprocess.check_output(["git", "--no-optional-locks", "-c", "core.longpaths=true", *args], cwd=ROOT)


def freeze():
    paths = [ENGINE, BODY, Path(sys.executable), *[HERE / name for name in (
        ".gdignore", "PLAN.md", "REVIEW-PLAN.md", "map_delivery.gd", "run_gate.py", "windows_job.py")],
        *[ROOT / name for name in ("project.godot", ".godot/global_script_class_cache.cfg", "scenes/WorldMap.tscn",
            "data/scenarios/base/world_208.json", "tests/world_link.gd")]]
    for subtree in ("scripts", "view", "hud", "core"):
        paths.extend((ROOT / subtree).rglob("*.gd"))
    if sha(HERE / "PLAN.md") != PLAN_HASH:
        raise ValueError("unapproved plan SHA")
    files = {str(path): {"sha256": sha(path), "size": path.stat().st_size} for path in sorted(set(paths))}
    return {"head": git("rev-parse", "HEAD").decode().strip(), "files": files}


def run(attempt):
    if any(not (HERE / f"attempt-{index:02}").exists() for index in range(1, attempt)):
        raise ValueError("attempt index must be consecutive")
    before = freeze()
    if before != json.loads(MANIFEST.read_bytes()):
        raise ValueError("frozen inputs drifted before run")
    out = HERE / f"attempt-{attempt:02}"
    out.mkdir()
    user = out / "user"
    user.mkdir()
    env = dict(os.environ, APPDATA=str(user), LOCALAPPDATA=str(user), XDG_DATA_HOME=str(user))
    command = [str(ENGINE), "--headless", "--path", str(ROOT), "--log-file", str(out / "godot.log"),
               "--script", "res://" + (HERE / "map_delivery.gd").relative_to(ROOT).as_posix()]
    record(out / "input-before.json", before)
    record(out / "command.json", {"argv": command, "cwd": str(ROOT), "isolated_user_base": str(user)})
    timed_out = False
    with LauncherJob() as job, (out / "stdout.bin").open("xb") as stdout, (out / "stderr.bin").open("xb") as stderr:
        proc = subprocess.Popen(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr, creationflags=CREATE_SUSPENDED)
        try:
            job.assign_and_resume(proc.pid)
        except OSError:
            if job.assigned:
                job.terminate()
            else:
                proc.kill()
            proc.wait(timeout=5)
            raise
        try:
            proc.wait(timeout=45)
        except subprocess.TimeoutExpired:
            timed_out = True
            job.terminate()
            proc.wait(timeout=5)
        accounting = job.accounting()
    output = (out / "stdout.bin").read_bytes() + b"\n" + (out / "stderr.bin").read_bytes()
    payloads = [json.loads(line[len(b"P03_MAP_PASS "):]) for line in output.splitlines() if line.startswith(b"P03_MAP_PASS ")]
    payload = payloads[0] if len(payloads) == 1 else None
    diagnostics = {key: len(re.findall(pattern, output, re.MULTILINE)) for key, pattern in {
        "script_error": rb"^SCRIPT ERROR:", "error": rb"^ERROR:", "warning": rb"^WARNING:",
        "objectdb": rb"ObjectDB", "resources": rb"resources? still in use"}.items()}
    after = freeze()
    record(out / "input-after.json", after)
    engine_matches = bool(payload and payload["engine_pid"] != proc.pid and Path(payload["engine_path"]).resolve() == BODY.resolve())
    user_isolated = bool(payload and Path(payload["user_dir"]).resolve().is_relative_to(user.resolve()))
    result = {"actual_exit": proc.returncode, "timed_out": timed_out, "launcher_pid": proc.pid, "job": accounting,
              "inputs": len(before["files"]), "input_stable": before == after, "diagnostics": diagnostics,
              "engine_identity_matches": engine_matches, "user_isolated": user_isolated, "payload": payload}
    result["passed"] = bool(proc.returncode == 0 and not timed_out and before == after and not any(diagnostics.values())
                            and accounting["active"] == 0 and accounting["total"] >= 2 and engine_matches and user_isolated
                            and payload["checks"] == 15 and payload["cases"] == NAMES and payload["failures"] == [])
    record(out / "run.json", result)
    print(json.dumps(result, ensure_ascii=True))
    return 124 if timed_out else int(not result["passed"])


def main():
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--freeze", action="store_true")
    mode.add_argument("--attempt", type=int, choices=(1, 2, 3))
    args = parser.parse_args()
    if args.freeze:
        record(MANIFEST, freeze())
        print(sha(MANIFEST))
        return 0
    return run(args.attempt)


if __name__ == "__main__":
    raise SystemExit(main())
