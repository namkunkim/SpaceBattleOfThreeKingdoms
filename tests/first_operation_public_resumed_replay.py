"""Run one public checkpoint, a fresh resume, and public replay in an isolated Windows profile."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


PROJECT = Path(__file__).resolve().parents[1]
SCRIPT = PROJECT / "tests/first_operation_public_resumed_replay.gd"
PHASES = ("checkpoint", "resume", "replay")
FILES = ("pc-first-operation-product-v1.save", "uninterrupted.pcopreplay", "resumed.pcopreplay",
         "resumed-replay-oracle")


def sha(path):
    if not path.is_file():
        return None
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", required=True, type=Path)
    parser.add_argument("--evidence", required=True, type=Path)
    options = parser.parse_args()
    if os.name != "nt":
        parser.error("requires Windows")
    engine = options.engine.resolve(strict=True)
    evidence = options.evidence.resolve()
    evidence.mkdir()
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA", "USERPROFILE", "TEMP", "TMP"):
        folder = evidence / "profile" / key
        folder.mkdir(parents=True)
        env[key] = str(folder)
    env["SBTK_P02_P03_REPLAY_PROFILE"] = env["APPDATA"]
    env["SBTK_SAFE_INSETS"] = "0,0,0"
    user = Path(env["APPDATA"]) / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    phases = []
    seen = set()
    for phase in PHASES:
        before = {name: sha(user / name) for name in FILES}
        log = evidence / f"{phase}.engine.log"
        console = evidence / f"{phase}.console.log"
        command = [str(engine), "--headless", "--fixed-fps", "60", "--resolution", "1600x900", "--path",
                   str(PROJECT), "--log-file", str(log), "--script",
                   "res://" + SCRIPT.relative_to(PROJECT).as_posix(), "--", phase]
        with console.open("xb") as stream, subprocess.Popen(
            command, cwd=PROJECT, env=env, stdout=stream, stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW,
        ) as child:
            try:
                status = child.wait(timeout=120)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()
                status = None
        raw = log.read_text(encoding="utf-8", errors="replace") if log.is_file() else ""
        all_output = raw + "\n" + console.read_text(encoding="utf-8", errors="replace")
        diagnostics = sorted({line for line in all_output.splitlines()
                              if re.search(r"\b(?:ERROR|WARNING):", line)})
        checks = [line for line in raw.splitlines() if line.startswith("P03_PUBLIC_CURSOR_CHECK ")]
        markers = [line for line in raw.splitlines() if line.startswith("P02_P03_RESUMED_REPLAY_RESULT ")]
        marker = f"P02_P03_RESUMED_REPLAY_RESULT phase={phase} checks={len(checks)} failures=0 pid={child.pid}"
        after = {name: sha(user / name) for name in FILES}
        checks_pass = (len(checks) >= 10 and all(line.startswith("P03_PUBLIC_CURSOR_CHECK true ") for line in checks))
        if phase == "checkpoint":
            bytes_pass = not any(before.values()) and all(after[name] for name in (FILES[0], FILES[1], FILES[3]))
            bytes_pass = bytes_pass and after[FILES[2]] is None
        elif phase == "resume":
            bytes_pass = after == before | {FILES[2]: before[FILES[1]]} and after[FILES[2]] is not None
        else:
            bytes_pass = before == after and all(after.values())
        passed = (status == 0 and not diagnostics and markers == [marker] and checks_pass
                  and bytes_pass and child.pid not in seen)
        seen.add(child.pid)
        phases.append({"phase": phase, "command": command, "pid": child.pid, "exit": status, "checks": len(checks),
                       "diagnostics": diagnostics, "before": before, "after": after, "pass": passed,
                       "log_sha256": sha(log), "console_sha256": sha(console)})
        if not passed:
            break
    passed = len(phases) == len(PHASES) and all(phase["pass"] for phase in phases)
    result = {"head": subprocess.check_output(["git", "-c", f"safe.directory={PROJECT.as_posix()}", "-C",
                                               PROJECT, "rev-parse", "HEAD"], text=True).strip(),
              "engine_sha256": sha(engine), "script_sha256": sha(SCRIPT), "runner_sha256": sha(Path(__file__)),
              "phases": phases, "pass": passed}
    (evidence / "RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"resumed replay: {sum(phase['checks'] for phase in phases)} checks, pass={passed}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
