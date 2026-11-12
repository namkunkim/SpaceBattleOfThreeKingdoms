"""Compare approved Red Cliffs v1's public host, headless CLI, and replay CLI.

Run on Windows from an imported worktree with the native dependency prepared:
    python tests/first_operation_consumer_parity.py --engine GODOT_EXE --evidence NEW_DIRECTORY
    Add --c0-only to compare the complete C0 state through the shared CLI bootstrap.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

PROJECT = Path(__file__).resolve().parents[1]
HOST_SCRIPT = PROJECT / "tests/first_operation_consumer_host.gd"
CLI_SCRIPT = "res://tests/autoresolve.gd"
USER_DIRECTORY = Path("APPDATA/Godot/app_userdata/SpaceBattleOfThreeKingdoms")
TIMEOUT_SECONDS = 180


def file_sha(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def result_sha(value: object) -> str:
    canonical = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def load_object(path: Path) -> dict:
    with path.open(encoding="utf-8") as stream:
        value = json.load(stream)
    if not isinstance(value, dict):
        raise ValueError(f"expected a JSON object in {path}")
    return value


def run_phase(engine: Path, evidence: Path, phase: str, script: str, arguments: list[str]) -> dict:
    profile = evidence / phase
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA", "TEMP", "TMP"):
        path = profile / key
        path.mkdir(parents=True)
        env[key] = str(path)
    env["SBTK_P02_PARITY_PROFILE"] = env["APPDATA"]
    env["SBTK_SAFE_INSETS"] = "0,0,0"
    log = profile / "engine.log"
    stdout = profile / "stdout.log"
    command = [engine, "--headless", "--fixed-fps", "60", "--path", PROJECT,
               "--log-file", log, "--script", script, "--", *arguments]
    with stdout.open("wb") as stream, subprocess.Popen(
        command, cwd=PROJECT, env=env, stdout=stream, stderr=subprocess.STDOUT,
        creationflags=subprocess.CREATE_NO_WINDOW,
    ) as process:
        try:
            exit_code = process.wait(timeout=TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            exit_code = None
    lines = log.read_text(encoding="utf-8", errors="replace").splitlines() if log.is_file() else []
    console = stdout.read_text(encoding="utf-8", errors="replace").splitlines()
    diagnostics = sorted({line for line in lines + console if re.search(r"\b(?:ERROR|WARNING):", line)})
    checks = [line for line in lines if line.startswith("P02_PARITY_CHECK ")]
    if phase == "host":
        prefix = "P02_PARITY_RESULT "
        expected = f"{prefix}checks={len(checks)} failures=0 pid={process.pid}"
        markers_ok = (len(checks) > 2 and all(line.startswith("P02_PARITY_CHECK true ") for line in checks)
                      and [line for line in lines if line.startswith(prefix)] == [expected])
    else:
        markers_ok = sum(line.startswith("OPERATION_HEADLESS_PASS ") for line in lines) == 1
    return {
        "phase": phase, "pid": process.pid, "exit": exit_code,
        "diagnostics": diagnostics, "host_checks": len(checks),
        "engine_log_sha256": file_sha(log) if log.is_file() else None,
        "stdout_sha256": file_sha(stdout),
        "pass": exit_code == 0 and not diagnostics and markers_ok,
    }


def compare(host: dict, result: dict, executor: str, bundle_sha: str) -> dict[str, bool]:
    metadata = result["meta"].copy()
    checks = {
        "executor": metadata.pop("executor", None) == executor,
        "exact_bundle_bytes": metadata.pop("input_file_sha256", None) == bundle_sha,
        "all_initial_metadata": metadata == host["meta"],
        "no_blocked_ticks": result["blocked_ticks"] == 0,
    }
    checks.update({field: host[field] == result[field]
                   for field in ("summary", "projection", "events", "event_count")})
    return checks


def compare_initial(c0_path: Path) -> dict:
    frames = load_object(c0_path)
    host = frames["host"]
    checks = {phase: {part: frames[phase][part] == host[part] for part in ("frame", "checkpoint")}
              for phase in ("headless", "replay")}
    return {
        "checks": checks,
        "initial_output_sha256": file_sha(c0_path),
        "initial_frame_sha256": result_sha(host["frame"]),
        "initial_checkpoint_sha256": result_sha(host["checkpoint"]),
        "operation_id": host["checkpoint"]["operation_id"],
        "state_digest": host["checkpoint"]["state_digest"],
        "pass": all(check for phase_checks in checks.values() for check in phase_checks.values()),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", required=True, type=Path)
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--c0-only", action="store_true")
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("requires the Windows product host")
    engine = args.engine.resolve(strict=True)
    evidence = args.evidence.resolve()
    evidence.mkdir()
    proof = {
        "mode": "c0-bootstrap" if args.c0_only else "terminal-cli",
        "head": subprocess.check_output(
            ["git", "-c", f"safe.directory={PROJECT.as_posix()}", "-C", PROJECT, "rev-parse", "HEAD"],
            text=True,
        ).strip(),
        "engine": str(engine),
        "engine_sha256": file_sha(engine),
        "test_sha256": file_sha(HOST_SCRIPT),
        "runner_sha256": file_sha(Path(__file__)),
        "phases": [],
    }
    try:
        host_args = ["c0"] if args.c0_only else []
        host_phase = run_phase(engine, evidence, "host", f"res://{HOST_SCRIPT.relative_to(PROJECT).as_posix()}", host_args)
        proof["phases"].append(host_phase)
        if not host_phase["pass"]:
            raise RuntimeError("public host phase failed")
        host_directory = evidence / "host" / USER_DIRECTORY
        if args.c0_only:
            proof.update(compare_initial(host_directory / "c0-result.json"))
        else:
            host_file = host_directory / "host-result.json"
            replay_file = host_directory / "approved-host.pcopreplay"
            bundle = host_directory / "approved-bundle.json"
            bundle_sha = file_sha(bundle)
            proof.update({"host_output_sha256": file_sha(host_file), "host_export_sha256": file_sha(replay_file),
                          "input_bundle_sha256": bundle_sha})
            outputs = {phase: evidence / f"{phase}-result.json" for phase in ("headless", "replay")}
            options = {"headless": "--first-operation-input", "replay": "--first-operation-replay"}
            with ThreadPoolExecutor(max_workers=2) as pool:
                futures = [pool.submit(run_phase, engine, evidence, phase, CLI_SCRIPT,
                                       [option, str(bundle), "--out", str(outputs[phase])])
                           for phase, option in options.items()]
                proof["phases"].extend(future.result() for future in futures)
            if not all(phase["pass"] for phase in proof["phases"]):
                raise RuntimeError("one or more CLI phases failed")
            host = load_object(host_file)
            checks = {phase: compare(host, load_object(path), f"first_operation_{phase}", bundle_sha)
                      for phase, path in outputs.items()}
            proof.update({
                "checks": checks,
                "bundle_unchanged": file_sha(bundle) == bundle_sha,
                "terminal": host["summary"],
                "events": host["event_count"],
                "source_digest": host["meta"]["source_digest"],
                "effective_digest": host["meta"]["effective_digest"],
                "terminal_projection_sha256": result_sha(host["projection"]),
                "ordered_event_sha256": result_sha(host["events"]),
                "cli_output_sha256": {phase: file_sha(path) for phase, path in outputs.items()},
            })
            proof["pass"] = proof["bundle_unchanged"] and all(
                check for phase_checks in checks.values() for check in phase_checks.values()
            )
    except (OSError, ValueError, RuntimeError, KeyError) as exc:
        proof["error"] = str(exc)
        proof["pass"] = False
    (evidence / "RESULT.json").write_text(json.dumps(proof, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(proof, ensure_ascii=False, indent=2))
    return 0 if proof["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
