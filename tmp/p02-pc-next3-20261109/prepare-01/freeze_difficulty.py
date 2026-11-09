from pathlib import Path
import hashlib
import json
import shutil
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OUT = BASE / "attempt-01"
PROJECT = OUT / "project"
ENGINE = Path(r"C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe")
PWSH = Path(shutil.which("pwsh"))
PYTHON = Path(shutil.which("python"))
SETTINGS = BASE.parents[1] / "p02-sixth-20261108/returning-settings.cfg"
ORACLE = BASE.parent / "data-oracle-v2.json"
FLEET = "scripts/FleetBattle3D.gd"
STEPS = ("01-card", "02-difficulty", "03-mode", "04-sortie", "05-sortie-skip",
         "06-prologue-skip", "07-place-mode", "08-start", "09-place-confirm")
DIRECT = "route.seed route.difficulty profile.host profile.rules roster.full roster.wait roster.brief start.controls placement.tick result.seed result.difficulty result.once"
IDS = {
    "D01": DIRECT, "D02": DIRECT, "D03": DIRECT + " fixture.clean_prologue", "D04": DIRECT,
    "D05": "org.open.rules org.apply.excluded profile.rules roster.full roster.wait",
    "D06": "start.controls placement.tick retry.same.brief retry.new.sim retry.same.seed retry.same.rules retry.same.roster",
    "D07": "prepare.no.sim prepare.no.deck prepare.notice return.map return.no.result return.last.difficulty",
    "D08": "start.controls placement.tick fail.same.sim fail.same.seed fail.same.difficulty fail.same.g fail.same.clocks fail.same.selection fail.same.trace fail.same.link fail.notice retry.valid",
    "D09": "legacy.title legacy.default.rules legacy.roster start.controls placement.tick legacy.restart",
    "D10": "auto.validate auto.worker.started auto.completed auto.joined auto.outcome.seed auto.outcome.difficulty",
    "D11": "fallback.org.errors fallback.start.blocked fallback.rules fallback.roster",
    "D12": "poc.rs.empty poc.no.scenario poc.legacy.difficulty poc.no.link",
    "D13": "fixture.invalid_auto_contract invalid.no.sim invalid.notice invalid.return.no.result",
}
RED_DIRECT = "profile.host profile.rules roster.full roster.wait"
REDS = {"D01": RED_DIRECT, "D03": RED_DIRECT, "D04": RED_DIRECT,
        "D05": "org.open.rules profile.rules roster.full roster.wait",
        "D06": "retry.same.rules retry.same.roster", "D11": "fallback.rules fallback.roster",
        "D13": "invalid.no.sim invalid.notice invalid.return.no.result"}
DIAGNOSTICS = {
    "D07": "ERROR: [FleetBattle3D] invalid_candidate_profile at profile.foe",
    "D08": "ERROR: [FleetBattle3D] invalid_candidate_profile at profile",
    "D13": "ERROR: [FleetBattle3D] invalid_brief_difficulty at brief.difficulty",
}

def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def read(path):
    return json.loads(path.read_bytes())

def git(*argv):
    return subprocess.check_output(["git", "--no-optional-locks", *argv], cwd=ROOT).decode().splitlines()

def command(side, lane, seconds):
    path = OUT / side / lane
    roaming = path / "roaming"
    user = roaming / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    native = side == "after-physical"
    argv = [str(ENGINE), "--windowed" if native else "--headless", "--path", str(PROJECT),
            "--log-file", str(path / "engine.log")]
    if lane == "import":
        argv += ["--editor", "--import"]
    else:
        if native:
            argv += ["--resolution", "1600x900", "--position", "80,80"]
        argv += ["--script", "res://tests/p02_difficulty_probe.gd", "--", lane, side]
    red = REDS.get(lane, "").split() if side == "before" else []
    ids = IDS.get(lane, "").split()
    if native:
        ids = ["route.seed", "route.difficulty", "profile.host", "profile.rules", "roster.full",
               "roster.wait", "start.controls", "placement.tick", "physical.final_viewport"]
        ids += [f"physical.input.{step}" for step in STEPS]
    diagnostics = [] if lane not in DIAGNOSTICS or (side == "before" and lane == "D13") else [DIAGNOSTICS[lane]]
    return {
        "side": side, "lane": lane, "argv": argv, "cwd": str(PROJECT),
        "command_file": str(path / "command.json"), "os_log": str(path / "engine.os.tsv"),
        "abort": str(OUT / "abort"), "timeout_seconds": seconds, "expected_engine_exit": int(bool(red)),
        "env": {
            "APPDATA": str(roaming), "LOCALAPPDATA": str(path / "local"), "TEMP": str(path / "temp"),
            "TMP": str(path / "temp"), "XDG_DATA_HOME": str(roaming),
            "P02_PC_EXPECT_PROJECT": PROJECT.as_posix(), "P02_PC_EXPECT_USER": user.as_posix(),
            "P02_DIFFICULTY_RAW": str(path / "raw.json"), "P02_PHYSICAL_DIR": str(path) if native else "",
        },
        "returning_cfg": side in ("before", "after") and lane not in ("import", "D03"),
        "expected_ids": ids, "expected_reds": red, "diagnostics": diagnostics,
    }

