"""Freeze the reviewed source universe and commands. This file never launches a process."""
import hashlib
import json
import os
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
PREVIOUS = BASE.parent / "p02-pc-next-20261109"
OUT = BASE / "attempt-01"
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe")
PYTHON = Path("C:/Python314/python.exe")
PWSH = Path(os.environ["P02_RETURN_PWSH"])
RETURNING = BASE.parent / "p02-sixth-20261108/returning-settings.cfg"
LINK = "scripts/world_link.gd"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def put(path, value):
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def lane(side, name, seconds, args, exit_code=0):
    stage = OUT / side
    project = stage / "project"
    log = stage / name
    roaming = log / "roaming"
    user = roaming / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    return {
        "name": name, "side": side, "command_file": str(log / "command.json"),
        "argv": [str(ENGINE), "--headless", "--path", str(project), "--log-file", str(log / "engine.log"), *args],
        "env": {
            "APPDATA": str(roaming), "LOCALAPPDATA": str(log / "local"),
            "XDG_DATA_HOME": str(roaming), "TEMP": str(log / "temp"), "TMP": str(log / "temp"),
            "P02_PC_EXPECT_PROJECT": project.as_posix(), "P02_PC_EXPECT_USER": user.as_posix(),
        },
        "cwd": str(project), "os_log": str(log / "engine.os.tsv"),
        "abort": str(OUT / "abort"), "timeout_seconds": seconds, "expected_engine_exit": exit_code,
    }


old_closure = read(PREVIOUS / "closure-v2.json")["source_map"]
for path in (LINK, "view/world/world_map_screen.gd"):
    old_closure[path] = sha(PREVIOUS / "candidate" / (Path(path).name + ".txt"))
source_map = {path: sha(ROOT / path) for path in old_closure}
if source_map != old_closure:
    raise ValueError({path: (old_closure[path], digest) for path, digest in source_map.items() if digest != old_closure[path]})
baseline = read(BASE / "baseline.json")
for row in baseline["files"]:
    if sha(ROOT / row["path"]) != row["sha256"]:
        raise ValueError("Scoped baseline drift: " + row["path"])
source = (BASE / "world_link.before.gd.txt").read_bytes()
if sha(BASE / "world_link.before.gd.txt") != source_map[LINK]:
    raise ValueError("Backup differs from source")
anchor = b'\toutcome = o\n\tbrief = null\n\tget_tree().change_scene_to_file(WORLD_SCENE)'
replacement = b'''\tvar previous_brief := brief
\tvar previous_outcome := outcome
\toutcome = o
\tbrief = null
\tvar error := get_tree().change_scene_to_file(WORLD_SCENE)
\tif error != OK:
\t\tbrief = previous_brief
\t\toutcome = previous_outcome
\t\tpush_warning("WORLD_RETURN_REJECTED error=%d" % error)'''
if source.count(anchor) != 1:
    raise ValueError("Return hunk anchor drift")
candidate = BASE / "world_link.candidate.gd.txt"
patched = source.replace(anchor, replacement, 1)
if candidate.exists():
    if candidate.read_bytes() != patched:
        raise ValueError("Existing candidate drift")
else:
    with candidate.open("xb") as stream:
        stream.write(patched)
commands = []
for side in ("before", "after"):
    commands.append(lane(side, "import", 300, ["--editor", "--import"]))
    for name in ("result", "pause", "prepare", "result-ok", "pause-ok", "prepare-ok"):
        command = lane(side, name, 60, ["--script", "res://tests/p02_return_probe.gd", "--", name, side])
        rejected = 0 if name.endswith("-ok") else (1 if side == "before" else 2)
        accepted = not rejected or side == "after"
        assertions = ["scope", "arguments", "battle", "phase", "button", "map-uncached"]
        if rejected:
            assertions.append("hide-map")
            for index in range(1, rejected + 1):
                assertions.extend(f"reject-{index}-{key}" for key in ("scene", "ui", "settings", "brief", "queue"))
            assertions.append("restore-map")
        if accepted:
            assertions.extend(["accept-scene", "accept-queue", "accept-settings", "accept-view"])
            if name.startswith("result"):
                assertions.append("accept-facts")
        command["expected_assertions"] = assertions
        command["diagnostics"] = {
            "ERROR: Cannot open file 'res://scenes/WorldMap.tscn'.": rejected,
            "ERROR: Failed loading resource: res://scenes/WorldMap.tscn.": rejected,
            "WARNING: WORLD_RETURN_REJECTED error=19": rejected if side == "after" else 0,
            "ERROR: [FleetBattle3D] invalid_candidate_profile at profile": int(name.startswith("prepare")),
        }
        commands.append(command)
    for status in ("clean", "returning"):
        commands.append(lane(side, "world-" + status, 120, ["--script", "res://tests/world_link.gd", "--", "--quick"], 1 if status == "clean" else 0))
    commands.append(lane(side, "outbound-round-trip", 75, ["--script", "res://tests/p02_previous_roundtrip.gd", "--", "--direct-round-trip"]))
files = [
    ENGINE, PYTHON, PWSH, PREVIOUS / "launch-direct.ps1", PREVIOUS / "P02DirectJob.cs",
    PREVIOUS / "world-link-prepared-v6.gd.txt", RETURNING, BASE / "baseline.json",
    BASE / "prepare-manifest.py", BASE / "run-reviewed-return.py", BASE / "return-probe.gd.txt", candidate,
]
put(BASE / "EXECUTION-REVIEW-ONLY-V3.json", {
    "status": "REVIEW_ONLY", "attempt_root": str(OUT), "baseline": baseline,
    "files": {str(path): sha(path) for path in files}, "source_map": source_map,
    "expected_command_count": 20, "expected_timeout_sum_seconds": 1950,
    "powershell": str(PWSH), "returning_settings": str(RETURNING),
    "commands": commands,
})
