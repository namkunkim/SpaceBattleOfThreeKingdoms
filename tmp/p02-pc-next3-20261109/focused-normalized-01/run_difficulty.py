from collections import Counter
from pathlib import Path
import json
import shutil
import subprocess
import sys
import time

from freeze_difficulty import BASE, ROOT, OUT, PROJECT, PWSH, SETTINGS, ORACLE, FLEET, PROBE, CANDIDATE, git, read, sha

REVIEWED = BASE / "EXECUTION-REVIEW-ONLY.json"
APPROVAL = BASE / "EXECUTION-INDEPENDENT-APPROVED.json"
TERMINAL = (
    "WARNING: ObjectDB instances leaked at exit",
    "ERROR: ",  # Resource line receives additional exact suffix check below.
)

def require(ok, reason):
    if not ok:
        raise RuntimeError(reason)

def free():
    return shutil.disk_usage(BASE).free

def verify_sources(spec, inventory):
    require(git("rev-parse", "HEAD") == [spec["head"]] and not git("diff", "--cached", "--name-only"), "HEAD or staged drift")
    require(sha(ROOT / git("rev-parse", "--git-path", "index")[0]) == spec["index_sha256"], "Index drift")
    for path, want in spec["files"].items():
        require(sha(Path(path)) == want, "Tool/fixture drift: " + path)
    for key, row in inventory["closure"].items():
        require(sha(ROOT / key) == row["sha256"], "Shared source drift: " + key)

def verify_project(expected):
    for key, want in expected.items():
        require(sha(PROJECT / key) == want, "Isolated project drift: " + key)

def recycle_cache(spec):
    root = PROJECT.resolve()
    cache = root / ".godot"
    held = root / ".godot.p02-recycle"
    require(root == PROJECT and root.parent == OUT.resolve() and root.is_relative_to(BASE.resolve()), "Cache parent scope")
    require(cache.is_dir() and cache.resolve() == cache and not cache.is_symlink() and not cache.is_junction(), "Cache missing or linked")
    require(not held.exists() and held.resolve() == held and not held.is_symlink(), "Recycle destination exists")
    for item in cache.rglob("*"):
        require(not item.is_symlink() and not item.is_junction(), "Cache contains links: " + str(item))
    size = sum(p.stat().st_size for p in cache.rglob("*") if p.is_file())
    require(size <= 400000000, "Cache exceeded 400 MB")
    with (OUT / "cache-recycle.jsonl").open("x", encoding="utf-8") as report:
        report.write(json.dumps({"step": "verified", "cache": str(cache), "held": str(held), "bytes": size, "free": free()}) + "\n")
        report.flush()
        cache.rename(held)
        require(held.resolve() == held and held.parent == root and not cache.exists(), "Moved cache drift")
        report.write(json.dumps({"step": "renamed", "held": str(held)}) + "\n")
        report.flush()
        shutil.rmtree(held)
        report.write(json.dumps({"step": "removed", "free": free()}) + "\n")
    require(free() >= spec["runtime_free_floor_bytes"], "Free space after cache recycle")

def run_lane(command, spec):
    path = Path(command["command_file"])
    log = path.parent
    log.mkdir(parents=True)
    for key in ("APPDATA", "LOCALAPPDATA", "TEMP"):
        Path(command["env"][key]).mkdir()
    if command["returning_cfg"]:
        user = Path(command["env"]["P02_PC_EXPECT_USER"])
        user.mkdir(parents=True)
        shutil.copyfile(SETTINGS, user / "settings.cfg")
    path.write_text(json.dumps(command, ensure_ascii=False), encoding="utf-8")
    args = [str(PWSH), "-NoLogo", "-NoProfile", "-NonInteractive", "-File", str(BASE / "launch.ps1"),
            "-CommandFile", str(path), "-SourceSha", spec["files"][str(BASE / "P02DirectJob.cs")]]
    with (log / "supervisor.stdout").open("xb") as stdout, (log / "supervisor.stderr").open("xb") as stderr:
        with subprocess.Popen(args, cwd=PROJECT, stdout=stdout, stderr=stderr) as process:
            start = time.monotonic()
            abort_reason = ""
            while process.poll() is None:
                if free() < spec["runtime_free_floor_bytes"]:
                    abort_reason = "Runtime storage floor"
                elif time.monotonic() - start > command["timeout_seconds"] + 20:
                    abort_reason = "Supervisor deadline"
                if abort_reason:
                    Path(command["abort"]).touch()
                    try:
                        process.wait(timeout=20)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    raise RuntimeError(abort_reason)
                time.sleep(0.2)
            require(process.returncode == 0, "Supervisor failed " + str(log))
    return log

