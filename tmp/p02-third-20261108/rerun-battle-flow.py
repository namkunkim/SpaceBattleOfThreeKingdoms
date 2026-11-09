from pathlib import Path
import hashlib, json, subprocess, sys
root=Path.cwd()
e=root/"tmp/p02-third-20261108"
previous=e/"attempt2"
out=e/"attempt3"
out.mkdir()
def load(path):
 return json.loads(path.read_text(encoding="utf8"))
def sha(path):
 return hashlib.sha256(path.read_bytes()).hexdigest()
def dump(path,data):
 path.write_text(json.dumps(data,indent=2)+"\n",encoding="utf8")
baseline=load(previous/"freeze.json")
prior=load(previous/"results.json")
failed=[case["label"] for case in prior["cases"] if not case["pass_process"]]
assert failed==["battle-flow"] and all(c["passed"] for c in prior["comparisons"])
history=root/"tmp/i01b-followup-20261028/logs/battle_flow-output.log"
files={**baseline["files"],str(previous/"results.json"):sha(previous/"results.json"),str(previous/"freeze.json"):sha(previous/"freeze.json"),str(Path(__file__).resolve()):sha(Path(__file__))}
def stable():
 return all(sha(Path(p))==value for p,value in files.items())
assert stable()
job=next(row for row in baseline["jobs"] if row["label"]=="battle-flow")
cmd=job["command"][:]
cmd[cmd.index("--log-file")+1]=str(out/"battle-flow.engine.log")
dump(out/"freeze.json",{"files":files,"version":baseline["version"],"job":cmd})
result=subprocess.run(cmd,capture_output=True,timeout=90)
(out/"battle-flow.stdout").write_bytes(result.stdout)
(out/"battle-flow.stderr").write_bytes(result.stderr)
history_lines=history.read_bytes().splitlines()
historical_exit=history_lines[history_lines.index(b"BATTLE_FLOW_PASS")+1:]
assert len(historical_exit)==4 and historical_exit[0].startswith(b"WARNING: 153 ObjectDB") and historical_exit[2].startswith(b"ERROR: 18 resources")
expected_stderr=result.stderr.splitlines()==historical_exit
matched_prior=result.stderr==(previous/"battle-flow.stderr").read_bytes()
diagnostics={flag:sum(line.startswith(flag.encode()+b":") for line in (result.stdout+result.stderr).splitlines()) for flag in ["SCRIPT ERROR","ERROR","WARNING"]}
passed=result.returncode==0 and b"BATTLE_FLOW_PASS" in result.stdout.splitlines() and diagnostics=={"SCRIPT ERROR":0,"ERROR":1,"WARNING":1} and expected_stderr and matched_prior and stable()
dump(out/"results.json",{"passed":passed,"processes":1,"exit":result.returncode,"historical_exit_lines_match":expected_stderr,"attempt2_stderr_bytes_match":matched_prior,"diagnostics":diagnostics,"hash_stability":stable(),"validated_attempt2_processes":len(prior["cases"])-1,"validated_attempt2_comparisons":len(prior["comparisons"]),"k6_total_actual_processes":74+75+1})
print(passed, result.returncode,diagnostics,expected_stderr,matched_prior)
sys.exit(0 if passed else 1)
