import json
from pathlib import Path
from launch import HERE, write_json

rows = {}
for line in (HERE / "LONGPATH-PROTECTED.jsonl").open(encoding="utf-8"):
    item = json.loads(line)
    path = item.pop("path")
    if path in rows and rows[path] != item:
        raise ValueError(f"inconsistent overlapping observations: {path}")
    rows[path] = item
archive = json.loads((HERE / "LONGPATH-PROTECTED-ARCHIVES.json").read_text(encoding="utf-8"))
rows.update(archive)
summary = json.loads((HERE / "LONGPATH-PROTECTED-SUMMARY.json").read_text(encoding="utf-8"))
if set(summary["errors"]) != set(archive):
    raise ValueError("unresolved expected roots")
roots = list(summary["roots"]) + list(archive)
if any(root not in rows for root in roots):
    raise ValueError("protected root absent")
write_json(HERE / "LONGPATH-MERGED-SUMMARY.json", {
    "roots": len(roots),
    "directories": sum(row["type"] == "directory" for row in rows.values()),
    "files": sum(row["type"] == "file" for row in rows.values()),
    "archive_root_recoveries": len(archive),
    "errors_remaining_in_declared_root_scope": 0,
    "single_atomic_snapshot": False,
})