def assess(command, log, pairs):
    code = str(command["expected_engine_exit"])
    events = [line.split("\t")[2:] for line in Path(command["os_log"]).read_text(encoding="utf-8").splitlines()]
    require(events.count(["exit", code]) == 1 and events.count(["cleanup", "0"]) == 1, "Job exit/drain")
    require(events.count(["root_cleanup", "True", "True", "0", code, "True"]) == 1, "Root cleanup")
    lines = (log / "engine.log").read_text(encoding="utf-8", errors="replace").splitlines()
    require(not any("SCRIPT ERROR:" in line for line in lines), "Engine script error")
    diagnostics = Counter(x for x in lines if x.startswith(("ERROR:", "WARNING:")))
    expected = Counter(command["diagnostics"])
    require(not (expected - diagnostics), f"Missing diagnostics {expected-diagnostics}")
    extra = diagnostics - expected
    for msg in extra:
        require(msg.startswith(TERMINAL[0]) or (msg.startswith("ERROR: ") and "resources still in use at exit" in msg), f"Unplanned diagnostic {msg}")
    lane = command["lane"]
    side = command["side"]
    if side == "before":
        pairs[lane] = extra
    elif side == "after":
        require(extra == pairs[lane], "Terminal diagnostic delta")
    else:
        require(not extra, "Physical lane diagnostic has no baseline peer")
    if lane != "import":
        raw = read(log / "raw.json")
        require((raw["lane"], raw["phase"]) == (lane, side), "Raw lane identity")
        require(set(raw["checks"]) == set(command["expected_ids"]), "Unexpected assertion denominator")
        require(set(raw["failed"]) == set(command["expected_reds"]) == {k for k,v in raw["checks"].items() if v is False}, "Unexpected assertions")
        require(lines.count(f"P02_DIFFICULTY_DONE {len(raw['checks'])} {len(raw['failed'])}") == 1, "Missing sentinel")
    return {"side": side, "lane": lane, "exit": int(code), "diagnostics": dict(diagnostics)}

def main():
    require(len(sys.argv) == 2 and Path(sys.argv[1]).resolve() == APPROVAL, "Independent approval path required")
    approved = read(APPROVAL)
    require(approved == {"status": "INDEPENDENT_APPROVED", "review_only_sha256": sha(REVIEWED),
                         "scope": "focused-normalized-headless-14-only"}, "Independent headless approval SHA mismatch")
    spec = read(REVIEWED)
    inventory = read(Path(spec["source_inventory"]))
    require(spec["status"] == "REVIEW_ONLY" and Path(spec["attempt_root"]) == OUT and OUT.resolve() == OUT, "Scope mismatch")
    commands = spec["commands"]
    require(len(commands) == 14 and spec["attempt_limit"] == 1 and sum(x["timeout_seconds"] for x in commands) == spec["timeout_sum_seconds"], "Lane count drift")
    verify_sources(spec, inventory)
    require(free() >= spec["minimum_free_bytes"], "Start free space floor")
    OUT.mkdir()
    with (OUT / "scope.json").open("x", encoding="utf-8") as f:
        json.dump({"scope": "focused-normalized-headless-14-only", "physical_gui": "unverified",
                   "physical_launches": 0, "os_inputs": 0, "pc0_reruns": 0}, f)
    expected = {}
    for key, row in inventory["closure"].items():
        target = PROJECT / key
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / key, target)
        expected[key] = row["sha256"]
    for source, key in ((PROBE, "tests/p02_difficulty_probe.gd"),
                        (ORACLE, "tests/p02_difficulty_oracle.json")):
        shutil.copyfile(source, PROJECT / key)
        expected[key] = spec["files"][str(source)]
    verify_project(expected)
    pairs = {}
    for lane in commands:
        require(free() >= spec["runtime_free_floor_bytes"] and not (OUT / "abort").exists(), "Lane precondition")
        if lane["side"] == "after" and lane["lane"] == "import":
            verify_sources(spec, inventory)
            recycle_cache(spec)
            candidate = CANDIDATE
            shutil.copyfile(candidate, PROJECT / FLEET)
            expected[FLEET] = spec["files"][str(candidate)]
            verify_project(expected)
        log = run_lane(lane, spec)
        result = assess(lane, log, pairs)
        verify_project(expected)
        with (OUT / "results.jsonl").open("a", encoding="utf-8") as f:
            f.write(json.dumps(result, ensure_ascii=False) + "\n")
    verify_sources(spec, inventory)

if __name__ == "__main__":
    main()
