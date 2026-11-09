from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
OUT = BASE / "attempt-01"
PROJECT = OUT / "project"
PREVIOUS = BASE.parent / "p02-pc-next2-20261109"
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe")
PYTHON = Path("C:/Python314/python.exe")
PWSH = Path(shutil.which("pwsh"))
SETTINGS = BASE.parent / "p02-sixth-20261108/returning-settings.cfg"
PATCHED = ["scripts/world_link.gd", "scripts/FleetBattle3D.gd", "hud/ui_kit/command_deck.gd", "hud/ui_kit/deck_screens.gd"]

def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))

def git(*args):
    return subprocess.check_output(["git", "--no-optional-locks", *args], cwd=ROOT, text=True).strip()

def lane(side, name, flags, seconds, native=False):
    log = OUT / side / name
    roaming = log / "roaming"
    user = roaming / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    return {
        "name": name, "side": side, "command_file": str(log / "command.json"),
        "argv": [str(ENGINE), "--windowed" if native else "--headless", "--path", str(PROJECT), "--log-file", str(log / "engine.log"), *flags],
        "env": {
            "APPDATA": str(roaming), "LOCALAPPDATA": str(log / "local"),
            "XDG_DATA_HOME": str(roaming), "TEMP": str(log / "temp"), "TMP": str(log / "temp"),
            "P02_PC_EXPECT_PROJECT": PROJECT.as_posix(), "P02_PC_EXPECT_USER": user.as_posix(),
            "P02_NOTICE_CAPTURE": str(log) if native else "",
        },
        "cwd": str(PROJECT), "os_log": str(log / "engine.os.tsv"), "abort": str(OUT / "abort"),
        "timeout_seconds": seconds, "expected_engine_exit": 0,
    }

def probe(side, name, native=False):
    phase = name.removeprefix("standalone-").removesuffix("-ok")
    standalone = name.startswith("standalone-")
    rejects = not (standalone or name.endswith("-ok"))
    name_arg = name
    name = f"native-{name}" if native else name
    flags = ["--resolution", "1600x900"] if native else []
    cmd = lane(side, name, [*flags, "--script", "res://tests/p02_notice_probe.gd", "--", name_arg, side], 60, native)
    ids = ["scope", "arguments", "battle", "phase", "state-presence", "state-value", "button", "map-uncached", "hidden"]
    captures = []
    if native:
        captures.append("initial")
        ids.append("capture-initial")
    if standalone:
        ids.append("standalone-hidden")
        if phase != "prepare":
            ids.append("standalone-title")
    else:
        if rejects:
            ids.append("hide-map")
            for i in (1, 2):
                ids.extend(f"reject-{i}-{key}" for key in ("scene", "state-presence", "state-value", "ui", "settings", "brief", "queue", "sim", "focus-geometry", "guidance", "request", "actual-error", "notice"))
                if side == "after":
                    ids.append(f"reject-{i}-layout")
                if native:
                    ids.append(f"capture-reject-{i}")
                    captures.append(f"reject-{i}")
            ids.append("restore-map")
            if side == "after" and phase != "prepare":
                ids.append("reentry-hidden")
        ids.extend(["accept-request", "accept-old-scene", "accept-scene", "accept-queue", "accept-settings"])
        ids.extend(["accept-view", "accept-dto", "accept-facts"] if phase == "result" else ["accept-null", "accept-view"])
    cmd["expected_assertions"] = ids
    cmd["captures"] = captures
    cmd["diagnostics"] = {
        "ERROR: Cannot open file 'res://scenes/WorldMap.tscn'.": 2 * rejects,
        "ERROR: Failed loading resource: res://scenes/WorldMap.tscn.": 2 * rejects,
        "WARNING: WORLD_RETURN_REJECTED error=19": 2 * rejects,
        "ERROR: [FleetBattle3D] invalid_candidate_profile at profile": int(phase == "prepare"),
    }
    return cmd

def main():
    baseline = read(BASE / "baseline.json")
    if git("branch", "--show-current") != baseline["branch"] or git("rev-parse", "HEAD") != baseline["head"] or git("diff", "--cached", "--name-only") or sha(ROOT / git("rev-parse", "--git-path", "index")) != baseline["index_sha256"]:
        raise RuntimeError("Branch, HEAD or index changed")
    for row in baseline["files"]:
        if sha(ROOT / row["path"]) != row["sha256"]:
            raise RuntimeError(f"Scoped baseline drift: {row['path']}")
    previous = read(PREVIOUS / "ATTEMPT-02-EXECUTION-REVIEW-ONLY.json")
    paths = previous["source_map"].copy()
    paths["scripts/world_link.gd"] = sha(PREVIOUS / "world_link.candidate.gd.txt")
    source_map = {name: sha(ROOT / name) for name in paths}
    if source_map != paths:
        raise RuntimeError([name for name in paths if source_map[name] != paths[name]])
    for name in PATCHED:
        if sha(BASE / (Path(name).name + ".before.txt")) != source_map[name]:
            raise RuntimeError(f"Candidate base drift: {name}")
    commands = []
    for side in ("before", "after"):
        commands.append(lane(side, "import", ["--editor", "--import"], 300))
        for phase in ("pause", "result", "prepare"):
            for name in (phase, phase + "-ok", "standalone-" + phase):
                commands.append(probe(side, name))
            commands.append(probe(side, phase, native=True))
        cmd = lane(side, "returning-settings", ["--script", "res://tests/world_link.gd", "--", "--quick"], 120)
        cmd["copy_settings"] = True
        cmd["marker"] = "WORLD_LINK_PASS"
        commands.append(cmd)
    files = [ENGINE, PYTHON, PWSH, SETTINGS, PREVIOUS / "ATTEMPT-02-EXECUTION-REVIEW-ONLY.json", PREVIOUS / "REVIEW-CLOSEOUT-INDEPENDENT.md"]
    files += [p for p in BASE.iterdir() if p.is_file() and p.name not in ("EXECUTION-REVIEW-ONLY.json", "EXECUTION-INDEPENDENT-APPROVED.json")]
    for side in ("before", "after"):
        for phase in ("pause", "result", "prepare"):
            files.append(PREVIOUS / "attempt-02" / side / phase / "engine.log")
    manifest = {
        "status": "REVIEW_ONLY", "attempt_root": str(OUT), "baseline": baseline,
        "source_map": source_map, "source_bytes": sum((ROOT / name).stat().st_size for name in source_map),
        "files": {str(path): sha(path) for path in files}, "commands": commands, "patched": PATCHED,
        "settings": str(SETTINGS), "powershell": str(PWSH), "python": str(PYTHON),
        "minimum_free_bytes": 2800000000, "runtime_free_floor_bytes": 1500000000,
        "timeout_sum_seconds": sum(cmd["timeout_seconds"] for cmd in commands),
        "capture_method": "native renderer viewport PNG; fixture signal; no physical OS input",
    }
    with (BASE / "EXECUTION-REVIEW-ONLY.json").open("x", encoding="utf-8") as stream:
        json.dump(manifest, stream, ensure_ascii=False, indent=2)
        stream.write("\n")

if __name__ == "__main__":
    main()


