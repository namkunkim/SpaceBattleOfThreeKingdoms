import json
from pathlib import Path

from extended_inventory import inventory
from launch import HERE, write_json
from preservation_preflight import protection_roots

roots = protection_roots()
rows = {}
failures = {}
for root in roots:
    try:
        rows.update(inventory([root]))
    except (OSError, ValueError) as exc:
        failures[str(root)] = str(exc)
targets = json.loads((HERE / "LONGPATH-TARGETS.json").read_text(encoding="utf-8"))
for target in targets:
    if target not in rows:
        failures[target] = "expected long-path directory missing from protected inventory"
try:
    inventory([HERE / "reserved-missing-inventory-counterexample"])
except (OSError, ValueError):
    absent_root_rejected = True
else:
    absent_root_rejected = False
write_json(HERE / "LONGPATH-EXTENDED-PROTECTED.json", rows)
report = {
    "roots": [str(root) for root in roots], "failures": failures, "entries": len(rows),
    "files": sum(row["type"] == "file" for row in rows.values()),
    "expected_long_directories_present": all(path in rows for path in targets),
    "absent_root_rejected": absent_root_rejected,
}
write_json(HERE / "LONGPATH-EXTENDED-PROTECTED-SUMMARY.json", report)
print(json.dumps(report, indent=2))
raise SystemExit(bool(failures) or not absent_root_rejected)
