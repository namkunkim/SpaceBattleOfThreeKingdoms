from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, os, subprocess, sys

root = Path.cwd()
out = Path(__file__).resolve().parent
parent = out.parent
baseline = json.loads((parent / "baseline.json").read_bytes())
after_run = json.loads((parent / "v3-after-attempt-01-workspace.json").read_bytes())
before_run = json.loads((parent / "v3-before-attempt-02-workspace.json").read_bytes())
prefix = "tmp/p02-fifth-20261108/"
product = {"scripts/world/auto_resolver.gd", "scripts/world/battle_outcome.gd"}

def git(*args):
    return subprocess.check_output(["git", *args], env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"})

def capture(p):
    file = root / p
    if not file.exists():
        return None
    start = file.stat()
    with file.open("rb") as stream:
        sha = hashlib.file_digest(stream, "sha256").hexdigest()
    end = file.stat()
    assert (start.st_size, start.st_mtime_ns) == (end.st_size, end.st_mtime_ns), p
    return {"bytes": end.st_size, "sha256": sha, "modified_ns": end.st_mtime_ns, "created_ns": end.st_ctime_ns}

def list_new():
    return {p for p in git("ls-files", "--others", "--exclude-standard", "-z").decode().split("\0")
            if p and p not in baseline["paths"] and not p.startswith(prefix)}

assert git("branch", "--show-current") == (parent / "branch.raw").read_bytes()
assert git("rev-parse", "HEAD") == (parent / "head.raw").read_bytes()
assert git("ls-files", "--stage", "-z") == (parent / "index.raw").read_bytes()
assert capture(".git/index")["sha256"] == baseline["index_start"]["sha256"]
for p, item in baseline["runtime"].items():
    assert capture(p)["sha256"] == item["sha256"]
new = list_new()
seen = set(after_run["new"])
observed = sorted(new | seen)
with ThreadPoolExecutor(12) as pool:
    files = dict(zip(observed, pool.map(capture, observed)))
    existing = dict(zip(baseline["paths"], pool.map(capture, baseline["paths"])))
after_capture = list_new()
owned_drift = {p: {"before": baseline["paths"][p], "now": item} for p, item in existing.items()
               if item is None or item["bytes"] != baseline["paths"][p]["bytes"] or item["sha256"] != baseline["paths"][p]["sha256"]}
assert set(owned_drift) == product, list(owned_drift)
assert all(owned_drift[p]["now"]["sha256"] == after_run["drift"][p]["now"]["sha256"] for p in product)
first = "external-start.json"
stage = sys.argv[1]
comparison = None
if stage == "end":
    prior = json.loads((out / first).read_bytes())
    comparison = {"changed_or_removed": [p for p, row in prior["files"].items() if files.get(p) != row],
                  "arrived_after_start": sorted(set(files) - set(prior["files"]))}
    assert not comparison["changed_or_removed"], comparison
assert not (set(files) & set(json.loads((parent / "v3-after-attempt-01/inputs.json").read_bytes())))
result = {"utc_observation": datetime.now(timezone.utc).isoformat(), "baseline_count": len(existing),
          "owned_drift": owned_drift, "new_in_before_run": before_run["new"], "new_in_after_run": sorted(seen),
          "new_after_run_before_observation": sorted(new - seen), "observed_files": len(files), "files": files, "comparison": comparison,
          "arrived_during_read": sorted(after_capture - new), "removed_during_read": sorted(new - after_capture),
          "attribution": "New non-evidence paths have unverified ownership and origin. No writes by this P02 implementation."}
(out / ("external-" + stage + ".json")).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf8")
print("Baseline count", len(existing), "owned drift", len(owned_drift), "external paths", len(files), "new after run", len(new - seen))
