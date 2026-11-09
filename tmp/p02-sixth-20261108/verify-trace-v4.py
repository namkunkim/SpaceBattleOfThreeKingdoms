from copy import deepcopy
from pathlib import Path
import hashlib,json,sys
D=Path(__file__).resolve().parent
PROOF=D/"trace-oracle-v4.json"
def read(path): return json.loads(path.read_bytes())
def norm(row):
 return {k:v for k,v in row.items() if k not in ("wall_time","mono_ms")}
pre=read(PROOF)
for path,sha in pre["sources"].items():
 assert hashlib.sha256((D/path).read_bytes()).hexdigest()==sha,path
proof=D/sys.argv[1]/"atomic"
observed=read(proof/"result.json")["recover_publish_once"]["value"]
user=proof/"roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms"
def trace(key):
 path=observed[key]
 assert path.startswith("user://battle_traces/")
 return [json.loads(x) for x in (user/path.removeprefix("user://")).read_bytes().splitlines()]
start=trace("start_file")
close=trace("close_file")
assert len(start)==1
assert observed["start"]==start[0] and observed["close"]==close[-1]
assert norm(start[0])==pre["start"] and norm(close[-1])==pre["close"]
for field,value in [("control","bad_probe_control"),("pos",[123456,654321])]:
 changed=deepcopy(start[0])
 changed["data"]["fleet_state"][0][field]=value
 assert norm(changed)!=pre["start"],field
out={"start":norm(start[0]),"close":norm(close[-1]),"mutation_rejected":["control","pos"]}
(proof/"trace-compare.json").write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
print("trace comparison passed")
