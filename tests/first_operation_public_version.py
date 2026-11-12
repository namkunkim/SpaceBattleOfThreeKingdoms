"""Run the public P03 version gate against real generation B and its retained A."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


PROJECT = Path(__file__).resolve().parents[1]
SCRIPT = "res://tests/first_operation_public_version.gd"
PRIMARY = "pc-first-operation-product-v1.save"
PREVIOUS = PRIMARY + ".previous"
ORACLE = "p03-public-cursor-b"
FIXTURE_SHA = {
    PRIMARY: "2d57a35af2726189947afda8ffac6ad01d98878142a8c9742cd0b6b799b2a503",
    PREVIOUS: "3d371f92d21b9a954bd6b982e2dfa094c2a9b365052326c5de4a01ab272b6106",
    ORACLE: "687b621e4f4e78ee44f02960425840cc4f61cb18e1258c5532f364257df3bba4",
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fixture_hashes(path: Path) -> dict[str, str]:
    return {name: digest((path / name).read_bytes()) for name in FIXTURE_SHA}


def mutate_body(envelope: dict, key: str, replacement: str) -> dict:
    body = envelope["body"]
    original = json.loads(body)
    pattern = r'("' + key + r'"\s*:\s*)' + re.escape(json.dumps(original[key]))
    mutated, replacements = re.subn(pattern, lambda match: match[1] + json.dumps(replacement), body)
    if replacements != 1 or json.loads(mutated) != original | {key: replacement}:
        raise ValueError(f"not a one-field mutation: {key}")
    return envelope | {"body": mutated, "sha256": digest(mutated.encode("utf-8"))}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", required=True, type=Path)
    parser.add_argument("--fixture", required=True, type=Path)
    parser.add_argument("--evidence", required=True, type=Path)
    options = parser.parse_args()
    if os.name != "nt":
        parser.error("requires Windows")
    engine = options.engine.resolve(strict=True)
    fixture = options.fixture.resolve(strict=True)
    evidence = options.evidence.resolve()
    if fixture_hashes(fixture) != FIXTURE_SHA:
        parser.error("input fixture is not the reviewed real generation B")
    evidence.mkdir()
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA", "USERPROFILE", "TEMP", "TMP"):
        folder = evidence / "profile" / key
        folder.mkdir(parents=True)
        env[key] = str(folder)
    env["SBTK_P03_CURSOR_PROFILE"] = env["APPDATA"]
    env["SBTK_SAFE_INSETS"] = "0,0,0"
    user = Path(env["APPDATA"]) / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    user.mkdir(parents=True)
    for name in FIXTURE_SHA:
        shutil.copyfile(fixture / name, user / name)
    shutil.copyfile(user / PRIMARY, user / "p03-version-original")

    original = json.loads((user / PRIMARY).read_bytes())
    if original["version"] != 1 or digest(original["body"].encode("utf-8")) != original["sha256"]:
        raise ValueError("original checkpoint envelope is invalid")
    variants = {
        "envelope-version": original | {"version": 2},
        "checkpoint-format": mutate_body(original, "format", "pc-first-operation-internal-replay/2"),
        "rules-digest": mutate_body(original, "rules_digest", "f" * 64),
    }
    mutations = {}
    for label, envelope in variants.items():
        body_sha = digest(envelope["body"].encode("utf-8"))
        if body_sha != envelope["sha256"]:
            raise ValueError(f"invalid enclosing checksum: {label}")
        raw = json.dumps(envelope, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        (user / f"p03-version-{label}").write_bytes(raw)
        mutations[label] = {"sha256": digest(raw), "body_sha256": body_sha, "version": envelope["version"]}

    log = evidence / "engine.log"
    stdout = evidence / "stdout.log"
    cmd = [str(engine), "--headless", "--fixed-fps", "60", "--path", str(PROJECT),
           "--log-file", str(log), "--script", SCRIPT, "--", "version-boundaries"]
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
    checks = [line for line in logs.splitlines() if line.startswith("P03_PUBLIC_CURSOR_CHECK ")]
    markers = [line for line in logs.splitlines() if line.startswith("P03_PUBLIC_CURSOR_RESULT ")]
    marker = f"P03_PUBLIC_CURSOR_RESULT phase=version-boundaries checks={len(checks)} failures=0 pid={child.pid}"
    final = fixture_hashes(user)
    original_unchanged = fixture_hashes(fixture) == FIXTURE_SHA
    passed = (status == 0 and not diagnostics and markers == [marker] and len(checks) == 33
              and all(line.startswith("P03_PUBLIC_CURSOR_CHECK true ") for line in checks)
              and final == FIXTURE_SHA and original_unchanged)
    result = {
        "head": subprocess.check_output(["git", "-c", f"safe.directory={PROJECT.as_posix()}", "-C",
                                         PROJECT, "rev-parse", "HEAD"], text=True).strip(),
        "engine_sha256": digest(engine.read_bytes()), "command": cmd,
        "test_sha256": digest((PROJECT / "tests/first_operation_public_version.gd").read_bytes()),
        "base_test_sha256": digest((PROJECT / "tests/first_operation_public_cursor.gd").read_bytes()),
        "runner_sha256": digest(Path(__file__).read_bytes()),
        "fixture": str(fixture), "fixture_sha256": FIXTURE_SHA, "final_sha256": final,
        "source_fixture_unchanged": original_unchanged, "mutations": mutations,
        "pid": child.pid, "exit": status, "checks": len(checks), "diagnostics": diagnostics,
        "engine_log_sha256": digest(log.read_bytes()) if log.is_file() else None,
        "stdout_sha256": digest(stdout.read_bytes()), "pass": passed,
    }
    (evidence / "RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
