from pathlib import Path
import concurrent.futures, hashlib, json, os, shutil, subprocess, sys
R=Path.cwd()
D=Path(__file__).resolve().parent
REL=D.relative_to(R).as_posix()
E=Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
ENGINE="c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643"
CACHE=".godot/global_script_class_cache.cfg"
CLASS="0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1"
PRODUCT=["scripts/FleetBattle3D.gd","hud/ui_kit/command_deck.gd","hud/ui_kit/org_screen.gd"]
SUITES={"common":REL+"/product-host-common-v2.gd","battle-flow":"tests/battle_flow.gd",
 "world-clean":REL+"/world-probe.gd","world-returning":REL+"/world-probe.gd","organization":"tests/organization_ui.gd"}
ATOMIC=REL+"/product-host-atomic-v4.gd"
def sha(p):
 with p.open("rb") as f: return hashlib.file_digest(f,"sha256").hexdigest()
def rec(p):
 if p.is_file(): return {"bytes":p.stat().st_size,"sha256":sha(p)}
def git(*args):
 return subprocess.check_output(["git",*args],env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
def paths(*args):
 return {p for p in git("ls-files","-z",*args).decode().split("\0") if p and not p.startswith(REL+"/")}
def record_set(root,paths):
 with concurrent.futures.ThreadPoolExecutor(8) as pool:
  return dict(zip(paths,pool.map(lambda p:rec(root/p),paths)))
def dump(p,data): p.write_text(json.dumps(data,indent=2,ensure_ascii=False),encoding="utf8")
def read(p): return json.loads(p.read_bytes())
def metadata():
 return {"index":rec(R/".git/index"),"head":git("rev-parse","HEAD").decode().strip(),
  "branch":git("branch","--show-current").decode().strip(),
  "stage":hashlib.sha256(git("ls-files","--stage","-z")).hexdigest()}
def workspace(file):
 first=metadata()
 original=read(D/"baseline.json")
 a=paths("--cached")
 b=paths("--others","--exclude-standard")
 inv=record_set(R,sorted(a|b))
 drift={p:{"was":original["paths"].get(p),"now":inv.get(p)} for p in sorted(set(inv)|set(original["paths"])) if inv.get(p)!=({k:v for k,v in original["paths"][p].items() if k in ("bytes","sha256")} if p in original["paths"] else None)}
 assert first==metadata()
 list_delta=sorted((a ^ paths("--cached")) | (b ^ paths("--others","--exclude-standard")))
 assert first["head"]==original["before"]["head"] and first["branch"]==original["before"]["branch"]
 assert first["index"]["sha256"]==original["before"]["index"]["sha256"]
 assert first["stage"]==original["before"]["stage_sha256"]
 dump(file,{"tracked":len(a),"untracked":len(b),"meta":first,"drift":drift,"list_drift":list_delta})
 assert not any(not p.startswith("tmp/p03-") for p in list_delta), list_delta
 return drift
def prepare():
 workspace(D/"precopy-workspace.json")
 paths=set()
 for name in ["assets","core","data","hud","input","scenes","scripts","tests","view",".godot/imported"]:
  paths.update(p.relative_to(R).as_posix() for p in (R/name).rglob("*") if p.is_file())
 paths.update(["project.godot",CACHE,".godot/uid_cache.bin",".godot/scene_groups_cache.cfg",*SUITES.values(),ATOMIC])
 paths=sorted(paths)
 before=record_set(R,paths)
 assert all(before.values())
 for name in PRODUCT:
  assert before[name]["sha256"]==read(D/"baseline.json")["paths"][name]["sha256"]
  (D/(Path(name).name+".before.txt")).write_bytes((R/name).read_bytes())
 for stage in ["before","after"]:
  root=D/("project-"+stage)
  root.mkdir()
  for name in paths:
   dest=root/name
   dest.parent.mkdir(parents=True,exist_ok=True)
   shutil.copyfile(R/name,dest)
  assert record_set(root,paths)==before
 assert record_set(R,paths)==before
 dump(D/"frozen-inputs.json",before)
 dump(D/"proof-files.json",record_set(R,[REL+"/"+name for name in ["PLAN-v2.md","REVIEW-PLAN-V2-INDEPENDENT.md","run.py","returning-settings.cfg"]]))
 assert sha(E)==ENGINE and sha(R/CACHE)==CLASS
 (D/"engine-actual.txt").write_bytes(subprocess.check_output([str(E),"--version"]))
def run(stage, label):
 root=D/("project-"+stage)
 evidence=D/label
 evidence.mkdir()
 workspace(evidence/"workspace-pre.json")
 expected=read(D/"frozen-inputs-v4.json")
 assert record_set(R,sorted(read(D/"proof-files-v4.json")))==read(D/"proof-files-v4.json")
 if stage=="after":
  for name in PRODUCT:
   expected[name]=rec(R/name)
   shutil.copyfile(R/name,root/name)
 assert sha(E)==ENGINE and sha(root/CACHE)==CLASS
 assert record_set(R,sorted(expected))==expected
 assert record_set(root,sorted(expected))==expected
 dump(evidence/"inputs.json",expected)
 suites=dict(SUITES)
 if stage=="after": suites["atomic"]=ATOMIC
 def execute(item):
  name,script=item
  out=evidence/name
  out.mkdir()
  roam=out/"roaming"
  local=out/"local"
  user=roam/"Godot/app_userdata/SpaceBattleOfThreeKingdoms"
  user.mkdir(parents=True)
  local.mkdir()
  if name=="world-returning": shutil.copyfile(D/"returning-settings.cfg",user/"settings.cfg")
  env={"APPDATA":str(roam),"LOCALAPPDATA":str(local),"XDG_DATA_HOME":str(roam)}
  args=[str(E),"--headless","--path",str(root),"--script","res://"+script,"--",str(out/"result.json")]
  dump(out/"command.json",{"args":args,"env":env,"initial":{x.name:rec(x) for x in user.iterdir()}})
  try:
   x=subprocess.run(args,env={**os.environ,**env},capture_output=True,timeout=240)
   stdout,stderr,exitcode,timeout=x.stdout,x.stderr,x.returncode,False
  except subprocess.TimeoutExpired as x: stdout,stderr,exitcode,timeout=x.stdout or b"",x.stderr or b"",None,True
  (out/"stdout").write_bytes(stdout)
  (out/"stderr").write_bytes(stderr)
  dump(out/"process.json",{"exit":exitcode,"timeout":timeout,"stdout":rec(out/"stdout"),"stderr":rec(out/"stderr"),"result":rec(out/"result.json")})
  return name,exitcode,timeout
 with concurrent.futures.ThreadPoolExecutor(6) as pool: results=list(pool.map(execute,suites.items()))
 dump(evidence/"processes.json",results)
 assert record_set(root,sorted(expected))==expected and record_set(R,sorted(expected))==expected and sha(E)==ENGINE
 workspace(evidence/"workspace-post.json")
 print(results)
if sys.argv[1]=="prepare":
 original=read(D/"frozen-inputs-v2.json")
 expected=dict(original)
 for name in PRODUCT: expected[name]=rec(R/name)
 assert record_set(R,sorted(expected))==expected
 assert record_set(D/"project-before",sorted(original))==original
 root=D/"project-after"
 assert record_set(root,sorted(expected))==expected
 shutil.copyfile(R/ATOMIC,root/ATOMIC)
 original[ATOMIC]=rec(R/ATOMIC)
 dump(D/"frozen-inputs-v4.json",original)
 proof=[REL+"/"+name for name in ["PLAN-v2.md","REVIEW-PLAN-V2-INDEPENDENT.md","run-v4.py","returning-settings.cfg","native-oracle.json","trace-oracle-v4.json","verify-trace-v4.py"]]
 proof += [REL+"/"+name for name in read(D/"trace-oracle-v4.json")["sources"]]
 dump(D/"proof-files-v4.json",record_set(R,proof))
else: run(*sys.argv[1:])
