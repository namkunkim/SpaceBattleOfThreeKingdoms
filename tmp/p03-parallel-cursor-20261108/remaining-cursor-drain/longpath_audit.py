import json
from pathlib import Path
from preservation_preflight import HERE, ROOT, inventory, protection_roots
from launch import write_json

warnings = (HERE / "attempt-04/start-status-stderr.bin").read_text(encoding="utf-8")
paths = [ROOT / line.split("could not open directory '", 1)[1].split("':", 1)[0]
         for line in warnings.splitlines() if "could not open directory '" in line]
targeted = {}
for path in paths:
    try:
        targeted[str(path)] = inventory([path])
    except (OSError, ValueError) as exc:
        targeted[str(path)] = {"error": str(exc)}
write_json(HERE / "LONGPATH-TARGETS.json", targeted)
roots = protection_roots()
counts = {}
errors = {}
for path in roots:
    try:
        values = inventory([path])
        counts[str(path)] = {"entries": len(values), "files": sum(v["type"] == "file" for v in values.values())}
        with (HERE / "LONGPATH-PROTECTED.jsonl").open("a", encoding="utf-8") as handle:
            for name, record in sorted(values.items()):
                handle.write(json.dumps({"path": name, **record}, ensure_ascii=False) + "\n")
    except (OSError, ValueError) as exc:
        errors[str(path)] = str(exc)
write_json(HERE / "LONGPATH-PROTECTED-SUMMARY.json", {"roots": counts, "errors": errors})
print(json.dumps({"target_counts": {path: len(rows) for path, rows in targeted.items()},
                  "protected_roots": len(counts), "errors": errors}, ensure_ascii=False, indent=2))
