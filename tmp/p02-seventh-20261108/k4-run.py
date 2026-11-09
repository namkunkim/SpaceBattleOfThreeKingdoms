from pathlib import Path
import concurrent.futures as cf, hashlib, json, os, shutil, subprocess, sys
R=Path.cwd(); D=Path(__file__).resolve().parent; P=D/'k4-current'
OLD=R/'tmp/p02-sixth-20261108'
E=Path('C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe')
EXE=E.with_name(E.name.replace('_console',''))
B='scripts/FleetBattle3D.gd'; C='.godot/global_script_class_cache.cfg'
OWNER='core/battle/operation_private_state.gd'
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(p):return json.loads(p.read_bytes())
def dump(p,o):p.write_text(json.dumps(o,indent=2,ensure_ascii=False),encoding='utf8')
def scan(root,names):
 with cf.ThreadPoolExecutor(8) as e:return dict(zip(names,e.map(lambda n:sha(root/n),names)))
def rel(x):return x.relative_to(R).as_posix()
def meta():
 env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'}
 def git(*a):return subprocess.check_output(['git',*a],env=env)
 return dict(head=git('rev-parse','HEAD').decode().strip(),branch=git('branch','--show-current').decode().strip(),index=sha(R/'.git/index'),stage=hashlib.sha256(git('ls-files','--stage','-z')).hexdigest(),staged=git('diff','--cached','--raw','-z').hex())
baseline=read(D/'baseline.json')
historical=read(D/'after-attempt-02/inputs.json')
def engines():
 return {str(E):sha(E),str(EXE):sha(EXE),C:sha(R/C)}
def freeze():
 P.mkdir()
 paths=sorted(set(historical)|{rel(D/x) for x in ('PLAN-v5.md','REVIEW-PLAN-V5-INDEPENDENT.md','PLAN-v4.md','K4-CASES.txt','k4-run.py','k4-world-product.gd','fixed-trace-probe-v2.gd','roster-probe.gd','render-probe-v2.gd','input-probe.gd','GUI-RESUME-EVIDENCE.md','trace-comparison-detail.json')}|{rel(OLD/'returning-settings.cfg'),rel(D/'FleetBattle3D.gd.before.txt')})
 m=meta(); h=engines()
 now=scan(R,paths)
 drift={n:[historical[n],now[n]] for n in historical if historical[n]!=now[n]}
 dump(P/'preflight.json',dict(git=m,engines=h,drift=drift,inputs=now))
 assert h=={str(E):baseline['engine']['sha256'],str(EXE):'ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424',C:baseline['classcache']['sha256']}
 assert m==dict(head=baseline['before']['head'],branch=baseline['before']['branch'],index=baseline['before']['index']['sha256'],stage=baseline['before']['stage_sha256'],staged=baseline['before']['staged_hex'])
 assert set(drift)=={OWNER} and now[OWNER]=='ac59a7547469c705d33854742e9503b08422770b01956a47861b45735ab8c1c6',drift
 assert now[rel(D/'PLAN-v5.md')]=='d064c3e280345fea1e1c026a8b7941f5fc0bb61ad2d7492d9da3d3249d3bb904'
 assert scan(R,paths)==now and engines()==h and meta()==m
 for stage in ('before','after'):
  root=P/stage; root.mkdir()
  expected=dict(now)
  if stage=='before':expected[B]=baseline['paths'][B]['sha256']
  for n in paths:
   src=D/'FleetBattle3D.gd.before.txt' if stage=='before' and n==B else R/n
   dst=root/n;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
  assert scan(root,paths)==expected
  dump(P/(stage+'-inputs.json'),expected)
 assert scan(R,paths)==now and engines()==h and meta()==m
 dump(P/'freeze-complete.json',dict(paths=len(paths),only_replica_delta=B,canonical_owner=now[OWNER]))
def run(stage,name):
 root=P/stage
 expected=read(P/(stage+'-inputs.json'))
 pre=read(P/'preflight.json')
 assert scan(root,expected)==expected and scan(R,pre['inputs'])==pre['inputs'] and engines()==pre['engines'] and meta()==pre['git']
 out=P/(stage+'-'+name);out.mkdir()
 roam=out/'roaming';local=out/'local'; user=roam/'Godot/app_userdata/SpaceBattleOfThreeKingdoms'
 user.mkdir(parents=True);local.mkdir()
 cfg=root/rel(OLD/'returning-settings.cfg')
 if name in ('returning','world-complete','world-cancel','routed-mouse','routed-key','render-routed','render-live','roster'):
  shutil.copyfile(cfg,user/'settings.cfg')
 env=dict(APPDATA=str(roam),LOCALAPPDATA=str(local),XDG_DATA_HOME=str(roam),SBTK_SAFE_INSETS='0,0,0,0')
 before_user={f.relative_to(user).as_posix():sha(f) for f in user.rglob('*') if f.is_file()}
 args=[str(E),'--headless','--path',str(root)]
 result=str(out/'result.json')
 suite={'common':OLD/'product-host-common-v2.gd','atomic':OLD/'product-host-atomic-v4.gd','battle':R/'tests/battle_flow.gd','organization':R/'tests/organization_ui.gd','clean':OLD/'world-probe.gd','returning':OLD/'world-probe.gd','fixed':D/'fixed-trace-probe-v2.gd','roster':D/'roster-probe.gd','world-complete':D/'k4-world-product.gd','world-cancel':D/'k4-world-product.gd','routed-mouse':D/'input-probe.gd','routed-key':D/'input-probe.gd','render-routed':D/'render-probe-v2.gd','render-live':D/'render-probe-v2.gd'}[name]
 tail=[result]
 if name in ('world-complete','world-cancel','roster'):
  tail=[name.removeprefix('world-'),result]
 if name.startswith(('routed-','render-')):
  args=[str(E),'--path',str(root),'--rendering-method','gl_compatibility','--resolution','1600x900' if name in ('routed-mouse','render-routed') else '1280x720']
  if name in ('routed-key','render-live'):env['SBTK_SAFE_INSETS']='50,34,28,22'
  tail=['live' if name=='render-live' else 'routed',result]
 args+=['--script','res://'+rel(suite),'--',*tail]
 dump(out/'command.json',dict(args=args,env=env,user_before=before_user,manifest=sha(P/(stage+'-inputs.json'))))
 try:
  x=subprocess.run(args,env={**os.environ,**env},capture_output=True,timeout=240)
  rc,stdout,stderr=x.returncode,x.stdout,x.stderr
 except subprocess.TimeoutExpired as x:rc,stdout,stderr=None,x.stdout or b'',x.stderr or b''
 (out/'stdout').write_bytes(stdout);(out/'stderr').write_bytes(stderr)
 user_after={f.relative_to(user).as_posix():sha(f) for f in user.rglob('*') if f.is_file()}
 stable=scan(root,expected)==expected and scan(R,pre['inputs'])==pre['inputs'] and engines()==pre['engines'] and meta()==pre['git']
 dump(out/'process.json',dict(exit=rc,timeout=rc is None,inputs_unchanged=stable,user_after=user_after))
 assert stable
 print(stage,name,rc,flush=True)
if sys.argv[1]=='freeze':freeze()
elif sys.argv[1]=='suite':
 cases=[(stage,name) for stage in ('before','after') for name in ('common','battle','organization','clean','returning','fixed','roster','world-complete','world-cancel')]+[('after','atomic')]
 with cf.ThreadPoolExecutor(4) as pool:
  for f in cf.as_completed([pool.submit(run,*case) for case in cases]):f.result()
else:run(sys.argv[1],sys.argv[2])
