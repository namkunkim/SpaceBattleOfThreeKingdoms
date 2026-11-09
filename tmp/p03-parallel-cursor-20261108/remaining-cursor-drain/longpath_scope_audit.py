import json
from pathlib import Path
from launch import HERE, write_json
from extended_inventory import inventory

source = json.loads((HERE / "LONGPATH-PROTECTED-SUMMARY.json").read_text(encoding="utf-8"))
archive = json.loads((HERE / "LONGPATH-PROTECTED-ARCHIVES.json").read_text(encoding="utf-8"))
counts = {root: value for root, value in source["roots"].items()}
counts.update({root: {"entries": 1, "files": 1} for root in archive})
targets = json.loads((HERE / "LONGPATH-TARGETS.json").read_text(encoding="utf-8"))
target_match = inventory([Path(path) for path in targets])
try:
    inventory([HERE / "reserved-missing-inventory-counterexample"])
except (OSError, ValueError) as error:
    missing = str(error)
else:
    raise AssertionError("missing root was not rejected")
write_json(HERE / "LONGPATH-DECLARED-SCOPE-AUDIT.json", {
    "root_counts": counts, "explicit_extended_targets": target_match,
    "expected_missing_root_error": missing, "archives": archive,
})
