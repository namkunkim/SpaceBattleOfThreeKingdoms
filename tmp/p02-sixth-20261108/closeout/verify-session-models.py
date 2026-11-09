import json
from pathlib import Path
d=Path(__file__).resolve().parent
sessions=Path("C:/Users/nk782/.codex/sessions")
spec={
"implementation":("01a1ba05-cd2b-7da3-a1c7-cf0a5345c256","/root/p02_sixth_impl","01a1ba05-ce57-7e40-810f-c7689a6a009b"),
"independent_5b":("01a1ba00-0c5a-7692-a145-6d5c68e5dd4f","/root/p02_sixth_review","01a1ba15-9f16-7692-9e5a-81c6ecaa45bb")}
out={}
for role,(session,agent,turn) in spec.items():
 file,=sessions.rglob("*"+session+".jsonl")
 meta=None
 context=None
 with file.open(encoding="utf8") as f:
  for number,line in enumerate(f,1):
   try: row=json.loads(line)
   except ValueError: continue
   p=row.get("payload",{})
   if row["type"]=="session_meta" and p.get("id")==session:
    meta=(number,p["source"]["subagent"]["thread_spawn"])
   if row["type"]=="turn_context" and p.get("turn_id")==turn:
    context=(number,p["model"],row["timestamp"])
 assert meta and context and meta[1]["agent_path"]==agent and context[1] in ("gpt-6.1-sol","gpt-6.1-terra")
 out[role]={"session":session,"agent_path":agent,"nickname":meta[1]["agent_nickname"],"turn":turn,
  "actual_model":context[1],"turn_utc":context[2],"source":file.relative_to(sessions).as_posix(),"session_meta_line":meta[0],"turn_context_line":context[0]}
assert out["implementation"]["actual_model"]!=out["independent_5b"]["actual_model"]
(d/"session-models.json").write_text(json.dumps(out,indent=2)+"\n",encoding="utf8")
