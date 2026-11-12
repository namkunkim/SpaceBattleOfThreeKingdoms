"""Check the public Windows Atlas replay authority gate without replaying the long export."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


PROJECT = Path(__file__).resolve().parents[1]
SCRIPT = "tests/first_operation_public_replay_guard.gd"
ORIGINAL = "approved-original.pcopreplay"
MUTANT = "unknown-rules.pcopreplay"
EXPORT_SHA = "be1fe807e61c79cb8e31951c91992e95d34a9b356c48377aced7a6f370810d67"
SLOT_SHA = {
    "pc-first-operation-product-v1.save": "2d57a35af2726189947afda8ffac6ad01d98878142a8c9742cd0b6b799b2a503",
    "pc-first-operation-product-v1.save.previous": "3d371f92d21b9a954bd6b982e2dfa094c2a9b365052326c5de4a01ab272b6106",
}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def hashes(directory: Path, names: dict[str, str]) -> dict[str, str]:
    return {name: sha((directory / name).read_bytes()) for name in names}


def mutate(source: bytes) -> tuple[bytes, dict]:
    envelope = json.loads(source)
    old_rules = envelope["rules_digest"]
    new_rules = ("0" if old_rules[0] != "0" else "1") + old_rules[1:]
    old_bytes, new_bytes = old_rules.encode("ascii"), new_rules.encode("ascii")
    if source.count(old_bytes) != 1 or len(old_bytes) != 64:
        raise ValueError("rules digest is not one exact 64-byte occurrence")
    result = source.replace(old_bytes, new_bytes)
    changed = json.loads(result)
    body_sha = sha(envelope["body"].encode("utf-8"))
    if (changed != envelope | {"rules_digest": new_rules} or body_sha != changed["sha256"]
            or len(result) != len(source) or sum(a != b for a, b in zip(result, source)) != 1):
        raise ValueError("mutated replay is not an exact one-byte authority difference")
    return result, {"original_rules_digest": old_rules, "mutated_rules_digest": new_rules,
                    "body_sha256": body_sha, "changed_bytes": 1}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", required=True, type=Path)
    parser.add_argument("--fixture", required=True, type=Path)
    parser.add_argument("--replay", required=True, type=Path)
    parser.add_argument("--evidence", required=True, type=Path)
    options = parser.parse_args()
    if os.name != "nt":
        parser.error("requires Windows")
    engine = options.engine.resolve(strict=True)
    fixture = options.fixture.resolve(strict=True)
    replay = options.replay.resolve(strict=True)
    original = replay.read_bytes()
    if hashes(fixture, SLOT_SHA) != SLOT_SHA or sha(original) != EXPORT_SHA:
        parser.error("fixture must be the reviewed actual approved export and saved generations")
    mutant, mutation = mutate(original)
    evidence = options.evidence.resolve()
    evidence.mkdir()
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA", "USERPROFILE", "TEMP", "TMP"):
        folder = evidence / "profile" / key
        folder.mkdir(parents=True)
        env[key] = str(folder)
    env["SBTK_P02_REPLAY_GUARD_PROFILE"] = env["APPDATA"]
    env["SBTK_SAFE_INSETS"] = "0,0,0"
    user = Path(env["APPDATA"]) / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    user.mkdir(parents=True)
    for name in SLOT_SHA:
        shutil.copyfile(fixture / name, user / name)
    (user / ORIGINAL).write_bytes(original)
    (user / MUTANT).write_bytes(mutant)
    expected = SLOT_SHA | {ORIGINAL: EXPORT_SHA, MUTANT: sha(mutant)}

    log = evidence / "engine.log"
    stdout = evidence / "stdout.log"
    cmd = [str(engine), "--headless", "--fixed-fps", "60", "--resolution", "1600x900", "--path", str(PROJECT),
           "--log-file", str(log), "--script", "res://" + SCRIPT]
    with stdout.open("xb") as stream, subprocess.Popen(
        cmd, cwd=PROJECT, env=env, stdout=stream, stderr=subprocess.STDOUT,
        creationflags=subprocess.CREATE_NO_WINDOW,
    ) as child:
        try:
            status = child.wait(timeout=120)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
            status = None
    logs = log.read_text(encoding="utf-8", errors="replace") if log.is_file() else ""
    diagnostics = sorted({line for line in (logs + "\n" + stdout.read_text(encoding="utf-8", errors="replace")).splitlines()
                          if re.search(r"\b(?:ERROR|WARNING):", line)})
    checks = [line for line in logs.splitlines() if line.startswith("P02_REPLAY_GUARD_CHECK ")]
    markers = [line for line in logs.splitlines() if line.startswith("P02_REPLAY_GUARD_RESULT ")]
    marker = f"P02_REPLAY_GUARD_RESULT checks={len(checks)} failures=0 pid={child.pid}"
    final = hashes(user, expected)
    source_unchanged = hashes(fixture, SLOT_SHA) == SLOT_SHA and sha(replay.read_bytes()) == EXPORT_SHA
    passed = (status == 0 and not diagnostics and markers == [marker] and len(checks) == 17
              and all(line.startswith("P02_REPLAY_GUARD_CHECK true ") for line in checks)
              and final == expected and source_unchanged)
    result = {
        "head": subprocess.check_output(["git", "-c", f"safe.directory={PROJECT.as_posix()}", "-C",
                                         PROJECT, "rev-parse", "HEAD"], text=True).strip(),
        "engine_sha256": sha(engine.read_bytes()), "command": cmd,
        "test_sha256": sha((PROJECT / SCRIPT).read_bytes()), "runner_sha256": sha(Path(__file__).read_bytes()),
        "fixture": str(fixture), "original_replay": str(replay), "pre_sha256": expected,
        "final_sha256": final, "source_fixture_unchanged": source_unchanged, "mutation": mutation,
        "pid": child.pid, "exit": status, "checks": len(checks), "diagnostics": diagnostics,
        "engine_log_sha256": sha(log.read_bytes()) if log.is_file() else None,
        "stdout_sha256": sha(stdout.read_bytes()), "pass": passed,
    }
    (evidence / "RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
