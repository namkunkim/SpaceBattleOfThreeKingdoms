from pathlib import Path
import concurrent.futures as cf, hashlib, json, subprocess
e=Path("tmp/p02-third-20261108")
out=e/"before-supplemental"
out.mkdir()
base=json.loads((e/"before/freeze.json").read_text(encoding="utf8"))
paths={k:v for k,v in base["files"].items() if "gate.py" not in k}
def unchanged():
 return all(hashlib.sha256(Path(p).read_bytes()).hexdigest()==v for p,v in paths.items())
assert unchanged()
jobs=[("worker-poc","--operation-worker","worker-poc"),("worker-services","--operation-worker","worker-services"),("sync-worker-services","--operation-input","worker-services")]
def run(t):
 label, opt, name=t
 cmd=["C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe","--headless","--path",".","--log-file",str(out/(label+".engine.log")),"-s","tests/autoresolve.gd","--",opt,"tests/fixtures/p02/"+name+".json","--out",str(out/(label+".json"))]
 r=subprocess.run(cmd,capture_output=True,timeout=60)
 (out/(label+".stdout")).write_bytes(r.stdout)
 (out/(label+".stderr")).write_bytes(r.stderr)
 return {"command":cmd,"exit":r.returncode,"stderr_bytes":len(r.stderr)}
with cf.ThreadPoolExecutor(3) as pool:
 results=list(pool.map(run,jobs))
(out/"results.json").write_text(json.dumps({"jobs":results,"stable":unchanged()},indent=2))
print(results,unchanged())
