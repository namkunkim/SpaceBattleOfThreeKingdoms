import sys, pathlib, concurrent.futures, json, shutil, hashlib, os, subprocess
r=pathlib.Path.cwd()
d=pathlib.Path(__file__).resolve().parent
old=r/'tmp/p02-sixth-20261108'
eng=pathlib.Path('C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe')
exe=eng.with_name(eng.name.replace('_console',''))
suites=dict(common='product-host-common-v2.gd',atomic='product-host-atomic-v4.gd',battle='tests/battle_flow.gd',organization='tests/organization_ui.gd',clean='world-probe.gd',returning='world-probe.gd')
cache='.godot/global_script_class_cache.cfg'
def digest(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def inventory(root, names):
 with concurrent.futures.ThreadPoolExecutor(8) as e:return dict(zip(names,e.map(lambda n:digest(root/n),names)))
def dump(path,obj):path.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf8')
base=json.loads((d/'baseline.json').read_bytes())
def guard():
 assert digest(eng)==base['engine']['sha256']
 assert digest(exe)=='ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424'
 assert digest(r/cache)==base['classcache']['sha256']
 if not (d/'engine-version.txt').exists():
  (d/'engine-version.txt').write_bytes(subprocess.check_output([str(eng),'--version']))
def source_paths():
 paths={'project.godot',cache,'.godot/uid_cache.bin','.godot/scene_groups_cache.cfg'}
 for directory in ['assets','core','data','hud','input','scenes','scripts','tests','view','.godot/imported']:
  paths.update(x.relative_to(r).as_posix() for x in (r/directory).rglob('*') if x.is_file())
 paths.update(str(x.relative_to(r).as_posix()) for x in [eng,exe] if x.is_relative_to(r))
 paths.update((old/n).relative_to(r).as_posix() for n in [*{v for v in suites.values() if not v.startswith('tests/')},'returning-settings.cfg','native-oracle.json','trace-oracle-v4.json','verify-trace-v4.py'])
 paths.update((d/n).relative_to(r).as_posix() for n in ['run.py','run-v2.py','run-world-before.py','assertions.txt','PLAN-v2.md','REVIEW-PLAN-V2-INDEPENDENT.md'])
 return sorted(paths)
stage=sys.argv[1]
attempt=sys.argv[2] if len(sys.argv)>2 else '01'
root=d/('project-'+stage+('' if attempt=='01' else '-'+attempt))
out=d/(stage+'-attempt-'+attempt)
guard()
names=source_paths()
now=inventory(r,names)
now['scripts/FleetBattle3D.gd']=digest(d/'FleetBattle3D.gd.before.txt')
changed=[n for n in names if n in base['paths'] and now[n]!=base['paths'][n]['sha256'] and not(stage=='after' and n=='scripts/FleetBattle3D.gd')]
assert not changed,changed
if stage=='after':
 before=json.loads((d/'before-attempt-01/inputs.json').read_bytes())
 assert {n for n in set(now)|set(before) if now.get(n)!=before.get(n)}=={'scripts/FleetBattle3D.gd','tmp/p02-seventh-20261108/run-v2.py'}
out.mkdir()
dump(out/'inputs.json',now)
for n in names:
 dst=root/n
 dst.parent.mkdir(parents=True,exist_ok=True)
 shutil.copyfile(d/'FleetBattle3D.gd.before.txt' if n=='scripts/FleetBattle3D.gd' else r/n,dst)
assert inventory(root,names)==now and all(v==now[k] for k,v in inventory(r,names).items() if k!='scripts/FleetBattle3D.gd')
def run(pair):
 k,v=pair
 p=out/k
 p.mkdir()
 roam=p/'roaming'; local=p/'local'
 user=roam/'Godot/app_userdata/SpaceBattleOfThreeKingdoms'
 user.mkdir(parents=True);local.mkdir()
 if k=='returning':shutil.copyfile(old/'returning-settings.cfg',user/'settings.cfg')
 env=dict(APPDATA=str(roam),LOCALAPPDATA=str(local),XDG_DATA_HOME=str(roam))
 rel=v if v.startswith('tests/') else (old/v).relative_to(r).as_posix()
 args=[str(eng),'--headless','--path',str(root),'--script','res://'+rel,'--',str(p/'result.json')]
 dump(p/'command.json',dict(args=args,env=env))
 try:
  x=subprocess.run(args,capture_output=True,timeout=240,env={**os.environ,**env})
  rc,stdout,stderr=x.returncode,x.stdout,x.stderr
 except subprocess.TimeoutExpired as x:rc,stdout,stderr=None,x.stdout or b'',x.stderr or b''
 (p/'stdout').write_bytes(stdout)
 (p/'stderr').write_bytes(stderr)
 dump(p/'process.json',dict(exit=rc,timeout=rc is None))
 return k,rc
with concurrent.futures.ThreadPoolExecutor(6) as e:results=list(e.map(run,[(k,v) for k,v in suites.items() if k in ('clean','returning')]))
dump(out/'processes.json',results)
assert inventory(root,names)==now and all(v==now[k] for k,v in inventory(r,names).items() if k!='scripts/FleetBattle3D.gd')
guard()
print(results)



