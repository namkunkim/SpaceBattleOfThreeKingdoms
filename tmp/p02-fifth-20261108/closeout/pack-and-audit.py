from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib,json,os,subprocess

root=Path.cwd()
proof=root/"tmp/p02-fifth-20261108"
out=proof/"closeout"
bundle=out/"P02-LEGACY-OUTCOME-DELIVERY-20261108.zip"
base=json.loads((proof/"baseline.json").read_bytes())
observed=json.loads((proof/"v3/external-end.json").read_bytes())
hunks=json.loads((out/"docs-hunks.json").read_bytes())
manifest=json.loads((proof/"v3/evidence-sha256.json").read_bytes())["files"]
product={"scripts/world/auto_resolver.gd","scripts/world/battle_outcome.gd"}
known={**{p:v["now"]["sha256"] for p,v in observed["owned_drift"].items()}, **{p:v["after"] for p,v in hunks.items()}}
design="docs/battle-core/pc-campaign-design/"
new_docs={design+n for n in ("P02-LEGACY-OUTCOME-RESULT-20261108.md","P02-LEGACY-OUTCOME-CHECKLIST-20261108.md","SESSION-HANDOFF-P02-LEGACY-OUTCOME-20261108.md")}

def info(path):
    stat=path.stat()
    with path.open("rb") as f:
        sha=hashlib.file_digest(f,"sha256").hexdigest()
    assert (stat.st_size,stat.st_mtime_ns)==(path.stat().st_size,path.stat().st_mtime_ns),path
    return {"bytes":stat.st_size,"sha256":sha}
def git(*args):
    return subprocess.check_output(["git",*args],env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
def dump(p,v):
    p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+"\n",encoding="utf8")

for label,args in [("branch",("branch","--show-current")),("head",("rev-parse","HEAD")),("index",("ls-files","--stage","-z")),("tracked",("ls-files","--cached","-z"))]:
    assert git(*args)==(proof/(label+".raw")).read_bytes(),label
assert info(root/".git/index")["sha256"]==base["index_start"]["sha256"]
for path,r in base["runtime"].items():
    assert info(Path(path))["sha256"]==r["sha256"],path
with ThreadPoolExecutor(12) as pool:
    actual=dict(zip(base["paths"],pool.map(lambda p:info(root/p),base["paths"])))
drift={p:r for p,r in actual.items() if r["sha256"]!=base["paths"][p]["sha256"]}
assert set(drift)==set(known),set(drift)^set(known)
assert all(r["sha256"]==known[p] for p,r in drift.items())
for p,r in hunks.items():
    key=Path(p).name
    old=(out/(key+".old-hunk.txt")).read_bytes()
    new=(out/(key+".new-hunk.txt")).read_bytes()
    before=(out/(key+".before.txt")).read_bytes()
    after=(root/p).read_bytes()
    assert after.count(new)==1 and after.replace(new,old,1)==before
    assert info(out/(key+".before.txt"))["sha256"]==r["before"]
new_now={p for p in git("ls-files","--others","--exclude-standard","-z").decode().split("\0") if p and p not in actual and not p.startswith("tmp/p02-fifth-20261108/") and p not in new_docs}
assert set(observed["files"]) <= new_now
unattributed={p:info(root/p) for p in sorted(new_now)}
for p,r in observed["files"].items():
    assert unattributed[p]=={"bytes":r["bytes"],"sha256":r["sha256"]},p
runtime=set(json.loads((proof/"v3-after-attempt-01/inputs.json").read_bytes()))
assert not runtime & new_now
dump(out/"preservation.json",{"utc":datetime.now(timezone.utc).isoformat(),"baseline_files":len(actual),"exact_allowed_drift":drift,
    "baseline_zip_count":sum(p.endswith(".zip") for p in actual),"baseline_html_count":sum(p.endswith(".html") for p in actual),
    "baseline_p03_count":sum(p.startswith("tmp/p03-") for p in actual),"unattributed":unattributed,
    "unattributed_first_comparison":len(observed["files"]),"new_after_independent_observation":sorted(new_now-set(observed["files"])),
    "unattributed_prior_bytes_and_ownership":"unverified","unattributed_overlap_with_runtime":0,
    "index_sha":base["index_start"]["sha256"],"head":(proof/"head.raw").read_text().strip()})
diff=subprocess.run(["git","diff","--check"],capture_output=True,env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
(out/"diff-check.stdout").write_bytes(diff.stdout)
(out/"diff-check.stderr").write_bytes(diff.stderr)
(out/"diff-check.exit").write_text(str(diff.returncode)+"\n",encoding="utf8")
owned=subprocess.run(["git","diff","--check","--",*sorted(product)],capture_output=True,env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
assert owned.returncode==0 and not owned.stdout
paths={proof/p for p in manifest}
for p,r in manifest.items():
    assert info(proof/p)==r,p
paths.update({proof/"REVIEW-5B-INDEPENDENT.md",proof/"v3/evidence-sha256.json",proof/"closeout-docs.py",Path(__file__).resolve()})
paths.update(root/p for p in new_docs | product | set(hunks))
paths.update(p for p in out.iterdir() if p.is_file() and p.suffix!=".zip" and p.name not in ("archive-verification.json","delivery-manifest.json"))
records={p.relative_to(root).as_posix():info(p) for p in sorted(paths)}
manifest_path=out/"delivery-manifest.json"
dump(manifest_path,{"files":records,"reviewed_scope":"legacy WorldMap settlement boundary","implementation_review":"limited acceptance","closeout_review":"pending"})
entry=manifest_path.relative_to(root).as_posix()
archive_records={**records,entry:info(manifest_path)}
assert not bundle.exists()
with ZipFile(bundle,"x",compression=ZIP_DEFLATED,compresslevel=6) as z:
    for name in sorted(archive_records):
        assert not PurePosixPath(name).is_absolute() and ".." not in PurePosixPath(name).parts
        z.write(root/name,name)
with ZipFile(bundle) as z:
    assert z.testzip() is None
    assert len(z.namelist())==len(set(z.namelist()))==len(archive_records)
    assert set(z.namelist())==set(archive_records)
    for name,r in archive_records.items():
        data=z.read(name)
        assert len(data)==r["bytes"] and hashlib.sha256(data).hexdigest()==r["sha256"],name
        assert info(root/name)==r,name
dump(out/"archive-verification.json",{"archive":bundle.relative_to(root).as_posix(),**info(bundle),
    "entries":len(archive_records),"crc":"pass","entry_sha256_and_live_bytes":"pass","manifest_sha256":info(manifest_path)["sha256"]})
print(info(bundle),len(archive_records),"baseline",len(actual),"drift",len(drift),"unattributed",len(new_now),"diff_check",diff.returncode)
