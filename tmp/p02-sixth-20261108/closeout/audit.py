from concurrent.futures import ThreadPoolExecutor
from datetime import datetime,timezone
from pathlib import Path
import hashlib,json,os,subprocess,sys
R=Path.cwd()
D=Path(__file__).resolve().parent
P=D.parent
REL=P.relative_to(R).as_posix()
def read(path):return json.loads(path.read_bytes())
def info(path):
 before=path.stat()
 with path.open("rb") as file: sha=hashlib.file_digest(file,"sha256").hexdigest()
 after=path.stat()
 assert (before.st_size,before.st_mtime_ns)==(after.st_size,after.st_mtime_ns),path
 return {"bytes":after.st_size,"sha256":sha}
def git(*args):return subprocess.check_output(["git",*args],env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
def names(*args):return {x for x in git("ls-files","-z",*args).decode().split("\0") if x and not x.startswith(REL+"/")}
def metadata():
 return {"head":git("rev-parse","HEAD").decode().strip(),"branch":git("branch","--show-current").decode().strip(),
  "index":info(R/".git/index"),"stage_sha256":hashlib.sha256(git("ls-files","--stage","-z")).hexdigest()}
def audit():
 baseline=read(P/"baseline.json")
 product=read(P/"product-hunk-proof.json")
 hunks=read(D/"docs-hunks.json")
 new_docs={str((R/"docs/battle-core/pc-campaign-design"/n).relative_to(R).as_posix()) for n in (
  "P02-HOST-PREP-RESULT-20261108.md","P02-HOST-PREP-CHECKLIST-20261108.md","SESSION-HANDOFF-P02-HOST-PREP-20261108.md")}
 runtime=read(P/"after-attempt-02/inputs.json")
 meta=metadata()
 expected={k:baseline["before"][k] for k in meta}
 expected["index"]={k:expected["index"][k] for k in ("bytes","sha256")}
 assert meta==expected
 assert len(baseline["paths"])==19365
 for p,v in hunks.items():
  key=Path(p).name
  prior=(D/(key+".before.txt")).read_bytes()
  old=(D/(key+".old-hunk.txt")).read_bytes()
  new=(D/(key+".new-hunk.txt")).read_bytes()
  now=(R/p).read_bytes()
  assert now.count(new)==1 and now.replace(new,old,1)==prior
  assert hashlib.sha256(prior).hexdigest()==v["before"]==baseline["paths"][p]["sha256"]
 tracked=names("--cached")
 untracked=names("--others","--exclude-standard")
 paths=sorted(tracked|untracked)
 with ThreadPoolExecutor(8) as pool:
  actual=dict(zip(paths,pool.map(lambda name:info(R/name),paths)))
 assert metadata()==meta
 list_drift=sorted((tracked^names("--cached"))|(untracked^names("--others","--exclude-standard")))
 assert not set(list_drift)&(set(runtime)|set(hunks)|new_docs)
 prior={p:{k:r[k] for k in ("bytes","sha256")} for p,r in baseline["paths"].items()}
 delta={p:{"baseline":prior.get(p),"observed":actual.get(p)} for p in sorted(set(prior)|set(actual)) if prior.get(p)!=actual.get(p)}
 owned={**{p:v["after_sha256"] for p,v in product.items()},**{p:v["after"] for p,v in hunks.items()},**{p:actual[p]["sha256"] for p in new_docs}}
 assert set(owned)<=set(delta)
 assert all(actual[p]["sha256"]==sha for p,sha in owned.items())
 unattributed={p:r for p,r in delta.items() if p not in owned}
 assert not set(unattributed)&set(runtime)
 assert not set(delta)&{p for p in prior if p.endswith((".zip",".html"))}
 engine=Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
 cache=R/".godot/global_script_class_cache.cfg"
 for p,key in ((engine,"engine"),(cache,"classcache")):
  assert info(p)["sha256"]==baseline[key]["sha256"]
 return {"utc":datetime.now(timezone.utc).isoformat(),"counts":{"tracked":len(tracked),"untracked":len(untracked),
  "baseline":len(prior),"baseline_p03":sum(p.startswith("tmp/p03-") for p in prior),
  "baseline_zip":sum(p.endswith(".zip") for p in prior),"baseline_html":sum(p.endswith(".html") for p in prior)},
  "metadata":meta,"list_drift":list_drift,"files":actual,"owned":owned,"unattributed":unattributed}
if __name__=="__main__":
 result=audit()
 dest=D/sys.argv[1]
 with dest.open("x",encoding="utf8") as f:json.dump(result,f,indent=2,ensure_ascii=False)
 print(result["counts"],"owned",len(result["owned"]),"unattributed",len(result["unattributed"]),"list drift",result["list_drift"])
