from stage import *
import sys
from concurrent.futures import as_completed
K=D/sys.argv[1]
K.mkdir()
probes={'native':D/'native-probe.gd',
 'world-complete':R/'tmp/p02-seventh-20261108/k4-world-product.gd',
 'world-cancel':R/'tmp/p02-seventh-20261108/k4-world-product.gd',
 'world-clean':R/'tmp/p02-sixth-20261108/world-probe.gd',
 'world-returning':R/'tmp/p02-sixth-20261108/world-probe.gd'}
tests=['battle_flow','autoresolve','p02_headless_adapter','p02_worker_adapter','p02_replay_adapter','p02_viewer_events','i01b_private_state','i01b_service_state','i01b_active_replace']
cfg=R/'tmp/p02-sixth-20261108/returning-settings.cfg'
source=json.loads((T/'source.json').read_bytes())
after=json.loads((T/'after.json').read_bytes())
plans={p.name:sha(p) for p in [D/'PLAN.md',D/'PLAN-v2.md',D/'REVIEW-PLAN-V2-INDEPENDENT.md',D/'stage.py',Path(__file__)]}
engines=json.loads((T/'engine.json').read_bytes())
def git(*a):
 return subprocess.check_output(['git','-c','core.longpaths=true',*a],env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
def meta():
 return dict(head=git('rev-parse','HEAD').decode().strip(),branch=git('branch','--show-current').decode().strip(),index=sha(R/'.git/index'),stage=hashlib.sha256(git('ls-files','--stage','-z')).hexdigest(),staged=git('diff','--cached','--raw','-z').hex())
dump(K/'preflight.json',dict(plans=plans,git=meta(),probes={str(p):sha(p) for p in set(probes.values())|{cfg}},engines=engines,expected=dict(native=0,**{t:0 for t in tests},**{'world-complete':0,'world-cancel':0,'world-clean':'observe current clean baseline','world-returning':0})))
def audit():
 x={n:(h,sha(R/n)) for n,h in source.items() if n in ('core/battle/operation_private_state.gd','core/battle/operation_service_state.gd','.godot/global_script_class_cache.cfg',F,A,O)}
 return x
def work(stage,name):
 project=T/stage
 out=K/(stage+'-'+name);out.mkdir()
 user=out/'roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms'
 user.mkdir(parents=True)
 local=out/'local';local.mkdir()
 if name.startswith('world-') and name!='world-clean':shutil.copyfile(cfg,user/'settings.cfg')
 env={'APPDATA':str(out/'roaming'),'LOCALAPPDATA':str(local),'XDG_DATA_HOME':str(out/'roaming'),'SBTK_SAFE_INSETS':'0,0,0,0'}
 args=[str(E),'--headless','--path',str(project),'--script']
 if name in probes:
  q=project/('_p02_'+name+'.gd')
  shutil.copyfile(probes[name],q)
  args+=['res://'+q.name,'--']
  if name=='native':args += [stage,str(out/'observations.gdvar')]
  elif name in ('world-clean','world-returning'):args += [str(out/'result.json')]
  else:args += [name.split('-')[1],str(out/'result.json')]
 else:args+=['res://tests/'+name+'.gd']
 dump(out/'command.json',dict(args=args,env=env,user_before={str(p.relative_to(user)):sha(p) for p in user.rglob('*') if p.is_file()}))
 try:
  proc=subprocess.run(args,env={**os.environ,**env},capture_output=True,timeout=240)
  rc,so,se=proc.returncode,proc.stdout,proc.stderr
 except subprocess.TimeoutExpired as e:rc,so,se=None,e.stdout or b'',e.stderr or b''
 (out/'stdout').write_bytes(so);(out/'stderr').write_bytes(se)
 dump(out/'process.json',dict(exit=rc,timeout=rc is None,user_after={str(p.relative_to(user)):sha(p) for p in user.rglob('*') if p.is_file()}))
 print(stage,name,rc,flush=True)
initial=meta()
assert scan(R,source)==source
assert scan(T/'before',source)==source and scan(T/'after',after)==after
assert all(sha(Path(p))==h for p,h in engines.items())
subprocess.run([str(E),'--version'],capture_output=True,check=True).stdout.decode()
(K/'engine-version.txt').write_bytes(subprocess.check_output([str(E),'--version']))
if '--native-only' in sys.argv: jobs=['native']
else: jobs=list(probes)+tests
with ThreadPoolExecutor(4) as pool:
 for f in as_completed([pool.submit(work,s,n) for s in ('before','after') for n in jobs]):f.result()
final=scan(R,source)
dump(K/'postflight.json',dict(initial_git=initial,final_git=meta(),source_drift={n:[h,final[n]] for n,h in source.items() if final[n]!=h},before_match=scan(T/'before',source)==source,after_match=scan(T/'after',after)==after,live_guard=audit()))
