from concurrent.futures import ThreadPoolExecutor
import subprocess
from gate import dump, engine, evidence, root, runner, runtime, sha

runtime()
out = evidence / "negative-oracle"
out.mkdir()
raw = (root / runner).read_bytes()
anchor = b"var actual := owner.drain_events_for(side)"
assert raw.count(anchor) == 1
jobs = []
for name, replacement in [
        ("raw", b"var actual := owner.drain_events()"),
        ("swap", b"var actual := owner.drain_events_for(1 - side)")]:
    script = out / (name + ".gd")
    script.write_bytes(raw.replace(anchor, replacement))
    cmd = [str(engine), "--headless", "--path", str(root), "--log-file",
           str(out / (name + ".engine.log")), "-s", str(script)]
    jobs.append({"name": name, "command": cmd, "script_sha256": sha(script)})
dump(out / "freeze.json", {"jobs": jobs, "canonical_runner_sha256": sha(root / runner)})
def run(job):
    name = job["name"]
    proc = subprocess.run(job["command"], capture_output=True, timeout=90)
    (out / (name + ".stdout")).write_bytes(proc.stdout)
    (out / (name + ".stderr")).write_bytes(proc.stderr)
    expected = all(b"VIEWER_ROW " + row + b" FAIL " in proc.stdout for row in [b"E03", b"E04"])
    result = {"name": name, "exit": proc.returncode, "expected_two_fog_rows_fail": expected,
              "script_errors": proc.stderr.count(b"SCRIPT ERROR:")}
    result["passed"] = proc.returncode == 1 and expected and result["script_errors"] == 0
    return result
with ThreadPoolExecutor(2) as pool:
    results = list(pool.map(run, jobs))
runtime()
dump(out / "results.json", results)
print(results)
