from pathlib import Path
import hashlib,json
d=Path(__file__).resolve().parent
old=d.parent/"closeout"
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return json.loads(p.read_bytes())
proof=read(old/"docs-hunks.json")
prior=read(old/"archive-verification.json")
assert sha(Path(prior["archive"]).read_bytes())==prior["sha256"]
for name,record in proof.items():
 path=Path(name)
 key=path.name
 before=(old/(key+".before.txt")).read_bytes()
 a=(old/(key+".old-hunk.txt")).read_bytes()
 b=(old/(key+".new-hunk.txt")).read_bytes()
 assert sha(path.read_bytes())==record["after"] and sha(before)==record["before"]
 if key=="CHECKLIST-OPEN.md":
  assert b.count(b"\r\n")==1
  b=b.replace(b"\r\n",b"\n")
 if key=="P02-PROGRESS-CHECKLIST.md":
  assert b.count(b"/closeout/P02-HOST-PREP-DELIVERY-20261108.zip")==1
  b=b.replace(b"/closeout/P02-HOST-PREP-DELIVERY-20261108.zip",b"/closeout-v2/P02-HOST-PREP-DELIVERY-20261108.zip")
 after=before.replace(a,b,1)
 assert after.count(b)==1 and after.replace(b,a,1)==before
 for suffix,content in (("before",before),("old-hunk",a),("new-hunk",b)):
  (d/(key+"."+suffix+".txt")).write_bytes(content)
 path.write_bytes(after)
 record["after"]=sha(after)
(d/"docs-hunks.json").write_text(json.dumps(proof,indent=2)+"\n",encoding="utf8")
handoff=Path("docs/battle-core/pc-campaign-design/SESSION-HANDOFF-P02-HOST-PREP-20261108.md")
data=handoff.read_bytes()
oldlink=b"/closeout/preservation-before.json"
assert data.count(oldlink)==1
handoff.write_bytes(data.replace(oldlink,b"/closeout-v2/preservation-before.json"))
(d/"superseded-archive.json").write_text(json.dumps(prior,indent=2)+"\n",encoding="utf8")
