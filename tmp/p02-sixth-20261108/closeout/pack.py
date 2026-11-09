from pathlib import Path,PurePosixPath
from zipfile import ZipFile,ZIP_DEFLATED
import hashlib,json,subprocess,os
from audit import audit,info,read,R,D,P
def dump(path,data):
 with path.open("x",encoding="utf8") as f:json.dump(data,f,indent=2,ensure_ascii=False)
def process_diff(label,files):
 x=subprocess.run(["git","diff","--check","--",*files],capture_output=True,env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
 (D/(label+".stdout")).write_bytes(x.stdout)
 (D/(label+".stderr")).write_bytes(x.stderr)
 (D/(label+".exit")).write_text(str(x.returncode)+"\n",encoding="utf8")
 return x.returncode
prior=read(D/"preservation-before.json")
assert process_diff("owned-diff-check",[p for p in prior["owned"] if p.endswith(".gd")])==0
process_diff("global-diff-check",[])
manifest=D/"delivery-manifest.json"
archive=D/"P02-HOST-PREP-DELIVERY-20261108.zip"
assert not manifest.exists() and not archive.exists()
files={R/p for p in prior["owned"]}
files.update(p for p in P.iterdir() if p.is_file())
files.update(p for p in D.iterdir() if p.is_file())
for folder in ("before-attempt-01","before-attempt-03","after-attempt-01","after-attempt-02","leak-verbose-diagnostics"):
 for p in (P/folder).rglob("*"):
  if p.is_file() and p.name in {"stdout","stderr","process.json","command.json","result.json","comparison.json","inputs.json","workspace-pre.json","workspace-post.json","processes.json","trace-compare.json"}:
   files.add(p)
trace=read(P/"trace-oracle-v4.json")
files.update(P/p for p in trace["sources"])
post_atomic=P/"after-attempt-02/atomic"
rows=read(post_atomic/"result.json")["recover_publish_once"]["value"]
files.update(post_atomic/"roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms"/rows[k].removeprefix("user://") for k in ("start_file","close_file"))
records={p.relative_to(R).as_posix():info(p) for p in sorted(files)}
dump(manifest,{"scope":"legacy FleetBattle3D candidate preparation and synchronous failure guards",
 "implementation_review":"limited acceptance","closeout_review":"pending","files":records})
members={**records,manifest.relative_to(R).as_posix():info(manifest)}
with ZipFile(archive,"x",ZIP_DEFLATED,compresslevel=6) as z:
 for name in sorted(members):
  assert not PurePosixPath(name).is_absolute() and ".." not in PurePosixPath(name).parts
  z.write(R/name,name)
with ZipFile(archive) as z:
 assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))==len(members) and set(z.namelist())==set(members)
 for name,expected in members.items():
  content=z.read(name)
  assert {"bytes":len(content),"sha256":hashlib.sha256(content).hexdigest()}==expected==info(R/name),name
dump(D/"archive-verification.json",{"archive":archive.relative_to(R).as_posix(),**info(archive),"entries":len(members),
 "crc":"pass","entry_sha256_and_live_bytes":"pass","manifest_sha256":info(manifest)["sha256"]})
after=audit()
dump(D/"preservation-after.json",after)
drift={p:{"before":prior["files"].get(p),"after":after["files"].get(p)} for p in sorted(set(prior["files"])|set(after["files"])) if prior["files"].get(p)!=after["files"].get(p)}
assert not set(drift)&(set(prior["owned"])|set(read(P/"after-attempt-02/inputs.json")))
dump(D/"preservation-comparison.json",{"counts_before":prior["counts"],"counts_after":after["counts"],"owned_files_unchanged":True,
 "runtime_overlap_with_drift":0,"unattributed_observed_diff":drift,"unattributed_baseline_count":len(after["unattributed"]),
 "p03_baseline_drift_count":sum(p.startswith("tmp/p03-") for p in after["unattributed"]),
 "ownership_and_prior_bytes":"unverified; sequential observations"})
print(info(archive),len(members),len(drift))
