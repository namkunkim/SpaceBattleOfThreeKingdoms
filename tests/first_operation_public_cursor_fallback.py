"""Verify public cursor recovery with a real previous generation on Windows.

Use an imported worktree and a fixture directory made by the existing public
cursor test's seed/rotate phases. It must contain both slots and its B oracle.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

PROJECT = Path(__file__).resolve().parents[1]
SCRIPT = PROJECT / "tests/first_operation_public_cursor_fallback.gd"
BASE_SCRIPT = PROJECT / "tests/first_operation_public_cursor.gd"
PRIMARY = "pc-first-operation-product-v1.save"
PREVIOUS = PRIMARY + ".previous"
PENDING = PRIMARY + ".pending-fallback-test"
ORACLE = "p03-public-cursor-b"
FIXTURES = (PRIMARY, PREVIOUS, ORACLE)


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def hashes(directory: Path, names: tuple[str, ...]) -> dict[str, str]:
    return {name: sha256(directory / name) for name in names}


def run_phase(engine: Path, evidence: Path, env: dict[str, str], phase: str) -> dict:
    log = evidence / f"{phase}.engine.log"
    stdout = evidence / f"{phase}.stdout.log"
    command = [engine, "--headless", "--fixed-fps", "60", "--path", PROJECT,
               "--log-file", log, "--script", f"res://{SCRIPT.relative_to(PROJECT).as_posix()}", "--", phase]
    with stdout.open("wb") as stream, subprocess.Popen(
        command, cwd=PROJECT, env=env, stdout=stream, stderr=subprocess.STDOUT,
        creationflags=subprocess.CREATE_NO_WINDOW,
    ) as process:
        try:
            exit_code = process.wait(timeout=120)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            exit_code = None
    lines = log.read_text(encoding="utf-8", errors="replace").splitlines() if log.is_file() else []
    console = stdout.read_text(encoding="utf-8", errors="replace").splitlines()
    diagnostics = sorted({line for line in lines + console if re.search(r"\b(?:ERROR|WARNING):", line)})
    checks = [line for line in lines if line.startswith("P03_PUBLIC_CURSOR_CHECK ")]
    markers = [line for line in lines if line.startswith("P03_PUBLIC_CURSOR_RESULT ")]
    expected = f"P03_PUBLIC_CURSOR_RESULT phase={phase} checks={len(checks)} failures=0 pid={process.pid}"
    passed = (exit_code == 0 and not diagnostics and markers == [expected]
              and len(checks) > 2 and all(line.startswith("P03_PUBLIC_CURSOR_CHECK true ") for line in checks))
    return {
        "phase": phase, "pid": process.pid, "exit": exit_code, "checks": len(checks),
        "diagnostics": diagnostics, "engine_log_sha256": sha256(log) if log.is_file() else None,
        "stdout_sha256": sha256(stdout), "pass": passed,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", required=True, type=Path)
    parser.add_argument("--fixture", required=True, type=Path)
    parser.add_argument("--evidence", required=True, type=Path)
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("requires the Windows product host")
    engine = args.engine.resolve(strict=True)
    fixture = args.fixture.resolve(strict=True)
    evidence = args.evidence.resolve()
    evidence.mkdir()
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA", "TEMP", "TMP"):
        path = evidence / "profile" / key
        path.mkdir(parents=True)
        env[key] = str(path)
    env["SBTK_P03_CURSOR_PROFILE"] = env["APPDATA"]
    env["SBTK_SAFE_INSETS"] = "0,0,0"
    user_directory = Path(env["APPDATA"]) / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
    user_directory.mkdir(parents=True)
    proof = {
        "head": subprocess.check_output(
            ["git", "-c", f"safe.directory={PROJECT.as_posix()}", "-C", PROJECT, "rev-parse", "HEAD"],
            text=True,
        ).strip(),
        "engine": str(engine), "engine_sha256": sha256(engine),
        "test_sha256": sha256(SCRIPT), "base_test_sha256": sha256(BASE_SCRIPT),
        "runner_sha256": sha256(Path(__file__)),
        "fixture_path": str(fixture), "phases": [], "pass": False,
    }
    try:
        original = hashes(fixture, FIXTURES)
        proof["fixture_sha256"] = original
        for name in FIXTURES:
            shutil.copyfile(fixture / name, user_directory / name)
        if hashes(user_directory, FIXTURES) != original:
            raise RuntimeError("isolated fixture copy does not match")
        for phase in ("retain", "recover", "open-repaired"):
            result = run_phase(engine, evidence, env, phase)
            proof["phases"].append(result)
            if not result["pass"]:
                raise RuntimeError(f"{phase} phase failed")
            if phase == "retain":
                rotated = hashes(user_directory, (PRIMARY, PREVIOUS))
                if rotated[PREVIOUS] != original[PRIMARY] or rotated[PRIMARY] == original[PRIMARY]:
                    raise RuntimeError("rotation did not retain B and publish a distinct C")
                (user_directory / PRIMARY).rename(user_directory / PENDING)
                proof["synthetic_gap"] = hashes(user_directory, (PREVIOUS, PENDING))
                if (user_directory / PRIMARY).exists() or proof["synthetic_gap"][PENDING] != rotated[PRIMARY]:
                    raise RuntimeError("missing-primary setup does not preserve the rotated bytes")
        final = hashes(user_directory, (PRIMARY, PREVIOUS, PENDING))
        proof["final_sha256"] = final
        if any(final[name] != value for name, value in proof["synthetic_gap"].items()):
            raise RuntimeError("recovery modified retained or unpublished bytes")
        if final[PRIMARY] in proof["synthetic_gap"].values():
            raise RuntimeError("recovery did not publish a distinct primary")
        proof["pass"] = True
    except (OSError, RuntimeError) as exc:
        proof["error"] = str(exc)
    if "fixture_sha256" in proof:
        try:
            proof["fixture_unchanged"] = hashes(fixture, FIXTURES) == proof["fixture_sha256"]
        except OSError:
            proof["fixture_unchanged"] = False
        proof["pass"] = proof["pass"] and proof["fixture_unchanged"]
    (evidence / "RESULT.json").write_text(json.dumps(proof, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(proof, ensure_ascii=False, indent=2))
    return 0 if proof["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
