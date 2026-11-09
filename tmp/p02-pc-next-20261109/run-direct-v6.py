"""Execute one independently reviewed P02 attempt from an exact manifest."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
PYTHON = Path("C:/Python314/python.exe")
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe")
PWSH = Path("C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/native/powershell/pwsh.exe")
SUPERVISOR = BASE / "P02DirectJob.cs"
FOLDING = ".godot/editor/FleetBattle3D.tscn-folding-6fc9f3aa03723dcea84c2d7516fcefec.cfg"
FOLDING_SHA = "9b34a7fc95b0f9cd640941851bbb0ebc8777e0666f5560e828143047b26c7c93"
LAUNCHER = BASE / "launch-direct.ps1"
AUTO = ROOT / "tmp/p02-seventh-20261108/k5-world-product.gd"
BATTLE = "scenes/FleetBattle3D.tscn"
TEST = "tests/world_link.gd"
PROBE = "tests/p02_k5_world_product_probe.gd"
PRODUCT = ("scripts/world_link.gd", "view/world/world_map_screen.gd")
LANES = {
    "import": (300, ["--editor", "--import"]),
    "reject": (45, ["--script", "res://" + TEST, "--", "--direct-reject"]),
    "direct": (60, ["--script", "res://" + TEST, "--", "--direct-round-trip"]),
    "auto-complete": (195, ["--script", "res://" + PROBE, "--", "complete", "{result}"]),
    "auto-cancel": (90, ["--script", "res://" + PROBE, "--", "cancel", "{result}"]),
    "title": (75, ["--script", "res://tests/ui_flow.gd"]),
    "restart": (75, ["--script", "res://tests/battle_flow.gd"]),
}


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def require(condition, reason):
    if not condition:
        raise RuntimeError(reason)


def put(path, value):
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def exact(path, expected):
    require(path.is_file() and path.resolve() == path and sha(path) == expected.lower(), f"Path or SHA drift: {path}")


def inventory(project):
    return {p.relative_to(project).as_posix(): sha(p) for p in project.rglob("*") if p.is_file()}


def verify_reject_metadata(reject, reject_inventory):
    expected_scene_line = 'run/main_scene="res://scenes/FleetBattle3D.tscn"'
    allowed_folding_lines = [
        "[folding]", "",
        'node_unfolds=[NodePath("."), PackedStringArray("Visibility")]',
        "resource_unfolds=[]", "nodes_folded=[]", "animation_groups_folded=[]",
    ]
    checked = {"folding_metadata": {}, "project_scene_references": {}, "import_or_remap_files_checked": 0}
    require(BATTLE not in reject_inventory and not (reject / BATTLE).exists(), "Battle scene present in reject project")
    require(not any(name.casefold() in {"override.cfg", "project.binary"} for name in reject_inventory),
            "Unexpected project override or compiled project configuration")
    for name, digest in reject_inventory.items():
        lowered = name.casefold()
        if "fleetbattle3d.tscn-" in lowered or lowered.endswith(("fleetbattle3d.tscn.remap", "fleetbattle3d.tscn.import")):
            require(name == FOLDING and digest == FOLDING_SHA, f"Unknown scene cache/remap candidate: {name}")
            text = (reject / name).read_text(encoding="utf-8")
            require(text.splitlines() == allowed_folding_lines, "Unexpected scene folding format")
            checked["folding_metadata"][name] = {"sha256": digest, "lines": allowed_folding_lines}
        if lowered.endswith((".import", ".remap")):
            checked["import_or_remap_files_checked"] += 1
            content = (reject / name).read_text(encoding="utf-8-sig")
            require("fleetbattle3d.tscn" not in content.casefold(), f"Scene reference in import/remap metadata: {name}")
        if lowered.endswith(".godot"):
            content = (reject / name).read_text(encoding="utf-8-sig")
            lines = [line for line in content.splitlines() if "fleetbattle3d.tscn" in line.casefold()]
            if name == "project.godot":
                require(lines == [expected_scene_line], "Unexpected project scene reference")
            else:
                require(not lines, f"Unexpected nested project scene reference: {name}")
            if lines:
                checked["project_scene_references"][name] = lines
    require("project.godot" in checked["project_scene_references"], "Project scene check missing")
    return checked


def checkout(manifest, run):
    source = json.loads((BASE / "closure-v2.json").read_text(encoding="utf-8-sig"))
    branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip()
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    require((branch, head) == (manifest["branch"], manifest["head"]), "Git ref drift")
    staged = subprocess.check_output(["git", "diff", "--cached", "--name-only"], cwd=ROOT)
    require(not staged, "Index contains staged edits")
    git_index = subprocess.check_output(["git", "rev-parse", "--git-path", "index"], cwd=ROOT, text=True).strip()
    exact((ROOT / git_index).resolve(), manifest["index_sha256"])
    for name, digest in source["protected_nonowned_sha256"].items():
        exact(ROOT / name, digest)
    for name, digest in source["source_map"].items():
        src = ROOT / name
        require(src.is_relative_to(ROOT) and src.resolve().is_relative_to(ROOT), "Source escaped root")
        exact(src, digest)
        for side in ("before", "after"):
            dst = run / side / "project" / name
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
            exact(dst, digest)
    for side in ("before", "after"):
        project = run / side / "project"
        shutil.copyfile(BASE / "world-link-prepared-v6.gd.txt", project / TEST)
        shutil.copyfile(AUTO, project / PROBE)
        if side == "after":
            for name in PRODUCT:
                shutil.copyfile(BASE / "candidate" / (Path(name).name + ".txt"), project / name)
        put(run / side / "pre-import.json", inventory(project))


def command(run, side, lane, project):
    seconds, flags = LANES[lane]
    out = run / side / lane
    user = out / "roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    recorded_env = {
        "APPDATA": str(out / "roaming"), "LOCALAPPDATA": str(out / "local"),
        "XDG_DATA_HOME": str(out / "roaming"), "TEMP": str(out / "temp"), "TMP": str(out / "temp"),
        "P02_PC_EXPECT_PROJECT": project.as_posix(), "P02_PC_EXPECT_USER": user.as_posix(),
    }
    argv = [str(ENGINE), "--headless", "--path", str(project), "--log-file", str(out / "engine.log")]
    argv.extend(str(out / "result.json") if flag == "{result}" else flag for flag in flags)
    return {
        "argv": argv, "env": recorded_env, "cwd": str(project), "os_log": str(out / "engine.os.tsv"),
        "abort": str(run / "abort"), "timeout_seconds": seconds,
        "expected_engine_exit": 1 if side == "before" and lane == "reject" else 0,
    }


def invoke(run, side, lane, project, approved, source_sha):
    out = run / side / lane
    record = command(run, side, lane, project)
    require(approved == record, "Materialized command differs from approved matrix")
    require(not (run / "abort").exists(), "Controller abort")
    out.mkdir()
    for kind in ("roaming", "local", "temp"):
        (out / kind).mkdir()
    if lane in ("direct", "auto-complete", "auto-cancel"):
        user = Path(record["env"]["P02_PC_EXPECT_USER"])
        user.mkdir(parents=True)
        with (user / "settings.cfg").open("xb") as settings:
            settings.write(b"[progress]\nprologue_seen=true\n")
    put(out / "command.json", record)
    launch_argv = [str(PWSH), "-NoProfile", "-NonInteractive", "-File", str(LAUNCHER),
                   "-CommandFile", str(out / "command.json"), "-SourceSha", source_sha]
    put(out / "supervisor-argv.json", launch_argv)
    with (out / "supervisor.stdout").open("xb") as output, (out / "supervisor.stderr").open("xb") as errors:
        child = subprocess.Popen(launch_argv, cwd=out, stdout=output, stderr=errors,
                                 creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            supervisor_exit = child.wait(timeout=record["timeout_seconds"] + 45)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            (run / "abort").touch(exist_ok=True)
            try:
                supervisor_exit = child.wait(timeout=15)
            except subprocess.TimeoutExpired:
                child.kill()  # exact owned supervisor handle, never a PID search
                supervisor_exit = child.wait(timeout=5)
            put(out / "interrupted.json", {"supervisor_exit": supervisor_exit, "reason": "external watchdog or interruption"})
            raise
    put(out / "supervisor-exit.json", supervisor_exit)
    require(supervisor_exit == 0, "Direct C# supervisor failed")
    os_log = (out / "engine.os.tsv").read_text(encoding="utf-8")
    expected_exit = record["expected_engine_exit"]
    rows = [line.split("\t")[2:] for line in os_log.splitlines()]
    require([r for r in rows if r[0] == "exit"] == [["exit", str(expected_exit)]], "Actual Godot exit missing or wrong")
    require([r for r in rows if r[0] == "cleanup"] == [["cleanup", "0"]], "Job cleanup is incomplete")
    require([r for r in rows if r[0] == "root_cleanup"] == [["root_cleanup", "True", "True", "0", str(expected_exit), "True"]],
            "Root signal or actual cleanup exit missing")
    require(not any(r[0] in {"supervisor_error", "cleanup_snapshot_error", "cleanup_request"} for r in rows), "Cleanup or supervisor error")
    engine_log = (out / "engine.log").read_text(encoding="utf-8", errors="strict")
    require("Godot Engine v4.7.2.stable.official.ed1daf0bf" in engine_log, "Unexpected engine header")
    require(not re.search(r"SCRIPT ERROR|Parse Error", engine_log), "Script/parse error")
    put(out / "evidence-sha.json", inventory(out))
    combined = engine_log
    for line in combined.splitlines():
        if not re.search(r"(^|\s)ERROR:", line):
            continue
        known_teardown = "resources still in use at exit" in line
        known_reject = lane == "reject" and any(phrase in line for phrase in (
            "Cannot open file 'res://scenes/FleetBattle3D.tscn'.",
            "Failed loading resource: res://scenes/FleetBattle3D.tscn.",
        ))
        known_baseline = side == "before" and lane == "reject" and "TEST_FAIL " in line
        require(known_teardown or known_reject or known_baseline, f"Unexpected error diagnostic: {line}")
    if lane == "reject":
        expected_ids = ["F1", "F2", "F3"] + [f"R{i}" for i in range(1, 7)] + [f"A{i}" for i in range(1, 11)]
        expected_ids += [f"{prefix}{i}" for prefix in ("BS", "BN") for i in range(1, 14)]
        rows = re.findall(r"^PC_DIRECT_ROW (\w+) (PASS|FAIL)\s*$", engine_log, re.MULTILINE)
        require([r[0] for r in rows] == expected_ids and "PC_DIRECT_REJECT_DONE " in engine_log, "Missing/extra rejection rows")
        require((all(r[1] == "PASS" for r in rows)) == (side == "after"), "Unexpected rejection verdict")
        if side == "before":
            mandatory_failures = {"R1", "R3", "R4", "R5", "R6", "A2", "A3", "A4", "A5", "BS6", "BN6"}
            require(mandatory_failures <= {row_id for row_id, verdict in rows if verdict == "FAIL"},
                    "Baseline did not expose the expected contract violations")

        for phrase in ("Cannot open file 'res://scenes/FleetBattle3D.tscn'.", "Failed loading resource: res://scenes/FleetBattle3D.tscn."):
            require(engine_log.count(phrase) == 4, f"Unexpected engine refusal log: {phrase}")
    elif lane == "direct":
        require(re.findall(r"^PC_DIRECT_ROW (C\d) PASS\s*$", engine_log, re.MULTILINE) == ["C1", "C2", "C3", "C4"], "Direct rows")
        require("PC_DIRECT_ROUND_TRIP_DONE 0" in engine_log, "Missing direct completion")
    elif lane in ("title", "restart"):
        expected_marker = "UI_FLOW_PASS" if lane == "title" else "BATTLE_FLOW_PASS"
        require(engine_log.splitlines().count(expected_marker) == 1, f"Missing {lane} completion")
    elif lane in ("auto-complete", "auto-cancel"):
        rows = json.loads((out / "result.json").read_text(encoding="utf-8"))
        require(len(rows) == (14 if lane == "auto-complete" else 15) and all(r["ok"] for r in rows), "Auto rows")


def matrix(output):
    return {
        side: {
            lane: command(output, side, lane, output / side / ("reject-project" if lane == "reject" else "project"))
            for lane in LANES
        }
        for side in ("before", "after")
    }


def required_paths():
    return {
        PYTHON, ENGINE, PWSH, AUTO, SUPERVISOR, LAUNCHER, Path(__file__).resolve(),
        BASE / "closure-v2.json", BASE / "world-link-prepared-v6.gd.txt",
        *(BASE / "candidate" / (Path(name).name + ".txt") for name in PRODUCT),
    }


def run(approval, expected_sha):
    exact(approval, expected_sha)
    manifest = json.loads(approval.read_text(encoding="utf-8-sig"))
    require(manifest["status"] == "INDEPENDENTLY_APPROVED_P02_PC_NEXT_EXECUTION", "Plan is unapproved")
    require(approval.parent == BASE, "Manifest outside evidence")
    attempt = manifest["attempt"]
    require(type(attempt) is int and 1 <= attempt <= 6, "Invalid attempt")
    output = BASE / f"attempt-{attempt:02d}"
    require(not output.exists() and output.resolve() == output, "Attempt already exists or unsafe path")
    require(Path(sys.executable).resolve() == PYTHON, "Unexpected Python executable")
    require(set(manifest["files"]) == {str(p) for p in required_paths()}, "Approval file list mismatch")
    for path, digest in manifest["files"].items():
        exact(Path(path), digest)
    actual_matrix = matrix(output)
    require(manifest["commands"] == actual_matrix, "Approved argv or environment changed")
    source_sha = manifest["files"][str(SUPERVISOR)]
    output.mkdir()
    checkout(manifest, output)
    for side in ("before", "after"):
        path = output / side / "project"
        invoke(output, side, "import", path, actual_matrix[side]["import"], source_sha)
        imported = inventory(path)
        put(output / side / "post-import.json", imported)
        reject = output / side / "reject-project"
        shutil.copytree(path, reject, ignore=lambda directory, names: ["FleetBattle3D.tscn"] if Path(directory) == path / "scenes" else [])
        require(not (reject / BATTLE).exists(), "Reject scene unexpectedly present")
        reject_inventory = inventory(reject)
        require(reject_inventory == {k: v for k, v in imported.items() if k != BATTLE}, "Reject closure drift")
        guard = verify_reject_metadata(reject, reject_inventory)
        put(output / side / "reject-metadata-review.json", guard)
        put(output / side / "reject-closure.json", reject_inventory)
        for lane in LANES:
            if lane != "import":
                invoke(output, side, lane, reject if lane == "reject" else path, actual_matrix[side][lane], source_sha)
    for lane in ("auto-complete", "auto-cancel"):
        before = json.loads((output / "before" / lane / "result.json").read_text(encoding="utf-8"))
        after = json.loads((output / "after" / lane / "result.json").read_text(encoding="utf-8"))
        if lane == "auto-complete":
            before_join = next(r["details"] for r in before if r["assertion"] == "result-join")
            after_join = next(r["details"] for r in after if r["assertion"] == "result-join")
            require(before_join == after_join, "Auto outcome or fingerprint changed")
        require([r["assertion"] for r in before] == [r["assertion"] for r in after], "Auto row IDs changed")
    put(output / "completed.json", {"attempt": attempt, "provenance": "pending independent 5-b review"})


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Expected independent approval manifest and its SHA-256")
    run(Path(sys.argv[1]).resolve(), sys.argv[2])
