from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json

out = Path(__file__).resolve().parent.parent
v3 = out / "v3"
evidence = [
    "baseline.json", "branch.raw", "head.raw", "index.raw", "tracked.raw", "untracked.raw",
    "engine-version.txt", "diff-check-before.exit", "diff-check-before.stderr", "diff-check-before.stdout",
    "PLAN.md", "PLAN-V2.md", "PLAN-V3.md", "REVIEW-PLAN-INDEPENDENT.md", "REVIEW-PLAN-V2-INDEPENDENT.md",
    "REVIEW-PLAN-V3-INDEPENDENT.md", "REVIEW-CONCURRENT-FILES-INDEPENDENT.md", "IMPLEMENTATION-EVIDENCE.md",
    "battle_outcome.gd.before.txt", "auto_resolver.gd.before.txt", "fixture.gd", "product-outcome-common.gd",
    "product-outcome-boundary.gd", "run.py", "prepare-v3.py", "derive-v3-launcher.py",
    "before-attempt-01-workspace.json", "v3-precopy-workspace.json", "v3-pre-run-workspace.json",
    "v3-before-attempt-02-workspace.json", "v3-after-attempt-01-workspace.json",
]
paths = {out / p for p in evidence}
paths.update(p for p in v3.iterdir() if p.is_file() and p.name != "evidence-sha256.json")
for label in ("before-attempt-01", "v3-before-attempt-02", "v3-after-attempt-01"):
    paths.update(p for p in (out / label).rglob("*") if p.is_file())

def measure(p):
    stat = p.stat()
    with p.open("rb") as file:
        digest = hashlib.file_digest(file, "sha256").hexdigest()
    assert (p.stat().st_size, p.stat().st_mtime_ns) == (stat.st_size, stat.st_mtime_ns), p
    return {"bytes": stat.st_size, "sha256": digest}

proof = {"utc": datetime.now(timezone.utc).isoformat(), "files": {p.relative_to(out).as_posix(): measure(p) for p in sorted(paths)}}
(v3 / "evidence-sha256.json").write_text(json.dumps(proof, indent=2, ensure_ascii=False) + "\n", encoding="utf8")
print(len(proof["files"]), measure(v3 / "evidence-sha256.json")["sha256"])
