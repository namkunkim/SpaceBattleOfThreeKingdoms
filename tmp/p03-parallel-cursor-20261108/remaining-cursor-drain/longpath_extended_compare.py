import json
from launch import HERE, write_json

def read(name):
    return json.loads((HERE / name).read_text(encoding="utf-8"))

original = {}
for line in (HERE / "LONGPATH-PROTECTED.jsonl").open(encoding="utf-8"):
    row = json.loads(line)
    original[row.pop("path")] = row
archives = read("LONGPATH-PROTECTED-ARCHIVES.json")
original.update(archives)
extended = read("LONGPATH-EXTENDED-PROTECTED.json")
summary = read("LONGPATH-EXTENDED-PROTECTED-SUMMARY.json")
assert set(summary["failures"]) == set(archives)
extended.update(archives)
assert all(root in extended for root in summary["roots"])
write_json(HERE / "LONGPATH-EXTENDED-COMPARISON.json", {
    "files": sum(row["type"] == "file" for row in extended.values()),
    "directories": sum(row["type"] == "directory" for row in extended.values()),
    "new": sorted(extended.keys() - original.keys()),
    "removed": sorted(original.keys() - extended.keys()),
    "changed": sorted(key for key in original.keys() & extended.keys() if original[key] != extended[key]),
    "separate_observation_windows": True,
})
