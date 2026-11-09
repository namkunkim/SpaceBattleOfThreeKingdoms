from pathlib import Path
import json, re, subprocess, sys
from gate import audit, dump, engine, evidence, root, runner, owner, runtime, sha

def baseline_for(label):
    return evidence / ("baseline-world" if label == "world_link" else "baseline-regressions")

def diagnostic_lines(path):
    return path.read_bytes().splitlines()

def existing_leaks(lines):
    return len(lines) == 4 and bool(
        re.fullmatch(rb"WARNING: \d+ ObjectDB instances were leaked at exit \(run with `--verbose` for details\)\.", lines[0])
        and lines[1].strip() == b"at: cleanup (core/object/object.cpp:2536)"
        and re.fullmatch(rb"ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.", lines[2])
        and lines[3].strip() == b"at: clear (core/io/resource.cpp:822)")

def records(stage):
    return {r["label"]: r for r in json.loads((evidence / stage / "results.json").read_bytes())["cases"]}

def main(attempt, viewer_attempt):
    runtime()
    proof = evidence / ("proof-" + viewer_attempt + "-verified")
    proof.mkdir()
    before, after, viewer = records("before"), records(attempt), records(viewer_attempt)
    after["viewer"] = viewer["viewer"]
    paired = {}
    for label, old in before.items():
        new = after[label]
        paired[label] = old["pass_process"] and new["pass_process"] and all(
            old[k] == new[k] for k in ("exit", "timeout", "diagnostics", "rejects", "output_sha256"))
    regression = {}
    pass_markers = {
        "p02_headless_adapter": b"P02_ADAPTER_PASS", "p02_worker_adapter": b"P02_WORKER_CHECKS",
        "p02_replay_adapter": b"P02_REPLAY_PASS", "detection_rules": b"DETECTION_RULES_PASS",
        "battle_flow": b"BATTLE_FLOW_PASS", "placement": b"PLACEMENT_PASS", "world_link": b"WORLD_LINK_PASS",
        "i01b_active_replace": b"I01B_ACTIVE_REPLACE_PASS",
    }
    for label, marker in pass_markers.items():
        baseline_stage = baseline_for(label)
        old = records(baseline_stage.name)[label]
        old_stderr = (baseline_stage / (label + ".stderr")).read_bytes()
        new_stderr = (evidence / attempt / (label + ".stderr")).read_bytes()
        match = old_stderr == new_stderr
        known_exit_only = existing_leaks(old_stderr.splitlines()) and existing_leaks(new_stderr.splitlines())
        historical = False
        if label == "battle_flow":
            lines = (root / "tmp/i01b-followup-20261028/logs/battle_flow-output.log").read_bytes().splitlines()
            historical = new_stderr.splitlines() == lines[lines.index(b"BATTLE_FLOW_PASS") + 1:]
        stdout = (evidence / attempt / (label + ".stdout")).read_bytes()
        old_stdout = (baseline_stage / (label + ".stdout")).read_bytes()
        new = after[label]
        regression[label] = {"exit": [old["exit"], new["exit"]], "timeout": [old["timeout"], new["timeout"]],
                             "stderr_byte_match": match, "both_only_existing_exit_leaks": known_exit_only, "exact_historical_match": historical,
                             "old_diagnostics": old_stderr.decode(), "new_diagnostics": new_stderr.decode(),
                             "passed": old["pass_process"] and new["pass_process"]
                             and old["diagnostics"] == new["diagnostics"]
                             and marker in old_stdout and marker in stdout
                             and ((match and not new_stderr) or (known_exit_only and (match or historical)))}
    viewer_stdout = (evidence / viewer_attempt / "viewer.stdout").read_bytes()
    rows = re.findall(rb"^VIEWER_ROW (E\d\d) PASS ", viewer_stdout, re.MULTILINE)
    final_marker = re.search(rb"^P02_VIEWER_EVENTS_PASS rows=14 assertions=(\d+)\b", viewer_stdout, re.MULTILINE)
    current = (root / owner).read_bytes()
    original = (evidence / "owner.before.gd.txt").read_bytes()
    hunk = (evidence / "owned-hunk.gd.txt").read_bytes()
    reverse = current.count(hunk) == 1 and current.replace(hunk, b"", 1) == original
    diff = subprocess.run(["git", "diff", "--check"], capture_output=True)
    (proof / "diff-check.stdout").write_bytes(diff.stdout)
    (proof / "diff-check.stderr").write_bytes(diff.stderr)
    before_check = (evidence / "diff-check-before.stdout").read_bytes()
    diff_match = diff.returncode == 2 and diff.stdout.splitlines() == before_check.splitlines()
    hygiene = not any(line.endswith((b" ", b"\t")) for line in (hunk + (root / runner).read_bytes()).splitlines())
    preserved = audit("post-" + viewer_attempt)
    scopes = ([row["path"] for row in preserved["changes"]] == [owner] and preserved["new"] == [runner]
              and preserved["branch_head_index_match"])
    counts = {str(i): sum(r["exit"] == i for r in [*before.values(), *after.values()]) for i in (0, 1)}
    result = {"base_process_count": len(before) + len(after), "exit_counts": counts,
              "timeouts": sum(r["timeout"] for r in [*before.values(), *after.values()]),
              "paired_cli": paired, "regression": regression, "logical_rows_passed": [s.decode() for s in rows],
              "assertions": int(final_marker[1]) if final_marker else None,
              "owner_reverse_sha_matches": reverse, "original_owner_sha256": sha(evidence / "owner.before.gd.txt"),
              "owner_sha256": sha(root / owner), "runner_sha256": sha(root / runner),
              "whole_diff_check_actual_exit": diff.returncode, "whole_diff_check_baseline_match": diff_match,
              "owned_hunk_trailing_whitespace_clean": hygiene, "scoped_drift": scopes}
    result["required_freezes_stable"] = all(not json.loads((evidence / stage / "results.json").read_bytes())["freeze_changes"]
                                           for stage in {"before", "baseline-world", attempt, viewer_attempt})
    result["passed"] = all((result["required_freezes_stable"], result["base_process_count"] == 17, all(paired.values()),
                            all(r["passed"] for r in regression.values()), after["viewer"]["pass_process"],
                            rows == [f"E{i:02}".encode() for i in range(1, 15)], final_marker,
                            reverse, diff_match, hygiene, scopes))
    dump(proof / "verdict.json", result)
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result["passed"] else 1

if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))

