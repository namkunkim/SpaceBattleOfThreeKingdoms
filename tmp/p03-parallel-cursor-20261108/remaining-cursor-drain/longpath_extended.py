import hashlib
import json
import os
from pathlib import Path
from preservation_preflight import HERE
from launch import write_json

targets = json.loads((HERE / "LONGPATH-TARGETS.json").read_text(encoding="utf-8"))
result = {}
for path in targets:
    extended = "\\\\?\\" + path
    rows = []
    for root, folders, files in os.walk(extended, onerror=lambda error: (_ for _ in ()).throw(error)):
        rows.append({"dir": root, "folders": sorted(folders), "files": sorted(files)})
        for file in files:
            name = Path(root) / file
            with name.open("rb") as handle:
                rows.append({"path": str(name), "sha256": hashlib.file_digest(handle, "sha256").hexdigest(),
                             "bytes": handle.tell()})
    result[path] = rows
write_json(HERE / "LONGPATH-EXTENDED-TARGETS.json", result)
