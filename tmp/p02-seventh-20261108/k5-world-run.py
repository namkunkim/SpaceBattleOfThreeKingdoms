from pathlib import Path
import concurrent.futures as cf, hashlib, json, os, subprocess
D=Path(__file__).resolve().parent
R=Path.cwd(); K4=D/'k4-current'; P=D/'k5-world-retry'
P.mkdir()
PROBE=D/'k5-world-product.gd'
C='.godot/global_script_class_cache.cfg'
E=Path('C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe')
EXE=E.with_name(E.name.replace('_console',''))
CFG=R/'tmp/p02-sixth-20261108/returning-settings.cfg'
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(p):return json.loads(p.read_bytes())
def dump(p,o):p.write_text(json.dumps(o,indent=2,ensure_ascii=False),encoding='utf8')
def scan(root,expected):
 with cf.ThreadPoolExecutor(8) as pool:return dict(zip(expected,pool.map(lambda n:sha(root/n),expected)))
pre=read(K4/'preflight.json')
proof={str(p):sha(p) for p in [E,EXE,R/C,PROBE,CFG,Path(__file__).resolve(),D/'PLAN-v5.md',D/'REVIEW-PLAN-V5-INDEPENDENT.md']}
assert [proof[str(p)] for p in (E,EXE,R/C)]==[pre['engines'][str(E)],pre['engines'][str(EXE)],pre['engines'][C]]
assert scan(R,pre['inputs'])==pre['inputs']
cases=[(s,l) for s in ('before','after') for l in ('complete','cancel')]
dump(P/'preflight.json',{'hashes':proof,'cases':cases,'replicas':{s:sha(K4/(s+'-inputs.json')) for s in ('before','after')}})
def run(s,l):
 expected=read(K4/(s+'-inputs.json'));root=K4/s
 assert scan(root,expected)==expected
 out=P/(s+'-'+l);out.mkdir()
 roam=out/'roaming';local=out/'local';user=roam/'Godot/app_userdata/SpaceBattleOfThreeKingdoms'
 user.mkdir(parents=True);local.mkdir()
 (user/'settings.cfg').write_bytes(CFG.read_bytes())
 env=dict(APPDATA=str(roam),LOCALAPPDATA=str(local),XDG_DATA_HOME=str(roam))
 args=[str(E),'--headless','--path',str(root),'--script',str(PROBE),'--',l,str(out/'result.json')]
 dump(out/'command.json',{'args':args,'env':env,'returning_settings_sha256':sha(user/'settings.cfg')})
 try:
  x=subprocess.run(args,capture_output=True,env={**os.environ,**env},timeout=220)
  rc,stdout,stderr=x.returncode,x.stdout,x.stderr
 except subprocess.TimeoutExpired as x:rc,stdout,stderr=None,x.stdout or b'',x.stderr or b''
 (out/'stdout').write_bytes(stdout);(out/'stderr').write_bytes(stderr)
 stable=scan(root,expected)==expected
 dump(out/'process.json',{'exit':rc,'timeout':rc is None,'inputs_unchanged':stable})
 print(s,l,rc,stable,flush=True)
 return s,l,rc,stable
with cf.ThreadPoolExecutor(4) as e:
 runs=list(e.map(lambda c:run(*c),cases))
assert scan(R,pre['inputs'])==pre['inputs']
assert {p:sha(Path(p)) for p in proof}==proof
dump(P/'processes.json',runs)
