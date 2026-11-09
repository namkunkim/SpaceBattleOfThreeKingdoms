from pathlib import Path
import ast,hashlib, json, os, subprocess
D=Path(__file__).resolve().parent
tree=ast.parse((D/'k4-run.py').read_text(encoding='utf-8-sig'))
tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
exec(compile(tree,str(D/'k4-run.py'),'exec'))
K4=P
P=D/'k6-worldlink-retry';P.mkdir()
frozen=read(K4/'preflight.json')
runs=[(s,l) for s in ('before','after') for l in ('clean','returning')]
proof={rel(f):sha(f) for f in [Path(__file__).resolve(),D/'PLAN-v5.md',D/'REVIEW-PLAN-V5-INDEPENDENT.md',OLD/'world-probe.gd',OLD/'returning-settings.cfg']}
dump(P/'preflight.json',{'runs':runs,'mode':'serial','timeout_s':320,'same_engine_inputs':frozen['engines'],'files':proof,'replica_manifest':{s:sha(K4/(s+'-inputs.json')) for s in ('before','after')}})
def verify_all(root,expected):
 return scan(root,expected)==expected and scan(R,frozen['inputs'])==frozen['inputs'] and engines()==frozen['engines'] and meta()==frozen['git'] and all(sha(R/f)==h for f,h in proof.items())
results=[]
for stage,lane in runs:
 out=P/(stage+'-'+lane);out.mkdir()
 root=K4/stage
 expected=read(K4/(stage+'-inputs.json'))
 assert verify_all(root,expected)
 roam=out/'roaming';local=out/'local';user=roam/'Godot/app_userdata/SpaceBattleOfThreeKingdoms'
 user.mkdir(parents=True);local.mkdir()
 if lane=='returning':shutil.copyfile(OLD/'returning-settings.cfg',user/'settings.cfg')
 env=dict(APPDATA=str(roam),LOCALAPPDATA=str(local),XDG_DATA_HOME=str(roam))
 args=[str(E),'--headless','--path',str(root),'--script','res://'+rel(OLD/'world-probe.gd'),'--',str(out/'result.json')]
 dump(out/'command.json',{'args':args,'env':env,'expected_exit':1 if lane=='clean' else 0})
 try:
  x=subprocess.run(args,env={**os.environ,**env},capture_output=True,timeout=320)
  code,stdout,stderr=x.returncode,x.stdout,x.stderr
 except subprocess.TimeoutExpired as x:code,stdout,stderr=None,x.stdout or b'',x.stderr or b''
 (out/'stdout').write_bytes(stdout);(out/'stderr').write_bytes(stderr)
 stable=verify_all(root,expected)
 lines=[l for l in stderr.decode('utf8',errors='replace').splitlines() if l.startswith(('ERROR:','SCRIPT ERROR:','WARNING:'))]
 nontermination=[l for l in lines if 'leaked at exit' not in l and 'resources still in use at exit' not in l]
 wanted=['ERROR: TEST_FAIL 천하에서 오면 브리핑부터 (prologue)'] if lane=='clean' else []
 marker='WORLD_LINK_FAIL 1' if lane=='clean' else 'WORLD_LINK_PASS'
 ok=stable and code==(1 if lane=='clean' else 0) and nontermination==wanted and marker in stdout.decode('utf8',errors='replace')
 entry={'stage':stage,'lane':lane,'exit':code,'timeout':code is None,'inputs_unchanged':stable,'expected_result':ok,'diagnostics':lines}
 dump(out/'process.json',entry)
 results.append(entry)
 dump(P/'processes.json',results)
 print(stage,lane,code,stable,ok,flush=True)
 if not ok:
  raise SystemExit(1)
