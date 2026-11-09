from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import datetime,hashlib,json,os,subprocess
R=Path.cwd();D=Path(__file__).resolve().parent
O=D/'final-readonly-index'; O.mkdir()
REL=D.relative_to(R).as_posix()+'/'
def time():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def read(f):return json.loads(f.read_bytes())
def dump(f,x):f.write_text(json.dumps(x,ensure_ascii=False,indent=2),encoding='utf8')
def sha(f):
 with f.open('rb') as s:return hashlib.file_digest(s,'sha256').hexdigest()
def git(*a):return subprocess.check_output(['git',*a],env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
def meta():
 return dict(head=git('rev-parse','HEAD').decode().strip(),branch=git('branch','--show-current').decode().strip(),index_sha256=sha(R/'.git/index'),stage_sha256=hashlib.sha256(git('ls-files','--stage','-z')).hexdigest(),staged_hex=git('diff','--cached','--raw','-z').hex())
def manifest():
 def names(*a):return {s for s in git('ls-files',*a,'-z').decode().split('\0') if s and not s.startswith(REL)}
 return names('--cached'),names('--others','--exclude-standard')
def inspect(p):
 try:
  a=p.stat(); h=sha(p); b=p.stat()
  return {'bytes':a.st_size,'sha256':h,'read_drift':(a.st_mtime_ns,a.st_size)!=(b.st_mtime_ns,b.st_size)}
 except OSError as e:return {'error':str(e)}
def scan(paths):
 ordered=sorted(paths)
 with ThreadPoolExecutor(8) as e:return dict(zip(ordered,e.map(lambda f:inspect(R/f),ordered)))
pre=read(D/'k4-current/preflight.json')
initial=read(D/'baseline.json')
v4=read(D/'live-v4-inputs.json')
old=read(D/'after-attempt-02/inputs.json')
eng=['C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe','C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe','.godot/global_script_class_cache.cfg']
paths=set(pre['inputs'])|set(v4['paths'])|set(eng)
samples=[]
for i in (1,2):
 t0=time();m0=meta(); t,u=manifest()
 a=scan(paths|t|u)
 t1,u1=manifest();m1=meta()
 w={p:a[p] for p in sorted(t|u)}
 result={'begin_utc':t0,'end_utc':time(),'meta_begin':m0,'meta_end':m1,'tracked':len(t),'nonignored_untracked':len(u),'within_sample_list_delta':sorted((t^t1)|(u^u1)),'execution':{p:a[p] for p in sorted(paths)},'workspace':w}
 dump(O/f'sample-{i}.json',result)
 samples.append(result)
x,y=samples
def delta(expected,actual):return {p:[expected.get(p),actual.get(p,{}).get('sha256')] for p in sorted(expected) if expected[p]!=actual.get(p,{}).get('sha256')}
def change(a,b):return {p:[a.get(p),b.get(p)] for p in sorted(a.keys()|b.keys()) if a.get(p)!=b.get(p)}
execution_delta=change(x['execution'],y['execution'])
workspace_delta=change(x['workspace'],y['workspace'])
first_delta=change({p:{'bytes':v.get('bytes'),'sha256':v.get('sha256'),'read_drift':v.get('drift')} for p,v in initial['paths'].items()},y['workspace'])
report={'original_baseline_utc':initial['timestamp'],'k4_execution_paths':len(pre['inputs']),'v4_execution_paths':len(v4['paths']),'union_with_engine_paths':len(paths),'observations':[{k:s[k] for k in ('begin_utc','end_utc','meta_begin','meta_end','tracked','nonignored_untracked','within_sample_list_delta')} for s in samples],
 'k4_delta_by_sample':[delta(pre['inputs'],s['execution']) for s in samples],
 'v4_delta_by_sample':[delta({p:q['sha256'] for p,q in v4['paths'].items()},s['execution']) for s in samples],
 'historical_k2_delta_by_sample':[delta(old,s['execution']) for s in samples],
 'execution_between_samples':execution_delta,'workspace_between_samples':workspace_delta,
 'workspace_delta_from_original_baseline':first_delta,
 'workspace_delta_overlaps_k4':sorted(set(first_delta)&set(pre['inputs'])),
 'workspace_between_samples_overlaps_k4':sorted(set(workspace_delta)&set(pre['inputs'])),
 'workspace_p03_or_unattributed':{p:v for p,v in first_delta.items() if p!='scripts/FleetBattle3D.gd'},
 'read_errors_and_within_file_drift':[sorted(p for p,v in {**s['workspace'],**s['execution']}.items() if 'error' in v or v.get('read_drift')) for s in samples],
 'notes':'Read-only sequential observations. Paths are classified by overlap; timing and pathname cannot establish authorship. Evidence subtree excluded from workspace inventory, retained where frozen as execution input.'}
dump(O/'INDEX.json',report)
print(json.dumps({k:len(report[k]) if isinstance(report[k],dict) else report[k] for k in ('k4_execution_paths','v4_execution_paths','union_with_engine_paths','k4_delta_by_sample','v4_delta_by_sample','execution_between_samples','workspace_between_samples','workspace_delta_overlaps_k4','workspace_between_samples_overlaps_k4','read_errors_and_within_file_drift')},ensure_ascii=False))
