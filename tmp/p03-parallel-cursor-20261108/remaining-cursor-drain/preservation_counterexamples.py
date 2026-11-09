import json
from preservation_preflight import HERE, TRACE_PARENTS, protection_failures
from launch import write_json

parent = TRACE_PARENTS[0]
existing = str(parent / "battle-existing.jsonl")
new = str(parent / "battle-new.jsonl")
wrong = str(parent.parent / "battle-new.jsonl")
directory = str(parent / "battle-directory.jsonl")
link = str(parent / "battle-link.jsonl")
owned = str(HERE / "attempt-example")
file_a = {"type": "file", "bytes": 1, "sha256": "a"}
file_b = {"type": "file", "bytes": 1, "sha256": "b"}
before = {existing: file_a}
cases = {
    "same": (before, {}, 0, 0),
    "existing_changed": ({existing: file_b}, {}, 1, 0),
    "existing_removed": ({}, {}, 1, 0),
    "proven_new": ({**before, new: file_a}, {new: "synthetic P02 provenance"}, 0, 1),
    "unproven_new": ({**before, new: file_a}, {}, 1, 0),
    "wrong_parent": ({**before, wrong: file_a}, {wrong: "synthetic"}, 1, 0),
    "directory": ({**before, directory: {"type": "directory"}}, {directory: "synthetic"}, 1, 0),
    "link": ({**before, link: {"type": "link"}}, {link: "synthetic"}, 1, 0),
}
results = {}
for name, (after, evidence, failures, permitted) in cases.items():
    bad, good = protection_failures(before, after, evidence, HERE / "attempt-example")
    results[name] = {"pass": (len(bad), len(good)) == (failures, permitted), "failures": bad, "allowed": good}
write_json(HERE / "PRESERVATION-COUNTEREXAMPLES.json", results)
assert all(row["pass"] for row in results.values())
print(json.dumps({name: row["pass"] for name, row in results.items()}))
