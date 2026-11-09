from pathlib import Path
import hashlib,json,os
root=Path(os.environ["USERPROFILE"])/".codex/sessions/2026/11/08"
e=Path("tmp/p02-third-20261108")
out=e/"closeout"
paths={"/root/p02_third_plan":"plan_author","/root/p02_third_impl":"implementation","/root/p02_third_review":"independent_reviewer"}
proof={}
for f in root.glob("*.jsonl"):
 with f.open("rb") as source:
  raw_meta=source.readline()
  meta=json.loads(raw_meta)["payload"]
  path=meta.get("agent_path")
  if path not in paths: continue
  turns=[]
  for raw in source:
   rec=json.loads(raw)
   if rec.get("type")!="turn_context": continue
   p=rec["payload"]
   turns.append({"timestamp":rec.get("timestamp"),"turn_id":p.get("turn_id"),"model":p.get("model"),"raw_sha256":hashlib.sha256(raw).hexdigest()})
  proof[paths[path]]={"session":meta["id"],"parent":meta["parent_thread_id"],"path":path,"session_meta_raw_sha256":hashlib.sha256(raw_meta).hexdigest(),"session_file":f.name,"turn_context":turns}
assert len(proof)==3
assert all(x["model"]=="gpt-6.1-sol" for key in ("implementation","plan_author") for x in proof[key]["turn_context"])
assert all(x["model"]=="gpt-6.1-terra" for x in proof["independent_reviewer"]["turn_context"])
assert len({x["session"] for x in proof.values()})==3 and len({x["parent"] for x in proof.values()})==1
proof["review_records"]={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in e.glob("REVIEW*.md")}
(out/"model-independence.json").write_text(json.dumps(proof,indent=2)+"\n")
