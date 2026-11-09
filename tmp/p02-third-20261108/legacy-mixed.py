from pathlib import Path
import hashlib, json, subprocess
p=Path("tmp/p02-third-20261108")
o=p/"legacy-mixed"
o.mkdir()
backup=o/"autoresolve.before.gd"
backup.write_bytes((p/"autoresolve.before.txt").read_bytes())
source=Path("tests/autoresolve.gd")
cache=Path(".godot/global_script_class_cache.cfg")
exe=Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
fixture=Path("tests/fixtures/p02/worker-poc.json")
files=[backup,source,cache,exe,fixture]
def hashes(): return {str(f):hashlib.sha256(f.read_bytes()).hexdigest() for f in files}
before=hashes()
rows={}
output=o/"mixed.absent.json"
for label,script in (("before",backup),("after",source)):
 cmd=[str(exe),"--headless","--path",".","--log-file",str(o/(label+".engine.log")),"-s",str(script),"--","--operation-worker",str(fixture),"--operation-input",str(fixture),"--out",str(output)]
 r=subprocess.run(cmd,capture_output=True,timeout=30)
 (o/(label+".stdout")).write_bytes(r.stdout)
 (o/(label+".stderr")).write_bytes(r.stderr)
 rows[label]={"command":cmd,"exit":r.returncode,"new_output":output.exists()}
good=hashes()==before and all(row["exit"]==1 and not row["new_output"] for row in rows.values()) and all((o/("before."+x)).read_bytes()==(o/("after."+x)).read_bytes() for x in ["stdout","stderr"]) and b'"path":"--operation-input"' in (o/"after.stdout").read_bytes()
(o/"results.json").write_text(json.dumps({"files":before,"results":rows,"pass":good},indent=2))
print(good)
