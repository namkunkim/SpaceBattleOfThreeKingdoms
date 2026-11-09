from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import hashlib,json,os,subprocess
R=Path.cwd()
D=Path(__file__).resolve().parent
E=Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
EXE=E.with_name(E.name.replace("_console",""))
CACHE=".godot/global_script_class_cache.cfg"
PRODUCT="scripts/FleetBattle3D.gd"
PLAN="6f1e0a2c53d7cee1f7e34dbfdb279c9ba29fa6ed30dbd809f68cb00fb0f9570a"
PROBE=D/"fixed-trace-probe.gd"
P=D/"fixed-trace-attempt-03"
P.mkdir()
def h(path):
 with path.open("rb") as f:return hashlib.file_digest(f,"sha256").hexdigest()
def read(path):return json.loads(path.read_bytes())
def dump(path,value):path.write_text(json.dumps(value,indent=2,ensure_ascii=False),encoding="utf8")
def verify(root,manifest):
 with ThreadPoolExecutor(8) as pool: return dict(zip(manifest,pool.map(lambda n:h(root/n),manifest)))
def metadata():
 env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"}
 def git(*a):return subprocess.check_output(["git",*a],env=env)
 return {"head":git("rev-parse","HEAD").decode().strip(),"branch":git("branch","--show-current").decode().strip(),"stage":hashlib.sha256(git("ls-files","--stage","-z")).hexdigest(),"index":h(R/".git/index"),"staged_hex":git("diff","--cached","--raw","-z").hex()}
base=read(D/"baseline.json")
source=read(D/"after-attempt-02/inputs.json")
canon={str(f):h(f) for f in [E,EXE,R/CACHE,R/PRODUCT,PROBE,Path(__file__).resolve(),D/"PLAN-v3.md",D/"REVIEW-PLAN-V3-INDEPENDENT.md"]}
assert canon[str(E)]==base["engine"]["sha256"] and canon[str(EXE)]=="ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424"
assert canon[str(R/CACHE)]==base["classcache"]["sha256"] and canon[str(D/"PLAN-v3.md")]==PLAN
assert canon[str(R/PRODUCT)]==source[PRODUCT]
head=metadata()
assert head=={"head":base["before"]["head"],"branch":base["before"]["branch"],"stage":base["before"]["stage_sha256"],"index":base["before"]["index"]["sha256"],"staged_hex":base["before"]["staged_hex"]}
assert verify(R,source)==source
dump(P/"canonical-before.json",{"files":canon,"git":head,"source":source})
def execute(stage,replica,manifest_path):
 out=P/stage
 out.mkdir()
 root=D/replica
 manifest=read(D/manifest_path)
 assert set(manifest)^set(source) in (set(),{"tmp/p02-seventh-20261108/run-v2.py"})
 assert all(digest==source[n] for n,digest in manifest.items() if n!=PRODUCT)
 a=verify(root,manifest)
 assert a==manifest
 dump(out/"inputs-before.json",a)
 roam=out/"roaming"; local=out/"local"
 user=roam/"Godot/app_userdata/SpaceBattleOfThreeKingdoms"
 user.mkdir(parents=True);local.mkdir()
 env=dict(APPDATA=str(roam),LOCALAPPDATA=str(local),XDG_DATA_HOME=str(roam))
 args=[str(E),"--headless","--path",str(root),"--script",str(PROBE),"--",str(out/"result.json")]
 dump(out/"command.json",{"args":args,"env":env,"manifest_sha256":h(D/manifest_path)})
 try:
  x=subprocess.run(args,capture_output=True,env={**os.environ,**env},timeout=100)
  code,stdout,stderr=x.returncode,x.stdout,x.stderr
 except subprocess.TimeoutExpired as x:code,stdout,stderr=None,x.stdout or b"",x.stderr or b""
 (out/"stdout").write_bytes(stdout)
 (out/"stderr").write_bytes(stderr)
 after=verify(root,manifest)
 dump(out/"inputs-after.json",after)
 dump(out/"process.json",{"exit":code,"timeout":code is None,"inputs_unchanged":a==after})
 assert code==0 and a==after
 result=read(out/"result.json")
 raw=Path(result["trace"]); initial=Path(result["initial_trace"])
 assert raw!=initial and all(f.is_relative_to(user) for f in (raw,initial))
 (out/"fixed-session-start.jsonl").write_bytes(raw.read_bytes())
 (out/"startup-and-close.jsonl").write_bytes(initial.read_bytes())
 rows=[json.loads(l) for l in raw.read_bytes().splitlines()]
 assert len(rows)==1 and rows[0]["seq"]==1 and rows[0]["kind"]=="session_start"
 assert rows[0]["data"]["seed"]==result["seed"]==27182818
 assert result["message"]=="시나리오를 읽지 못해 시험 전장으로 엽니다" and not result["routed"] and result["result"]=={"ok":True}
 assert result["path"]==rows[0]["data"]["profile_path"]=="res://data/profiles/p02_sixth_missing.json"
 errors=[l for l in stderr.decode("utf8").splitlines() if l.startswith(("ERROR:","WARNING:","SCRIPT ERROR:"))]
 expected=["ERROR: 프로필 파일이 없다: res://data/profiles/p02_sixth_missing.json"]*4+["ERROR: 시나리오를 읽지 못해 시험 전장으로 엽니다 (res://data/profiles/p02_sixth_missing.json, 표준)"]*2
 termination=[l for l in errors if "leaked at exit" in l or "resources still in use at exit" in l]
 dump(out/"diagnostics.json",{"engine":errors,"termination":termination})
 assert sorted(l for l in errors if l not in termination)==sorted(expected), errors
 return rows[0],{k:v for k,v in result.items() if k not in ("initial_trace","trace","pid")}
b,bo=execute("before","project-before","before-attempt-01/inputs.json")
a,ao=execute("after","project-after-02","after-attempt-02/inputs.json")
def norm(r):return {k:v for k,v in r.items() if k not in ("wall_time","mono_ms")}
assert bo==ao and norm(b)==norm(a)
for key,value in [("control","wrong-control"),("pos",[123456,654321])]:
 bad=deepcopy(a)
 bad["data"]["fleet_state"][0][key]=value
 assert norm(bad)!=norm(b),key
assert verify(R,source)==source and metadata()==head
assert {f:h(Path(f)) for f in canon}==canon
dump(P/"canonical-after.json",{"files":canon,"git":head,"source":source})
dump(P/"comparison.json",{"strict_equal":True,"ignored":["wall_time","mono_ms"],"fixed_row":norm(a),"mutation_rejected":["control","pos"],"result_equal":True,"startup_original_strict_equal":False,"startup_original_matched":7,"startup_original_total":8})
print("fixed trace 1/1; full row and applied rosters equal, mutations rejected")
