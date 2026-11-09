"""Build a separate blocked V3 manifest. Does not execute a launch."""
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
from assessment_v3 import expectation, selected_keys

here = Path(__file__).resolve().parent
prior = here / "MANIFEST-V2-REVIEW-ONLY.json"
m = json.loads(prior.read_bytes())
for path in (prior, here.parent/"K6-EXECUTION-CONTRACT-v2.md",
             here.parent/"REVIEW-K6-CONTRACT-V2-INDEPENDENT.md",
             here.parent/"REVIEW-PREPARED-V2-INDEPENDENT.md",
             here/"ORACLES-V3.md",here/"runner_v3.py",here/"owned_job_v3.py",
             here/"assessment_v3.py",here/"make_manifest_v3.py",here/"check_v3_synthetic.py",
             *sorted(p for p in (here/"v3-synthetic").iterdir() if p.is_file())):
    data = path.read_bytes()
    m["dependencies"][str(path)] = {"path":str(path),"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()}
groups = {}
for j in m["jobs"]:
    j["expectation"] = expectation(j)
    if j["case_id"] in ("mode-active","mode-initial"):
        continue
    if j["row_id"] in (15,16,17,18,19,20,21):
        kind = "suite" if j["row_id"] in (19,20,21) else "independent"
        group_id = j["case_id"]
        keys = []
    else:
        diff = j["exact_argv"][-1] if j["case_id"] == "native" else None
        kind = "typed"
        group_id = f"{j['case_id']}/{diff}" if diff else j["case_id"]
        keys = selected_keys(j["case_id"],diff)
    if kind == "typed" and not keys:
        raise ValueError(f"comparison has no frozen typed keys: {group_id}")
    group = groups.setdefault(group_id,{"id":group_id,"kind":kind,"processes":[],"raw_paths":[],"keys":keys})
    group["processes"].append(j["process_id"])
    if j["raw"]:
        group["raw_paths"].append(j["raw"])
m["comparison_groups"] = list(groups.values())
m["workspace_freeze"] = str(here.parent/"WORKSPACE-FREEZE.json")
m["owned_launch"] = {"broker":str(here/"owned_job_v3.py"),"platform":"Windows CPython",
                     "barrier":"assign inert broker to private kill-on-close Job before pipe release"}
m["gates_open"] = ["GUI continuous foreground and exclusive input provenance unresolved",
                   "independent V3 re-review and orchestrator authorization",
                   "some suite exact denominators not frozen",
                   "row 17/18 field-wise product comparison and remaining product-format/static review"]
with (here/"MANIFEST-V3-REVIEW-ONLY.json").open("x",encoding="utf-8") as f:
    json.dump(m,f,ensure_ascii=False,indent=2)
print(len(m["jobs"]),m["timing"],len(groups))
