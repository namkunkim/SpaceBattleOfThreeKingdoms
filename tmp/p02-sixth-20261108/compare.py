from pathlib import Path
import hashlib, json, re, sys
D=Path(__file__).resolve().parent
PRE=D/"before-attempt-03"
FROZEN=D/"native-oracle.json"
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def inspect(folder):
 results={}
 for p in sorted(folder.glob("*/process.json")):
  suite=p.parent.name
  out=(p.parent/"stdout").read_text(encoding="utf8",errors="replace")
  err=(p.parent/"stderr").read_text(encoding="utf8",errors="replace")
  actual=json.loads(p.read_bytes())
  marker={"common":"SIXTH_COMMON rows=8","atomic":"SIXTH_ATOMIC rows=10","organization":"ORGANIZATION_UI_PASS","battle-flow":"BATTLE_FLOW_PASS","world-clean":"WORLD_LINK_FAIL 1","world-returning":"WORLD_LINK_PASS"}[suite]
  diagnostics=[line for line in err.splitlines() if line.startswith(("ERROR:", "SCRIPT ERROR:", "WARNING:"))]
  leaks=[line for line in diagnostics if "leaked at exit" in line or "resources still in use" in line]
  diagnostics=[line for line in diagnostics if line not in leaks]
  expected={"world-clean":["ERROR: TEST_FAIL 천하에서 오면 브리핑부터 (prologue)"],
    "organization":["ERROR: 알 수 없는 난이도: 없는 난이도"]*2+
      ["ERROR: 시나리오를 읽지 못해 시험 전장으로 엽니다 (res://data/profiles/red_cliffs_rt.json, 없는 난이도)"],
    "common":["ERROR: 프로필 파일이 없다: res://data/profiles/p02_sixth_missing.json"]*2+
      ["ERROR: 시나리오를 읽지 못해 시험 전장으로 엽니다 (res://data/profiles/p02_sixth_missing.json, 표준)"],
    "atomic":["ERROR: [FleetBattle3D] invalid_candidate_profile at profile"]*9+
      ["ERROR: [FleetBattle3D] invalid_candidate_profile at profile.ally"]}.get(suite,[])
  good=(actual["exit"]==(1 if suite=="world-clean" else 0) and not actual["timeout"]
    and marker in out and sorted(expected)==sorted(diagnostics))
  if suite=="world-clean": good=good and "(res://tests/world_link.gd:239)" in err
  if suite.startswith("world-"):
   entry=json.loads(next(line[len("SIXTH_USER "):] for line in out.splitlines() if line.startswith("SIXTH_USER ")))
   good=good and entry["settings"]==("" if suite=="world-clean" else sha(D/"returning-settings.cfg"))
   good=good and Path(entry["dir"]).resolve().is_relative_to(p.parent.resolve())
  results[suite]={"pass":good,"exit":actual["exit"],"timeout":actual["timeout"],"diagnostics":diagnostics,"leaks":leaks,"marker":next((s for s in out.splitlines() if marker in s),None)}
 return results
def dump(path,value):
 assert not path.exists(), path
 path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
if sys.argv[1]=="freeze":
 results=inspect(PRE)
 assert len(results)==5 and all(r["pass"] for r in results.values()),results
 input_proof=PRE/"common/result.json"
 baseline={"common":sha(input_proof),"processes":sha(PRE/"processes.json"),"suite_evidence":results,
  "inputs":sha(PRE/"inputs.json"),"workspace_after":sha(PRE/"workspace-post.json")}
 dump(FROZEN,baseline)
else:
 post=D/sys.argv[1]
 results=inspect(post)
 pre_proof=json.loads(FROZEN.read_bytes())
 assert sha(PRE/"common/result.json")==pre_proof["common"]
 left=json.loads((PRE/"common/result.json").read_bytes())
 right=json.loads((post/"common/result.json").read_bytes())
 differences=[name for name in set(left)|set(right) if left.get(name)!=right.get(name)]
 accepted=len(results)==6 and all(r["pass"] for r in results.values()) and not differences
 dump(post/"comparison.json",{"accepted":accepted,"processes":results,"common_differences":differences})
 print("accepted",accepted,"common differences",differences)
 sys.exit(0 if accepted else 1)