def main():
    inventory = read(BASE / "source-inventory.json")
    assert len(inventory["closure"]) == 1480
    runtime = {"assets", "core", "data", "hud", "input", "scenes", "scripts", "tests", "view"}
    tracked = subprocess.check_output(["git", "--no-optional-locks", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    omitted = [n for n in tracked if n.split("/")[0] in runtime and n not in inventory["closure"]]
    assert all(n.startswith("tests/") or Path(n).suffix in (".md", ".py", ".txt") for n in omitted), omitted
    assert git("rev-parse", "HEAD") == [inventory["head"]]
    assert git("diff", "--cached", "--name-only") == inventory["staged"] == []
    assert sha(ROOT / git("rev-parse", "--git-path", "index")[0]) == inventory["index_sha256"]
    assert all(sha(ROOT / n) == row["sha256"] for n, row in inventory["closure"].items())
    assert sha(BASE / "before" / FLEET) == inventory["closure"][FLEET]["sha256"]
    commands = []
    for side in ("before", "after"):
        commands.append(command(side, "import", 240))
        for lane in IDS:
            seconds = 240 if lane == "D10" else 90 if lane in ("D07", "D08", "D11", "D12", "D13") else 120
            commands.append(command(side, lane, seconds))
    commands.append(command("after-physical", "D03", 180))
    assert len(commands) == 29 and sum(x["expected_engine_exit"] for x in commands) == 7
    files = [ENGINE, PWSH, PYTHON, SETTINGS, ORACLE, BASE / "source-inventory.json",
             BASE / "freeze_difficulty.py", BASE / "run_difficulty.py", BASE / "CUA-PHYSICAL-POLICY.md",
             BASE / "P02DirectJob.cs", BASE / "launch.ps1", BASE / "verify_oracle.py",
             BASE / "p02_difficulty_probe.gd", BASE / "before" / FLEET, BASE / "after" / FLEET,
             BASE / "candidate.diff", BASE.parent / "PLAN-V2.md", BASE.parent / "REVIEW-PLAN-V2-INDEPENDENT.md",
             BASE.parents[1] / "p02-eighth-20261108/candidate-product.patch"]
    manifest = {
        "status": "REVIEW_ONLY", "attempt_root": str(OUT), "project": str(PROJECT),
        "head": inventory["head"], "index_sha256": inventory["index_sha256"],
        "source_inventory": str(BASE / "source-inventory.json"), "excluded_tracked_runtime_prefix_paths": omitted,
        "files": {str(x): sha(x) for x in files}, "commands": commands,
        "timeout_sum_seconds": sum(x["timeout_seconds"] for x in commands),
        "minimum_free_bytes": 2900000000, "runtime_free_floor_bytes": 1500000000,
        "peak_budget_bytes": 1400000000, "at_freeze_free_bytes": shutil.disk_usage(BASE).free,
        "cache_recycle": "approval-bound two-step rename and verified removal of only attempt-01/project/.godot",
        "terminal_diagnostics": "Only exact normalized terminal leak lines paired with same named before lane may be accepted; all unexpected diagnostics fail",
        "physical_driver": "CUA only. Physical lane withheld unless a separate policy-compliant method and evidence scope are independently approved.",
        "reviewable_headless_processes": 28, "physical_processes": 1, "pc0": "2/2 held; no retry or claim",
    }
    with (BASE / "EXECUTION-REVIEW-ONLY.json").open("x", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")

if __name__ == "__main__":
    main()

