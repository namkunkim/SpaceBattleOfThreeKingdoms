from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime,timezone
import hashlib,json,subprocess,os,time

root=Path.cwd()
out=Path(__file__).resolve().parent
prior=json.loads((out/"preservation.json").read_bytes())
base=json.loads((out.parent/"baseline.json").read_bytes())
oldarchive=json.loads((out/"archive-verification.json").read_bytes())
zip_path=root/oldarchive["archive"]
manifest=out/"delivery-manifest.json"
allowed=prior["exact_allowed_drift"]
new_docs={"P02-LEGACY-OUTCOME-RESULT-20261108.md","P02-LEGACY-OUTCOME-CHECKLIST-20261108.md","SESSION-HANDOFF-P02-LEGACY-OUTCOME-20261108.md"}
runtime=set(json.loads((out.parent/"v3-after-attempt-01/inputs.json").read_bytes()))
def utc(): return datetime.now(timezone.utc).isoformat()
def inspect(path):
    try:
        a=path.stat()
        with path.open("rb") as f:
            sha=hashlib.file_digest(f,"sha256").hexdigest()
        b=path.stat()
        return {"bytes":b.st_size,"sha256":sha,"mtime_ns":b.st_mtime_ns,"changed_while_reading":(a.st_size,a.st_mtime_ns)!=(b.st_size,b.st_mtime_ns)}
    except OSError as e:
        return {"error":str(e)}
def content(r):
    if "sha256" not in r:return r
    return {k:r[k] for k in ("bytes","sha256")}
def git(*args): return subprocess.check_output(["git",*args],env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
def new():
    return {p for p in git("ls-files","--others","--exclude-standard","-z").decode().split("\0") if p and p not in base["paths"] and not p.startswith("tmp/p02-fifth-20261108/") and Path(p).name not in new_docs}
def inventory(paths):
    paths=sorted(paths)
    with ThreadPoolExecutor(12) as pool:
        return dict(zip(paths,pool.map(lambda p:inspect(root/p),paths)))
def observe(n):
    started=utc()
    before=new()
    external=inventory(before|set(prior["unattributed"]))
    existing=inventory(base["paths"])
    after=new()
    drift={p:content(r) for p,r in existing.items() if content(r)!={k:base["paths"][p][k] for k in ("bytes","sha256")}}
    result={"start_utc":started,"end_utc":utc(),"new_path_list_start":sorted(before),"new_path_list_end":sorted(after),
            "new_path_intersects_runtime":sorted((before|after)&runtime),"external":external,"baseline_count":len(existing),
            "baseline_drift":drift,"baseline_unstable":{p:r for p,r in existing.items() if r.get("changed_while_reading") or "error" in r},
            "archive":content(inspect(zip_path)),"manifest":content(inspect(manifest)),
            "index_sha":inspect(root/".git/index").get("sha256"),"head":git("rev-parse","HEAD").decode().strip(),
            "branch":git("branch","--show-current").decode().strip(),
            "staged_index_matches":git("ls-files","--stage","-z")== (out.parent/"index.raw").read_bytes(),
            "engine_and_cache":{p:content(inspect(Path(p))) for p in base["runtime"]}}
    (out/f"post-zip-observation-{n}.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    return result
a=observe(1)
time.sleep(2)
b=observe(2)
def changes(left,right):
    return {p:{"before":left.get(p),"after":right.get(p)} for p in sorted(set(left)|set(right)) if left.get(p)!=right.get(p)}
ac={p:content(r) for p,r in a["external"].items()}
bc={p:content(r) for p,r in b["external"].items()}
audit={"two_observations": [a["start_utc"],a["end_utc"],b["start_utc"],b["end_utc"]],
       "difference_from_zip_observation":changes(prior["unattributed"],bc),
       "difference_between_new_observations":changes(ac,bc),
       "unstable_external": [{p:r for p,r in x["external"].items() if r.get("changed_while_reading") or "error" in r} for x in (a,b)],
       "list_drift_during_observation": [sorted(set(x["new_path_list_end"])^set(x["new_path_list_start"])) for x in (a,b)],
       "runtime_overlap":sorted(set(a["new_path_intersects_runtime"])|set(b["new_path_intersects_runtime"])),
       "baseline_verified":all(x["baseline_count"]==12281 and x["baseline_drift"]==allowed and not x["baseline_unstable"] and x["staged_index_matches"] and x["index_sha"]==prior["index_sha"] and x["head"]==prior["head"] and x["branch"]==(out.parent/"branch.raw").read_text().strip() and all(r=={k:base["runtime"][p][k] for k in ("bytes","sha256")} for p,r in x["engine_and_cache"].items()) for x in (a,b)),
       "archive_verified":all(x["archive"]=={k:oldarchive[k] for k in ("bytes","sha256")} and x["manifest"]["sha256"]==oldarchive["manifest_sha256"] for x in (a,b)),
       "ownership_and_state_before_first_observation":"unverified",
       "evidence_scope":"read-only post-ZIP observations; earlier records retained verbatim"}
(out/"post-zip-preservation-audit.json").write_text(json.dumps(audit,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
print({k:(len(v) if k.startswith("difference") else v) for k,v in audit.items() if k not in ("unstable_external","list_drift_during_observation")})
