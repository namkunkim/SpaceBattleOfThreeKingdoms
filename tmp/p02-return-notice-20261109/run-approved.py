from collections import Counter
from pathlib import Path
import json
import shutil
import struct
import subprocess
import sys

from freeze import BASE, ROOT, OUT, PROJECT, read, sha, git

def require(ok, reason):
    if not ok:
        raise RuntimeError(reason)

def verify(manifest):
    baseline = manifest["baseline"]
    require(git("branch", "--show-current") == baseline["branch"], "Branch drift")
    require(git("rev-parse", "HEAD") == baseline["head"] and not git("diff", "--cached", "--name-only"), "HEAD/index drift")
    require(sha(ROOT / git("rev-parse", "--git-path", "index")) == baseline["index_sha256"], "Index drift")
    for name, digest in manifest["files"].items():
        require(sha(Path(name)) == digest, name)
    for name, digest in manifest["source_map"].items():
        require(sha(ROOT / name) == digest, name)
    for row in baseline["files"]:
        require(sha(ROOT / row["path"]) == row["sha256"], row["path"])

def stage(manifest, side, expected):
    files = manifest["files"]
    for name in manifest["patched"]:
        stem = Path(name).name
        suffix = ".fixture.txt" if stem == "world_link.gd" else ".txt"
        source = BASE / f"{stem}.{'before' if side == 'before' else 'candidate'}{suffix}"
        shutil.copyfile(source, PROJECT / name)
        expected[name] = files[str(source)]
    verify_project(expected)

def verify_project(expected):
    for name, digest in expected.items():
        require(sha(PROJECT / name) == digest, f"Isolated input drift: {name}")
    for name in ("scenes/WorldMap.tscn.p02-held", "override.cfg", "project.binary"):
        require(not (PROJECT / name).exists(), f"Unexpected path: {name}")
    for path in PROJECT.rglob("*"):
        if path.is_file() and path.suffix in (".import", ".remap"):
            require(b"worldmap.tscn" not in path.read_bytes().lower(), str(path))

def assess(command, log):
    lines = (log / "engine.log").read_text(encoding="utf-8", errors="replace").splitlines()
    events = [line.split("\t")[2:] for line in Path(command["os_log"]).read_text(encoding="utf-8").splitlines()]
    require(events.count(["exit", "0"]) == 1 and events.count(["cleanup", "0"]) == 1, f"{log}: exit/cleanup")
    require(events.count(["root_cleanup", "True", "True", "0", "0", "True"]) == 1, f"{log}: root cleanup")
    require(not any("SCRIPT ERROR:" in line for line in lines), f"{log}: script error")
    diagnostics = Counter(line for line in lines if line.startswith(("ERROR:", "WARNING:")))
    expected = +Counter(command.get("diagnostics", {}))
    require(diagnostics == expected, f"{log}: actual {diagnostics}, expected {expected}")
    if "expected_assertions" in command:
        ids = command["expected_assertions"]
        assertions = [line for line in lines if line.startswith("P02_RETURN_ASSERT ")]
        require(assertions == [f"P02_RETURN_ASSERT {key} PASS" for key in ids], f"{log}: assertion records")
        require([line for line in lines if line.startswith("P02_RETURN_DONE ")] == [f"P02_RETURN_DONE {len(ids)} 0"], f"{log}: completion record")
    if "marker" in command:
        require(lines.count(command["marker"]) == 1, f"{log}: settings marker")
    captures = {}
    for filename in command.get("captures", []):
        png = log / (filename + ".png")
        with png.open("rb") as stream:
            header = stream.read(24)
        require(header[:8] == b"\x89PNG\r\n\x1a\n" and struct.unpack(">II", header[16:]) == (1600, 900), str(png))
        captures[png.name] = sha(png)
    return {"lane": str(log), "diagnostics": dict(diagnostics), "captures": captures}

def main():
    reviewed = BASE / "EXECUTION-REVIEW-ONLY.json"
    approval = BASE / "EXECUTION-INDEPENDENT-APPROVED.json"
    require(len(sys.argv) == 2 and Path(sys.argv[1]).resolve() == approval, "Independent approval path required")
    require(read(approval) == {"status": "INDEPENDENT_APPROVED", "review_only_sha256": sha(reviewed)}, "Independent approval SHA mismatch")
    manifest = read(reviewed)
    require(manifest["status"] == "REVIEW_ONLY" and manifest["attempt_root"] == str(OUT) and OUT.resolve() == OUT, "Unexpected attempt root")
    commands = manifest["commands"]
    require(len(commands) == 28 and sum(cmd["timeout_seconds"] for cmd in commands) == manifest["timeout_sum_seconds"], "Process denominator drift")
    verify(manifest)
    require(shutil.disk_usage(BASE).free >= manifest["minimum_free_bytes"], "Insufficient space")
    OUT.mkdir()
    expected = manifest["source_map"].copy()
    for name in expected:
        target = PROJECT / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / name, target)
    fixture = BASE / "notice-probe.gd.txt"
    shutil.copyfile(fixture, PROJECT / "tests/p02_notice_probe.gd")
    expected["tests/p02_notice_probe.gd"] = manifest["files"][str(fixture)]
    results = []
    active = None
    for command in commands:
        require(not (OUT / "abort").exists(), "External abort")
        require(shutil.disk_usage(BASE).free >= manifest["runtime_free_floor_bytes"], "Runtime free space floor")
        side = command["side"]
        if active != side:
            stage(manifest, side, expected)
            active = side
        command_file = Path(command["command_file"])
        log = command_file.parent
        log.mkdir(parents=True)
        for key in ("APPDATA", "LOCALAPPDATA", "TEMP"):
            Path(command["env"][key]).mkdir()
        if command.get("copy_settings"):
            user = Path(command["env"]["P02_PC_EXPECT_USER"])
            user.mkdir(parents=True)
            shutil.copyfile(manifest["settings"], user / "settings.cfg")
        command_file.write_text(json.dumps(command, ensure_ascii=False), encoding="utf-8")
        try:
            with (log / "supervisor.stdout").open("xb") as stdout, (log / "supervisor.stderr").open("xb") as stderr:
                subprocess.run(
                    [manifest["powershell"], "-NoLogo", "-NoProfile", "-NonInteractive", "-File", str(BASE / "launch.ps1"),
                     "-CommandFile", str(command_file), "-SourceSha", manifest["files"][str(BASE / "P02DirectJob.cs")]],
                    cwd=PROJECT, stdout=stdout, stderr=stderr, check=True, timeout=command["timeout_seconds"] + 45,
                )
        finally:
            scene = PROJECT / "scenes/WorldMap.tscn"
            held = scene.with_suffix(".tscn.p02-held")
            if not scene.exists() and held.is_file() and sha(held) == expected["scenes/WorldMap.tscn"]:
                held.rename(scene)
                (log / "recovered-map.txt").write_text("Supervisor restored verified fixture bytes after abnormal termination.\n", encoding="utf-8")
        require(not (log / "recovered-map.txt").exists(), "Fixture did not restore scene")
        verify_project(expected)
        results.append(assess(command, log))
        (OUT / "results.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    verify(manifest)

if __name__ == "__main__":
    main()
