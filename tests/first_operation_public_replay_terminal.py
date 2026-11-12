"""Check public Atlas replay rejection after asynchronous terminal verification."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True
from first_operation_public_replay_guard import SLOT_SHA, hashes, sha


PROJECT = Path(__file__).resolve().parents[1]
SCRIPT = "tests/first_operation_public_replay_terminal.gd"
ORIGINAL = "approved-original.pcopreplay"
MUTANT = "wrong-settlement.pcopreplay"
EXPORT_SHA = "39bd5ef52f230a4b46b62f812adaca1a096d1a249bd88183437b286630714f04"
WRONG_REASON = "p02_wrong_terminal_reason"


def mutate(source: bytes) -> tuple[bytes, dict]:
    envelope = json.loads(source)
    original_body = envelope["body"]
    parsed = json.loads(original_body)
    expected = parsed["expected_settlement"]
    old = expected["reason"]
    pattern = '"reason":' + json.dumps(old)
    if (parsed["max_ticks"] != 2 or original_body.count(pattern) != 1
            or envelope["sha256"] != sha(original_body.encode("utf-8"))):
        raise ValueError("input is not the reviewed two-tick terminal witness")
    mutant_body = original_body.replace(pattern, '"reason":' + json.dumps(WRONG_REASON))
    body_sha = sha(mutant_body.encode("utf-8"))
    if json.loads(mutant_body) != parsed | {"expected_settlement": expected | {"reason": WRONG_REASON}}:
        raise ValueError("not a single-field terminal reason change")
    mutant = envelope | {"body": mutant_body, "sha256": body_sha}
    raw = json.dumps(mutant, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return raw, {"original_reason": old, "mutated_reason": WRONG_REASON,
                 "original_body_sha256": envelope["sha256"], "mutated_body_sha256": body_sha,
                 "rules_digest": envelope["rules_digest"], "terminal_tick": 2,
                 "terminal_id": expected["id"]}


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
        parser.error("fixture must be the reviewed two-tick approved witness and saved generations")
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
    passed = (status == 0 and not diagnostics and markers == [marker] and len(checks) == 24
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
