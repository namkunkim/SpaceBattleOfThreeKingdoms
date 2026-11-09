"""Exercise V3 log acceptance with synthetic records. No engine or launcher."""
from copy import deepcopy
import importlib.util
from pathlib import Path

BASE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("return_oracle", BASE / "run-reviewed-return.py")
oracle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(oracle)
manifest = oracle.read(BASE / "EXECUTION-REVIEW-ONLY-V3.json")
scratch = BASE / "synthetic-oracle-v3"
scratch.mkdir()
template = next(c for c in manifest["commands"] if c["side"] == "after" and c["name"] == "result")
rows = [f"P02_RETURN_ASSERT {key} PASS" for key in template["expected_assertions"]]

for name, changed, accept in [
    ("exact", rows, True),
    ("missing", rows[1:], False),
    ("substitution", ["P02_RETURN_ASSERT unknown PASS", *rows[1:]], False),
    ("swapped", [rows[1], rows[0], *rows[2:]], False),
]:
    directory = scratch / name
    directory.mkdir()
    command = deepcopy(template)
    command["os_log"] = str(directory / "engine.os.tsv")
    Path(command["os_log"]).write_text(
        "1\tt\texit\t0\n2\tt\troot_cleanup\tTrue\tTrue\t0\t0\tTrue\n3\tt\tcleanup\t0\n",
        encoding="utf-8",
    )
    logs = [*changed, f"P02_RETURN_DONE {len(rows)} 0"]
    for line, count in command["diagnostics"].items():
        logs.extend([line] * count)
    (directory / "engine.log").write_text("\n".join(logs), encoding="utf-8")
    try:
        oracle.assess(command, directory)
    except RuntimeError:
        observed = False
    else:
        observed = True
    if observed != accept:
        raise AssertionError(name)
    print(name, "accepted" if observed else "rejected")
