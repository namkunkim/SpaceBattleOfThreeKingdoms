import hashlib,json,re,subprocess,sys,time
from pathlib import Path
from windows_job import LauncherJob, CREATE_SUSPENDED
root=Path(__file__).resolve().parents[2]; here=Path(__file__).resolve().parent
engine=Path('C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe'); body=engine.with_name('Godot_v4.7.2-stable_win64.exe')
name=sys.argv[1]; folder=here/name; folder.mkdir(exist_ok=False)
paths=[engine,body,root/'project.godot',root/'.godot/global_script_class_cache.cfg',here/'windows_job.py',here/'launch.py',here/'oracle_a.gd',here/'PLAN-REPLAY-PARTIAL-20261108.md',root/'tmp/p02-third-20261108/matrix/natural.json',root/'tmp/p02-third-20261108/matrix/late.json',root/'tmp/p02-third-20261108/oracle.native',root/'tmp/p02-third-20261108/oracle.gd',root/'tmp/p02-third-20261108/oracle.stdout',root/'tests/fixtures/p02/worker-services.json']+list((root/'core/battle').rglob('*.gd'))+list((root/'data/profiles').glob('*.json'))+[root/'data/bundle-layout.json']
# Freeze autoload, every class-cache script and source references plus design authorities.
cache=(root/'.godot/global_script_class_cache.cfg').read_text(encoding='utf-8')
class_paths=re.findall(r'"path":\s*"res://([^"]+)"',cache)
if not class_paths: raise SystemExit('class cache empty')
paths += [root/x for x in class_paths] + [root/'scripts/world_link.gd']
paths += list((root/'data').rglob('*.json'))
paths += [root/x for x in ['docs/battle-core/pc-campaign-design/H2-DECISION.md','docs/battle-core/pc-campaign-design/D04-STATE.md','docs/battle-core/pc-campaign-design/I01-READINESS-DECISION-20261026.md','docs/battle-core/pc-campaign-design/I01-ACCEPTANCE-PREREG-20261026.md','tmp/p03-progress-20261108/REPLAY-SUFFIX-RESPONSIBILITY.md']]
paths = list(dict.fromkeys(paths))
if not name.startswith('oracle-attempt-'): paths += [here/'probe.gd',here/'oracle-a.native']
def hashes(): return {str(p):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':p.stat().st_size} for p in paths}
before=hashes(); (folder/'input-before.json').write_text(json.dumps(before,indent=2))
script='oracle_a.gd' if name.startswith('oracle-attempt-') else 'probe.gd'
cmd=[str(engine),'--headless','--path',str(root),'--script','res://tmp/p03-parallel-cursor-20261108/'+script]
started=time.monotonic(); timed=False; error=None; proc=None; accounting=None
try:
 with LauncherJob() as job, (folder/'stdout.bin').open('wb') as out, (folder/'stderr.bin').open('wb') as err:
  proc=subprocess.Popen(cmd,cwd=root,stdout=out,stderr=err,creationflags=CREATE_SUSPENDED)
  try: job.assign_and_resume(proc.pid)
  except OSError:
   if job.assigned: job.terminate()
   else: proc.kill()
   proc.wait(timeout=5); raise
  try: proc.wait(timeout=60)
  except subprocess.TimeoutExpired: timed=True; job.terminate(); proc.wait(timeout=5)
  deadline=time.monotonic()+5; accounting=job.accounting()
  while accounting['active'] and time.monotonic()<deadline: time.sleep(.02); accounting=job.accounting()
except (OSError,subprocess.TimeoutExpired) as e: error=str(e)
after=hashes(); (folder/'input-after.json').write_text(json.dumps(after,indent=2))
raw=b'\n'.join((folder/x).read_bytes() if (folder/x).exists() else b'' for x in ['stdout.bin','stderr.bin'])
diag={n:len(re.findall(p,raw,re.M)) for n,p in {'script_error':rb'^SCRIPT ERROR:', 'error':rb'^ERROR:', 'warning':rb'^WARNING:', 'objectdb':rb'ObjectDB','resources':rb'resources? still in use'}.items()}
marker=b'ORACLE_RESULT ' if name.startswith('oracle-attempt-') else b'PROBE_RESULT '
lines=[x[len(marker):] for x in raw.splitlines() if x.startswith(marker)]
try: result=json.loads(lines[0]) if len(lines)==1 else None
except ValueError: result=None
identity=bool(result and proc and result.get('engine_pid')!=proc.pid and Path(result.get('engine_path','')).resolve()==body.resolve())
good=bool(proc and proc.returncode==0 and not timed and not error and before==after and not any(diag.values()) and accounting and accounting['active']==0 and accounting['total']>=2 and identity and result and result.get('ok') is True)
if not name.startswith('oracle-attempt-'):
 names=['prefix_then_terminal_unconsumed','invalid_late_prevalidates_all','prefix_only_control','helper_close_error']
 expected_ids=[f'{n}:{i}' for n in names for i in range(1,9)]
 expected_lines=[]
 for n in names:
  expected_lines += ['CASE_START '+n]+[f'CHECK {n}:{i} PASS' for i in range(1,9)]+['CASE_END '+n]
 actual_lines=[line.decode('utf-8',errors='replace') for line in raw.splitlines() if line.startswith((b'CASE_START ',b'CASE_END ',b'CHECK '))]
 good=good and result.get('checks')==32 and result.get('ids')==expected_ids and result.get('cases')==names and actual_lines==expected_lines
record={'argv':cmd,'actual_exit':proc.returncode if proc else None,'timeout_exit':124 if timed else None,'timed_out':timed,'error':error,'launcher_pid':proc.pid if proc else None,'accounting':accounting,'elapsed':time.monotonic()-started,'input_stable':before==after,'diagnostics':diag,'engine_identity_matches':identity,'result':result,'gate_passed':bool(good)}
(folder/'run.json').write_text(json.dumps(record,indent=2)); print(json.dumps(record,indent=2)); sys.exit(0 if good else 1)

