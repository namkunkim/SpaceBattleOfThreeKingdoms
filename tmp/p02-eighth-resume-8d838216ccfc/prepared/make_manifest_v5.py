from pathlib import Path
import hashlib
import json
import sys
sys.dont_write_bytecode=True
from world_product_v5 import RECLICK

p=Path(__file__).resolve().parent
prior=p/"MANIFEST-V4-REVIEW-ONLY.json"
runner=p/"runner_v5.py"
s=(p/"runner_v4.py").read_text(encoding="utf-8-sig")
with runner.open("x",encoding="utf-8") as f:
    f.write(s.replace("from world_product_v4 import assess","from world_product_v5 import assess"))
m=json.loads(prior.read_bytes())
def add(path):
    raw=path.read_bytes()
    meta={"path":str(path),"bytes":len(raw),"sha256":hashlib.sha256(raw).hexdigest()}
    m["dependencies"][str(path)]=meta
    return meta
for path in (prior,runner,Path(__file__).resolve(),p/"ORACLES-V5.md",p/"world_product_v5.py",
             p/"derive_world_v5.py",p/"extend_reclick_v5.py",p/"check_reclick_v5.py",p/"check_v5_synthetic.py",
             p.parent/"REVIEW-PREPARED-V4-INDEPENDENT.md",*sorted((p/"v5-synthetic").glob("*.json"))):
    add(path)
meta=add(p/"world-product-v5.gd")
for job in m["jobs"]:
    if job["row_id"] in (17,18):
        old=job["probe"]
        job["probe"]=meta["path"]
        job["dependency_files"]=[meta if x["path"]==old else x for x in job["dependency_files"]]
        if job["row_id"]==18:
            job["expectation"]["ids"].extend(RECLICK)
        else:
            job["complete_timeout"]={"internal_ms":175000,"failure_exit":1,"failure_records":["complete-aborted","abort-joined-without-result"],"external_owned_job_fallback":True}
for group in m["comparison_groups"]:
    if group["id"]=="world-cancel":
        group["expected_ids"].extend(RECLICK)
m["gates_open"]=["GUI continuous foreground and exclusive input provenance unresolved",
                 "independent V5 re-review and orchestrator authorization",
                 "7 suite exact denominators not frozen",
                 "V5 GDScript product syntax/runtime, cancel reclick and join unverified",
                 "real Godot wrapper and real nested Job rejection unobserved"]
with (p/"MANIFEST-V5-REVIEW-ONLY.json").open("x",encoding="utf-8") as f:
    json.dump(m,f,ensure_ascii=False,indent=2)
