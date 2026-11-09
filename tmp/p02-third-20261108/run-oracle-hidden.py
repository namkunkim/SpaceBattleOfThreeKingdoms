from pathlib import Path
import hashlib,json,subprocess
p=Path("tmp/p02-third-20261108")
base=json.loads((p/"oracle-freeze.json").read_text())
files={k:v for k,v in base["files"].items() if not k.endswith("oracle.gd")}
for f in [p/"oracle.gd",p/"oracle-hidden.gd"]:
 files[str(f)]=hashlib.sha256(f.read_bytes()).hexdigest()
def stable():
 return all(hashlib.sha256(Path(f).read_bytes()).hexdigest()==h for f,h in files.items())
assert stable()
cmd=[base["command"][0],"--headless","--path",".","--log-file",str(p/"oracle-hidden.engine.log"),"-s",str(p/"oracle-hidden.gd")]
(p/"oracle-hidden-freeze.json").write_text(json.dumps({"files":files,"command":cmd},indent=2))
r=subprocess.run(cmd,capture_output=True,timeout=60)
(p/"oracle-hidden.stdout").write_bytes(r.stdout)
(p/"oracle-hidden.stderr").write_bytes(r.stderr)
(p/"oracle-hidden-verdict.json").write_text(json.dumps({"exit":r.returncode,"stable":stable()}))
print(r.returncode,stable(),r.stdout.decode(),r.stderr.decode())
