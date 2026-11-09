from pathlib import Path
import hashlib,json,os,subprocess
from concurrent.futures import ThreadPoolExecutor
D=Path(__file__).resolve().parent
E=Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
inputs=json.loads((D/"frozen-inputs-v2.json").read_bytes())
after=json.loads((D/"after-attempt-01/inputs.json").read_bytes())
assert hashlib.file_digest(E.open("rb"),"sha256").hexdigest()=="c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643"
def run(row):
 stage,name,script=row
 project=D/("project-"+stage)
 for name2 in ["scripts/FleetBattle3D.gd","hud/ui_kit/org_screen.gd","hud/ui_kit/command_deck.gd",".godot/global_script_class_cache.cfg",script]:
  assert hashlib.file_digest((project/name2).open("rb"),"sha256").hexdigest()==(inputs if stage=="before" else after)[name2]["sha256"]
 out=D/"leak-verbose-diagnostics"/stage/name
 out.mkdir(parents=True)
 roam=out/"roaming"
 local=out/"local"
 roam.mkdir()
 local.mkdir()
 env={"APPDATA":str(roam),"LOCALAPPDATA":str(local),"XDG_DATA_HOME":str(roam)}
 args=[str(E),"--headless","--verbose","--path",str(project),"--script","res://"+script,"--",str(out/"result.json")]
 x=subprocess.run(args,env={**os.environ,**env},capture_output=True,timeout=240)
 (out/"stdout").write_bytes(x.stdout)
 (out/"stderr").write_bytes(x.stderr)
 (out/"process.json").write_text(json.dumps({"args":args,"env":env,"exit":x.returncode},indent=2),encoding="utf8")
 print(stage,name,x.returncode,flush=True)
suites={"common":"tmp/p02-sixth-20261108/product-host-common-v2.gd","organization":"tests/organization_ui.gd"}
with ThreadPoolExecutor(2) as pool:
 for _ in pool.map(run,[(s,n,p) for n,p in suites.items() for s in ["before","after"]]): pass
