"""Compose V4 sources from preserved V3 runner and review manifest."""
from pathlib import Path
import hashlib
import json

p = Path(__file__).resolve().parent
source = p / "runner_v3.py"
runner = p / "runner_v4.py"
s = source.read_text(encoding="utf-8-sig")
s = s.replace("from owned_job_v3 import run","from owned_job_v3 import run\nfrom world_product_v4 import assess as assess_world_product")
s = s.replace('    if group["kind"] == "suite":','    if group["kind"] == "world-product":\n        return assess_world_product(group["raw_paths"],group["cancel"],group["expected_ids"])\n    if group["kind"] == "suite":')
with runner.open("x",encoding="utf-8") as f:
    f.write(s)
prior = p / "MANIFEST-V3-REVIEW-ONLY.json"
m = json.loads(prior.read_bytes())
def add(path):
    raw = path.read_bytes()
    meta = {"path":str(path),"bytes":len(raw),"sha256":hashlib.sha256(raw).hexdigest()}
    m["dependencies"][str(path)] = meta
    return meta
hist = p / "SUITE-HISTORY-V4.json"
for path in (prior, runner, source, Path(__file__).resolve(), hist,
             p / "ORACLES-V4.md", p/"world-product-v4.gd",p/"world_product_v4.py",p/"derive_world_v4.py",
             p/"suite_history_v4.py",p/"check_v4_synthetic.py",p.parent/"REVIEW-PREPARED-V3-INDEPENDENT.md",
             *sorted(x for x in (p/"v4-synthetic").iterdir() if x.is_file())):
    add(path)
history = json.loads(hist.read_bytes())
for group in history["gate_k3_k4"].values():
    for log in group["logs"]:
        add(Path(log["path"]))
for records in history["observations"].values():
    for log in records:
        add(Path(log["path"]))
k4 = p.parents[1] / "p02-eighth-20261108/gate-k4"
for case in ("complete","cancel"):
    for lane in ("before","after"):
        add(k4 / f"{lane}-world-{case}/result.json")
jobs = {}
for j in m["jobs"]:
    if j["row_id"] in (17,18):
        old = j["probe"]
        meta = add(p / "world-product-v4.gd")
        j["probe"] = meta["path"]
        j["dependency_files"] = [meta if i["path"]==old else i for i in j["dependency_files"]]
        jobs[j["case_id"]] = j
for g in m["comparison_groups"]:
    if g["id"] in jobs:
        g.update(kind="world-product",cancel=g["id"]=="world-cancel",expected_ids=jobs[g["id"]]["expectation"]["ids"])
m["gates_open"] = ["GUI continuous foreground and exclusive input provenance unresolved",
                   "independent V4 re-review and orchestrator authorization",
                   "7 suite exact denominators not frozen",
                   "product-probe syntax/runtime unverified and cancel reclick contract to resolve",
                   "real Godot wrapper and real nested Job rejection unobserved"]
with (p / "MANIFEST-V4-REVIEW-ONLY.json").open("x",encoding="utf-8") as f:
    json.dump(m,f,ensure_ascii=False,indent=2)
