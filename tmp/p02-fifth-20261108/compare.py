from pathlib import Path
import hashlib, json, re, subprocess, sys

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent
PRODUCT = ("scripts/world/battle_outcome.gd", "scripts/world/auto_resolver.gd")
BEFORE = OUT / sys.argv[1]
AFTER = OUT / sys.argv[2]

def read(path):
    return json.loads(path.read_bytes())

def sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()

def count(path, regex):
    return re.search(regex, path.read_text(encoding="utf8")).groups()

before_inputs = read(BEFORE / "inputs.json")
after_inputs = read(AFTER / "inputs.json")
assert set(after_inputs) - set(before_inputs) == {"tmp/p02-fifth-20261108/product-outcome-boundary.gd"}
assert set(before_inputs) - set(after_inputs) == set()
assert sorted(p for p in before_inputs if before_inputs[p] != after_inputs[p]) == sorted(PRODUCT)
processes = {}
for label, stage, names in [
    ("before", BEFORE, ["product-outcome-common", "world_link", "p02_worker_adapter", "p02_headless_adapter"]),
    ("after", AFTER, ["product-outcome-common", "world_link", "p02_worker_adapter", "p02_headless_adapter", "product-outcome-boundary"]),
]:
    reports = read(stage / "processes.json")
    assert len(reports) == len(names)
    for name, row in zip(names, reports):
        dirname = stage / name
        assert row["exit"] == 0 and row["marker"] and not row["script_error"] and not row["timeout"], name
        for stream in ("stdout", "stderr"):
            assert sha(dirname / stream) == row[stream]
        if "result_sha256" in row:
            data = dirname / ("observations.json" if name == "p02_headless_adapter" else "result.json")
            assert sha(data) == row["result_sha256"]
        if name.startswith("product-outcome"):
            actual = read(dirname / "result.json")
            assert actual["failures"] == 0
            denom = 18 if name.endswith("common") else 7
            assert sorted(actual["rows"]) == [("A" if name.endswith("common") else "B") + f"{i:02d}" for i in range(1, denom + 1)], name
    processes[label] = dict(zip(names, reports))

old = read(BEFORE / "product-outcome-common/result.json")
new = read(AFTER / "product-outcome-common/result.json")
assert old["rows"] == new["rows"] and old["checks"] == new["checks"]
assert old["guard"]["classes"] == new["guard"]["classes"] == ["res://" + p for p in PRODUCT]
assert old["guard"]["version"] == new["guard"]["version"]
headless = "p02_headless_adapter"
worker = "p02_worker_adapter"
assert (BEFORE / headless / "observations.json").read_bytes() == (AFTER / headless / "observations.json").read_bytes()
for suite in (worker, headless):
    before_out = (BEFORE / suite / "stdout").read_text(encoding="utf8")
    after_out = (AFTER / suite / "stdout").read_text(encoding="utf8")
    assert re.sub(r"running_frames_observed=\d+", "", before_out) == re.sub(r"running_frames_observed=\d+", "", after_out)
assert old["rows"]["A03"]["tick"] == 10 and old["rows"]["A03"]["consumed"]
boundary = read(AFTER / "product-outcome-boundary/result.json")
assert all(boundary["rows"][key]["joined"] and boundary["rows"][key]["worker_caller"] != boundary["rows"][key]["main_caller"] for key in ("B01", "B02", "B03"))
assert boundary["rows"]["B04"] == {"ready": True, "joined": True, "poll": False, "unpublished": True}
assert boundary["rows"]["B05"]["repeat"]
workspace = read(OUT / (AFTER.name + "-workspace.json"))
assert set(workspace["drift"]) == set(PRODUCT), workspace["drift"]
assert all(p.startswith(("tmp/p03-command-suffix-20261107/", "tmp/p03-terminal-boundary-20261108/")) for p in workspace["new"]), workspace["new"]
base = read(OUT / "baseline.json")
for product in PRODUCT:
    assert sha(OUT / (Path(product).name + ".before.txt")) == base["paths"][product]["sha256"]
    assert sha(ROOT / product) == after_inputs[product]["sha256"]
checks = subprocess.run(["git", "-c", "core.whitespace=blank-at-eol,blank-at-eof,space-before-tab", "diff", "--check", "--", *PRODUCT], capture_output=True)
(OUT / "owned-diff-check.stdout").write_bytes(checks.stdout)
(OUT / "owned-diff-check.stderr").write_bytes(checks.stderr)
assert checks.returncode == 0
report = {"before": BEFORE.name, "after": AFTER.name, "same_common_rows": len(old["rows"]), "common_checks_per_stage": old["checks"],
          "boundary_rows": len(boundary["rows"]), "boundary_checks": boundary["checks"], "execution_input_count": len(before_inputs),
          "world_link": "WORLD_LINK_PASS; suite has no emitted assertion count",
          "worker_checks": int(count(AFTER / worker / "stdout", r"P02_WORKER_CHECKS (\d+)")[0]),
          "headless_counts": count(AFTER / headless / "stdout", r"cases=(\d+) checks=(\d+) rejections=(\d+) natural=(\d+) timeout=(\d+)"),
          "input_differences": list(PRODUCT), "processes": processes, "workspace": workspace}
(OUT / "gate-verdict.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf8")
print("PASS", report["same_common_rows"], report["boundary_rows"], report["common_checks_per_stage"], report["boundary_checks"])
