from pathlib import Path
import hashlib
import json
import subprocess
import sys

root = Path.cwd()
out = root / "tmp/p02-fifth-20261108/v3"
prefixes = ("tmp/p03-command-suffix-20261107/", "tmp/p03-terminal-boundary-20261108/")
baseline = json.loads((out.parent / "baseline.json").read_bytes())["paths"]

def read(path):
    before = path.stat()
    with path.open("rb") as file:
        digest = hashlib.file_digest(file, "sha256").hexdigest()
    after = path.stat()
    assert (before.st_size, before.st_mtime_ns) == (after.st_size, after.st_mtime_ns), path
    return {"bytes": before.st_size, "sha256": digest}

paths = {p for p in subprocess.check_output(["git", "ls-files", "--others", "--exclude-standard", "-z"]).decode().split("\0") if p.startswith(prefixes)}
rows = {p: read(root / p) for p in sorted(paths)}
original = {p: r for p, r in baseline.items() if p.startswith(prefixes)}
for p, r in original.items():
    assert rows.get(p) == {"bytes": r["bytes"], "sha256": r["sha256"]}, p
if sys.argv[1] == "after":
    old = json.loads((out / "p03-protection-before.json").read_bytes())["paths"]
    assert all(rows.get(p) == info for p, info in old.items())
(out / ("p03-protection-" + sys.argv[1] + ".json")).write_text(json.dumps({"paths": rows, "new_since_12281": sorted(paths - set(original))}, indent=2) + "\n", encoding="utf8")
print("P03", sys.argv[1], len(rows), "new since baseline", len(paths - set(original)))
