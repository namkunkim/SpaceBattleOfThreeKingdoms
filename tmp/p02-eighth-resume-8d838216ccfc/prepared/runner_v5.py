"""V3 read-only preflight and blocked execution harness."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

sys.dont_write_bytecode = True
from assessment_v3 import compare_assertions, compare_raw, read_checks, validate_assertions
from owned_job_v3 import run
from world_product_v5 import assess as assess_world_product
from runner_v2 import HERE, ROOT, RUNS, artifacts, compare_workspace, read, sha, stage, validate_file, within, write

def git(*argv):
    return subprocess.check_output(["git","--no-optional-locks",*argv], cwd=ROOT,
                                   env=os.environ | {"GIT_OPTIONAL_LOCKS":"0"}, timeout=30)

def metadata(path):
    return {"bytes":path.stat().st_size,"sha256":sha(path)}

def git_identity():
    index = Path(os.fsdecode(git("rev-parse","--path-format=absolute","--git-path","index").rstrip(b"\r\n")))
    return {"branch":git("symbolic-ref","--short","HEAD").decode().strip(),
            "head":git("rev-parse","HEAD").decode().strip(),
            "index":metadata(index),
            "stage_sha256":hashlib.sha256(git("ls-files","--stage","-z")).hexdigest(),
            "staged_diff_raw_hex":git("diff","--cached","--binary","--no-ext-diff").hex()}

def workspace_inventory(frozen, allow_prepared=True):
    # Record P03 changes as time samples, without inferring who changed any path.
    p03 = {}
    unexpected = []
    def names(data):
        return {part.decode("utf-8") for part in data.split(b"\0") if part}
    tracked = names(git("ls-files","-z"))
    untracked = names(git("ls-files","--others","--exclude-standard","-z"))
    current = tracked | untracked
    prepared = HERE.relative_to(ROOT).as_posix() + "/"
    for rel in sorted(current | frozen.keys()):
        prior = frozen.get(rel)
        if allow_prepared and rel.startswith(prepared) and not prior and rel not in tracked:
            continue
        if rel not in current:
            change = {"kind":"removed","previous":prior}
        else:
            p = within(ROOT, ROOT / rel)
            try:
                now = metadata(p)
            except OSError as e:
                now = {"read_error":str(e)}
            kind = "tracked" if rel in tracked else "untracked"
            if prior and now == {k:prior[k] for k in ("bytes","sha256")} and kind == prior["kind"]:
                continue
            change = {"kind":kind,"previous":prior,"current":now}
        if rel.startswith("tmp/p03-"):
            p03[rel] = change
        else:
            unexpected.append((rel,change))
    return {"utc_epoch_ns":time.time_ns(),"p03_observed_differences":p03,"other_differences":unexpected}

def assess_job(job, result):
    errors = []
    if result["interruption"]:
        errors.append(result["interruption"])
    if result["exit"] not in job["expected_exit"]:
        errors.append(f"unexpected exit: {result['exit']}")
    try:
        assertions = read_checks(job, job["expectation"])
        errors.extend(validate_assertions(job["expectation"],assertions,result["exit"],
                                         Path(job["stderr"]).read_text(encoding="utf-8-sig")))
    except (OSError, ValueError, TypeError, KeyError) as e:
        assertions = []
        errors.append(f"could not parse observations: {e}")
    return {"pass":not errors,"errors":errors,"checks":[{"ordinal":i,"id":k,"ok":v} for i,(k,v) in enumerate(assertions,1)]}

def compare_group(group, outcomes):
    missing = [pid for pid in group["processes"] if pid not in outcomes]
    if missing:
        return [f"comparison members not observed: {missing}"]
    if group["kind"] == "typed":
        return compare_raw(group["raw_paths"],group["keys"])
    if group["kind"] == "world-product":
        return assess_world_product(group["raw_paths"],group["cancel"],group["expected_ids"])
    if group["kind"] == "suite":
        first, second = [outcomes[pid] for pid in group["processes"]]
        if first["exit"] != second["exit"]:
            return ["suite exits differ"]
        return compare_assertions(first["assessment"]["checks"],second["assessment"]["checks"])
    return ["comparison requires separate independent evidence"]

def verify_replica(job, manifest, lanes):
    project = within(RUNS,Path(job["cwd"]))
    for rel, meta in lanes[job["lane"]].items():
        override = job["test_only_overlays"].get(rel)
        if override:
            meta = {"bytes":override["after_bytes"],"sha256":override["after_sha256"]}
        validate_file(within(project,project / rel),meta)
    for rel in manifest["supplemental_rel_paths"]:
        source = str(ROOT / rel)
        validate_file(within(project,project / rel),manifest["dependencies"][source])
    if job["probe"]:
        rel = job["exact_argv"][job["exact_argv"].index("--script")+1].removeprefix("res://")
        validate_file(within(project,project / rel),manifest["dependencies"][job["probe"]])

def execute_jobs(manifest, lanes):
    RUNS.mkdir()
    deadline = time.monotonic() + manifest["timing"]["serial_cap_seconds"]
    outcomes = {}
    for job in manifest["jobs"]:
        stop = lambda: (RUNS / "STOP").exists()
        if stop() or time.monotonic() >= deadline:
            break
        project = stage(job,manifest,lanes)
        verify_replica(job,manifest,lanes)
        cap = min(deadline,time.monotonic() + job["timeout_seconds"])
        dest = Path(job["artifact_root"])
        with Path(job["stdout"]).open("xb") as out, Path(job["stderr"]).open("xb") as err:
            result = run(job["exact_argv"],project,os.environ | job["environment_overrides"],out,err,
                         cap,job["kill_wait_seconds"],stop,
                         lambda pid: write(dest / "launch.json",{"owned_broker_pid":pid,"argv":job["exact_argv"]}))
        result["assessment"] = assess_job(job,result)
        result["artifacts"] = artifacts(dest)
        outcomes[job["process_id"]] = result
        write(dest / "result.json",result)
        verify_replica(job,manifest,lanes)
        if result["interruption"] or not result["assessment"]["pass"]:
            break
    comparisons = {}
    for group in manifest["comparison_groups"]:
        try:
            comparisons[group["id"]] = compare_group(group,outcomes)
        except (OSError, ValueError, TypeError, KeyError) as e:
            comparisons[group["id"]] = [f"could not compare observations: {e}"]
    write(RUNS / "comparisons.json",comparisons)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest",type=Path)
    ap.add_argument("--approval",type=Path)
    args = ap.parse_args()
    manifest = read(args.manifest)
    if manifest["status"] != "APPROVED_K6_ONCE" or manifest.get("gates_open"):
        raise SystemExit("Blocked review package. No process started.")
    if not args.approval:
        raise SystemExit("Independent acceptance and orchestration authorization are required.")
    approval = read(args.approval)
    if approval["status"] != "INDEPENDENT_ACCEPT_AND_ORCHESTRATOR_AUTHORIZE" or approval["manifest_sha256"] != sha(args.manifest):
        raise SystemExit("Approval does not match manifest.")
    if RUNS.exists() or manifest["timing"]["serial_cap_seconds"] > 21600:
        raise SystemExit("One-shot directory or finite limit gate failed.")
    if sorted({r for j in manifest["jobs"] for r in j["row_ids"]}) != list(range(1,22)):
        raise SystemExit("21-row denominator is required.")
    if any(j["expectation"]["kind"] == "external-gui" for j in manifest["jobs"]):
        raise SystemExit("GUI provenance and continuous foreground unapproved. No process started.")
    if any(j["expectation"].get("pending_exact_denominator") for j in manifest["jobs"]):
        raise SystemExit("Suite denominator remains unfrozen.")
    lanes = compare_workspace(manifest)
    baseline = read(Path(manifest["workspace_freeze"]))
    prior_git = git_identity()
    accepted = baseline["git_after"]
    comparable = {k:v for k,v in accepted.items()}
    comparable["index"] = {k:accepted["index"][k] for k in ("bytes","sha256")}
    if prior_git != comparable:
        raise SystemExit("Git metadata differs from the freeze.")
    before = workspace_inventory(baseline["paths"])
    if before["other_differences"]:
        raise SystemExit("Unattributed workspace drift. Re-freeze before launch.")
    try:
        execute_jobs(manifest,lanes)
    finally:
        after = workspace_inventory(baseline["paths"])
        write(RUNS / "workspace-guard.json",{"before":before,"after":after,
                                           "git_before":prior_git,"git_after":git_identity()})
        compare_workspace(manifest)
        if after["other_differences"] or git_identity() != prior_git:
            raise RuntimeError("Post-run protection check failed.")

if __name__ == "__main__":
    main()
