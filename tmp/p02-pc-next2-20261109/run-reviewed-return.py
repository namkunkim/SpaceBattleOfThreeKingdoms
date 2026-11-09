"""Stage and execute only an exact, externally approved attempt."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
PREVIOUS = BASE.parent / "p02-pc-next-20261109"
LINK = "scripts/world_link.gd"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def require(ok, reason):
    if not ok:
        raise RuntimeError(reason)


def git(*args):
    return subprocess.check_output(["git", "--no-optional-locks", *args], cwd=ROOT, text=True).strip()


def verify(manifest):
    baseline = manifest["baseline"]
    require(git("branch", "--show-current") == baseline["branch"], "Branch drift")
    require(git("rev-parse", "HEAD") == baseline["head"] and not git("diff", "--cached", "--name-only"), "HEAD or staged drift")
    require(sha(ROOT / git("rev-parse", "--git-path", "index")) == baseline["index_sha256_after"], "Index drift")
    for name, digest in manifest["files"].items():
        require(sha(Path(name)) == digest, name)
    for name, digest in manifest["source_map"].items():
        require(sha(ROOT / name) == digest, name)
    for row in baseline["files"]:
        require(sha(ROOT / row["path"]) == row["sha256"], row["path"])


def check_metadata(project):
    require(not (project / "scenes/WorldMap.tscn.p02-held").exists(), "Unexpected held scene")
    require(not any((project / name).exists() for name in ("override.cfg", "project.binary")), "Project override")
    for path in project.rglob("*"):
        if path.is_file() and path.suffix in (".import", ".remap"):
            require(b"worldmap.tscn" not in path.read_bytes().lower(), str(path))


def assess(command, path):
    log = (path / "engine.log").read_text(encoding="utf-8", errors="replace").splitlines()
    os_log = Path(command["os_log"]).read_text(encoding="utf-8").splitlines()
    events = [line.split("\t")[2:] for line in os_log]
    require(["exit", str(command["expected_engine_exit"])] in events and ["cleanup", "0"] in events, str(path))
    require(["root_cleanup", "True", "True", "0", str(command["expected_engine_exit"]), "True"] in events, str(path))
    require(not any(line.startswith("SCRIPT ERROR:") for line in log), str(path))
    diagnostics = Counter(line for line in log if line.startswith(("ERROR:", "WARNING:")))
    termination = [line for line in diagnostics if "leaked at exit" in line or "resources still in use at exit" in line]
    for line in termination:
        require(diagnostics.pop(line) == 1, line)
    if "expected_assertions" in command:
        identifiers = command["expected_assertions"]
        count = len(identifiers)
        rows = [line for line in log if line.startswith("P02_RETURN_ASSERT ")]
        require(rows == [f"P02_RETURN_ASSERT {key} PASS" for key in identifiers], str(path))
        require(log.count(f"P02_RETURN_DONE {count} 0") == 1, str(path))
        expected = +Counter(command["diagnostics"])
    else:
        expected = Counter()
        name = command["name"]
        if name == "world-clean":
            expected["ERROR: TEST_FAIL 천하에서 오면 브리핑부터 (prologue)"] = 1
        marker = {"world-clean": "WORLD_LINK_FAIL 1", "world-returning": "WORLD_LINK_PASS", "outbound-round-trip": "PC_DIRECT_ROUND_TRIP_DONE 0"}.get(name)
        require(marker is None or log.count(marker) == 1, str(path))
    require(diagnostics == expected, f"{path}: actual {diagnostics}, expected {expected}")
    return {"lane": str(path), "diagnostics": dict(diagnostics), "termination": termination}


def main():
    reviewed = BASE / "EXECUTION-REVIEW-ONLY-V3.json"
    approval = BASE / "EXECUTION-INDEPENDENT-APPROVED.json"
    require(len(sys.argv) == 2 and Path(sys.argv[1]).resolve() == approval, "Independent approval file required")
    require(read(approval) == {"status": "INDEPENDENT_APPROVED", "review_only_sha256": sha(reviewed)}, "Approval does not match manifest")
    manifest = read(reviewed)
    verify(manifest)
    commands = manifest["commands"]
    require(len(commands) == manifest["expected_command_count"] and sum(c["timeout_seconds"] for c in commands) == manifest["expected_timeout_sum_seconds"], "Process denominator drift")
    output = Path(manifest["attempt_root"])
    require(output == BASE / "attempt-01" and output.resolve() == output, "Attempt path drift")
    output.mkdir()
    for side in ("before", "after"):
        project = output / side / "project"
        for name in manifest["source_map"]:
            target = project / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        if side == "after":
            shutil.copyfile(BASE / "world_link.candidate.gd.txt", project / LINK)
        shutil.copyfile(BASE / "return-probe.gd.txt", project / "tests/p02_return_probe.gd")
        shutil.copyfile(PREVIOUS / "world-link-prepared-v6.gd.txt", project / "tests/p02_previous_roundtrip.gd")
        expected = dict(manifest["source_map"])
        if side == "after":
            expected[LINK] = manifest["files"][str(BASE / "world_link.candidate.gd.txt")]
        expected["tests/p02_return_probe.gd"] = sha(BASE / "return-probe.gd.txt")
        expected["tests/p02_previous_roundtrip.gd"] = sha(PREVIOUS / "world-link-prepared-v6.gd.txt")
        require({p.relative_to(project).as_posix(): sha(p) for p in project.rglob("*") if p.is_file()} == expected, str(project))
        check_metadata(project)
    results = []
    launcher = PREVIOUS / "launch-direct.ps1"
    supervisor_sha = manifest["files"][str(PREVIOUS / "P02DirectJob.cs")]
    for command in commands:
        require(not (output / "abort").exists(), "External abort")
        path = Path(command["command_file"]).parent
        path.mkdir()
        for key in ("APPDATA", "LOCALAPPDATA", "TEMP"):
            Path(command["env"][key]).mkdir()
        if command["name"] in ("world-returning", "outbound-round-trip"):
            dest = Path(command["env"]["P02_PC_EXPECT_USER"]) / "settings.cfg"
            dest.parent.mkdir(parents=True)
            shutil.copyfile(manifest["returning_settings"], dest)
        command_file = Path(command["command_file"])
        command_file.write_text(json.dumps(command, ensure_ascii=False), encoding="utf-8")
        try:
            with (path / "supervisor.stdout").open("xb") as stdout, (path / "supervisor.stderr").open("xb") as stderr:
                subprocess.run(
                    [manifest["powershell"], "-NoLogo", "-NoProfile", "-NonInteractive", "-File", str(launcher),
                     "-CommandFile", str(command_file), "-SourceSha", supervisor_sha],
                    cwd=command["cwd"], stdout=stdout, stderr=stderr, check=True, timeout=command["timeout_seconds"] + 45,
                )
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError) as error:
            project = Path(command["cwd"])
            (path / "supervisor-failure.json").write_text(json.dumps({
                "kind": type(error).__name__,
                "worldmap_exists": (project / "scenes/WorldMap.tscn").is_file(),
                "held_scene_exists": (project / "scenes/WorldMap.tscn.p02-held").is_file(),
            }), encoding="utf-8")
            raise
        results.append(assess(command, path))
        check_metadata(Path(command["cwd"]))
        (output / "results.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    verify(manifest)


if __name__ == "__main__":
    main()
