import hashlib
import json
from pathlib import Path

from extended_inventory import extended
from launch import HERE, write_json

report = json.loads((HERE / "LONGPATH-PROTECTED-SUMMARY.json").read_text(encoding="utf-8-sig"))
entries = {}
for path in report["errors"]:
    canonical = Path(path)
    actual = extended(canonical)
    before = actual.stat()
    with actual.open("rb") as stream:
        sha = hashlib.file_digest(stream, "sha256").hexdigest()
    after = actual.stat()
    if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
        raise ValueError(f"protected archive changed: {path}")
    entries[path] = {"type": "file", "sha256": sha, "bytes": after.st_size}
write_json(HERE / "LONGPATH-PROTECTED-ARCHIVES.json", entries)
print(len(entries))
