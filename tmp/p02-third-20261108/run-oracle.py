import hashlib, json, pathlib, subprocess
r=pathlib.Path("tmp/p02-third-20261108")
exe=pathlib.Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
paths=[str(p) for p in [exe,pathlib.Path(".godot/global_script_class_cache.cfg"),pathlib.Path("project.godot"),r/"oracle.gd",*pathlib.Path("core").rglob("*.gd"),*pathlib.Path("data").rglob("*.json"),*pathlib.Path("tests/fixtures/p02").glob("*.json")]]
def sha():
 return {p:hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest() for p in paths}
before=sha()
cmd=[str(exe),"--headless","--path",".","--log-file",str(r/"oracle.engine.log"),"-s",str(r/"oracle.gd")]
(r/"oracle-freeze.json").write_text(json.dumps(dict(command=cmd,files=before),indent=2))
x=subprocess.run(cmd,capture_output=True,timeout=60)
(r/"oracle.stdout").write_bytes(x.stdout)
(r/"oracle.stderr").write_bytes(x.stderr)
(r/"oracle-verdict.json").write_text(json.dumps(dict(exit=x.returncode,stable=sha()==before)))
print(x.returncode,sha()==before)
