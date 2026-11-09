"""Execute one independently reviewed P02 attempt from an exact manifest."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
BROKER = ROOT / "tmp/p02-ninth-20261108/prep-ab-sol/variant-abi-review/owned_job_python_nowindow_candidate.py"
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
ENGINE_CHILD = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe")
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
        shutil.copyfile(BASE / "world-link-prepared.gd.txt", project / TEST)
        shutil.copyfile(AUTO, project / PROBE)
        if side == "after":
            for name in PRODUCT:
                shutil.copyfile(BASE / "candidate" / Path(name).name, project / name)
        put(run / side / "pre-import.json", inventory(project))


def invoke(job, run, side, lane, project):
    seconds, flags = LANES[lane]
    out = run / side / lane
    out.mkdir()
    for kind in ("roaming", "local", "temp"):
        (out / kind).mkdir()
    user = out / "roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    env = os.environ.copy()
    recorded_env = {
        "APPDATA": str(out / "roaming"), "LOCALAPPDATA": str(out / "local"),
        "XDG_DATA_HOME": str(out / "roaming"), "TEMP": str(out / "temp"), "TMP": str(out / "temp"),
        "P02_PC_EXPECT_PROJECT": project.as_posix(), "P02_PC_EXPECT_USER": user.as_posix(),
    }
    env.update(recorded_env)
    if lane in ("direct", "auto-complete", "auto-cancel"):
        user.mkdir(parents=True)
        with (user / "settings.cfg").open("xb") as settings:
            settings.write(b"[progress]\nprologue_seen=true\n")
    argv = [str(ENGINE), "--headless", "--path", str(project), "--log-file", str(out / "engine.log")]
    argv.extend(str(out / "result.json") if flag == "{result}" else flag for flag in flags)
    put(out / "command.json", {"argv": argv, "env": recorded_env, "timeout_seconds": seconds})
    start = time.monotonic()
    try:
        with (out / "stdout.bin").open("xb", buffering=0) as stdout, (out / "stderr.bin").open("xb", buffering=0) as stderr:
            receipt = job.run(argv, project, env, stdout, stderr, start + seconds, 10,
                              stop=lambda: (run / "abort").exists(),
                              on_start=lambda pid: put(out / "broker-pid.json", pid))
    except BaseException as error:
        put(out / "supervisor-error.json", {"type": type(error).__name__, "message": str(error)})
        raise
    receipt["elapsed_seconds"] = time.monotonic() - start
    receipt["files"] = inventory(out)
    put(out / "receipt.json", receipt)
    require(receipt["interruption"] is None and receipt["active_at_join"] == 0, f"Owned process interrupted: {lane}")
    expected_exit = 1 if side == "before" and lane == "reject" else 0
    require(receipt["exit"] == expected_exit, f"Unexpected actual exit: {side}/{lane}")
    engine_log = (out / "engine.log").read_text(encoding="utf-8", errors="replace")
    stdout = (out / "stdout.bin").read_text(encoding="utf-8", errors="replace")
    stderr = (out / "stderr.bin").read_text(encoding="utf-8", errors="replace")
    require(not re.search(r"SCRIPT ERROR|Parse Error", engine_log + stdout + stderr), "Script/parse error")
    combined = engine_log + stdout + stderr
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
        rows = re.findall(r"^PC_DIRECT_ROW (\w+) (PASS|FAIL)\s*$", stdout, re.MULTILINE)
        require([r[0] for r in rows] == expected_ids and "PC_DIRECT_REJECT_DONE " in stdout, "Missing/extra rejection rows")
        require((all(r[1] == "PASS" for r in rows)) == (side == "after"), "Unexpected rejection verdict")
        for phrase in ("Cannot open file 'res://scenes/FleetBattle3D.tscn'.", "Failed loading resource: res://scenes/FleetBattle3D.tscn."):
            require(stderr.count(phrase) == 4, f"Unexpected engine refusal log: {phrase}")
    elif lane == "direct":
        require(re.findall(r"^PC_DIRECT_ROW (C\d) PASS\s*$", stdout, re.MULTILINE) == ["C1", "C2", "C3", "C4"], "Direct rows")
        require("PC_DIRECT_ROUND_TRIP_DONE 0" in stdout, "Missing direct completion")
    elif lane in ("title", "restart"):
        expected_marker = "UI_FLOW_PASS" if lane == "title" else "BATTLE_FLOW_PASS"
        require(stdout.splitlines().count(expected_marker) == 1, f"Missing {lane} completion")
    elif lane in ("auto-complete", "auto-cancel"):
        rows = json.loads((out / "result.json").read_text(encoding="utf-8"))
        require(len(rows) == (14 if lane == "auto-complete" else 15) and all(r["ok"] for r in rows), "Auto rows")


def run(approval, expected_sha):
    exact(approval, expected_sha)
    manifest = json.loads(approval.read_text(encoding="utf-8-sig"))
    require(manifest["status"] == "INDEPENDENTLY_APPROVED_P02_PC_NEXT_EXECUTION", "Plan is unapproved")
    require(approval.parent == BASE, "Manifest outside evidence")
    attempt = manifest["attempt"]
    require(type(attempt) is int and 1 <= attempt <= 6, "Invalid attempt")
    output = BASE / f"attempt-{attempt:02d}"
    require(not output.exists() and output.resolve() == output, "Attempt already exists or unsafe path")
    required = {str(p) for p in (ENGINE, ENGINE_CHILD, AUTO, BROKER, Path(__file__).resolve(),
                                BASE / "closure-v2.json", BASE / "world-link-prepared.gd.txt")}
    required |= {str(BASE / "candidate" / Path(name).name) for name in PRODUCT}
    require(set(manifest["files"]) == required, "Approval file list mismatch")
    for path, digest in manifest["files"].items():
        exact(Path(path), digest)
    spec = importlib.util.spec_from_file_location("p02_owned_job", BROKER)
    job = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(job)
    output.mkdir()
    checkout(manifest, output)
    for side in ("before", "after"):
        path = output / side / "project"
        invoke(job, output, side, "import", path)
        imported = inventory(path)
        put(output / side / "post-import.json", imported)
        reject = output / side / "reject-project"
        shutil.copytree(path, reject, ignore=lambda directory, names: ["FleetBattle3D.tscn"] if Path(directory) == path / "scenes" else [])
        require(not (reject / BATTLE).exists(), "Reject scene unexpectedly present")
        reject_inventory = inventory(reject)
        require(reject_inventory == {k: v for k, v in imported.items() if k != BATTLE}, "Reject closure drift")
        require(not any("fleetbattle3d.tscn-" in k.lower() or k.lower().endswith("fleetbattle3d.tscn.remap") for k in reject_inventory), "Possible cached/remapped scene")
        put(output / side / "reject-closure.json", reject_inventory)
        for lane in LANES:
            if lane != "import":
                invoke(job, output, side, lane, reject if lane == "reject" else path)
    put(output / "completed.json", {"attempt": attempt, "provenance": "pending independent 5-b review"})


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Expected independent approval manifest and its SHA-256")
    run(Path(sys.argv[1]).resolve(), sys.argv[2])
