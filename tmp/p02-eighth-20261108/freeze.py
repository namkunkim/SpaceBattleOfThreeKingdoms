import hashlib,json,os,pathlib,subprocess,datetime,sys
from concurrent.futures import ThreadPoolExecutor
d=pathlib.Path(__file__).parent
def git(*a): return subprocess.check_output(['git','-c','core.quotepath=false','-c','core.longpaths=true',*a],env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
def paths(*a): return {p.decode('utf-8') for p in git('ls-files','-z',*a).split(b'\0') if p and not p.startswith(b'tmp/p02-eighth-20261108/')}
def digest(p):
 try:
  s=os.stat(p)
  with open(p,'rb') as f: h=hashlib.file_digest(f,'sha256').hexdigest()
  t=os.stat(p)
  return {'bytes':s.st_size,'sha256':h,'drift':(s.st_size,s.st_mtime_ns)!=(t.st_size,t.st_mtime_ns)}
 except OSError as e: return {'error':str(e)}
def meta():
 idx=os.fsdecode(git('rev-parse','--git-path','index').strip())
 stage=git('ls-files','--stage','-z')
 staged=git('diff','--cached','--raw','-z')
 return {'branch':git('branch','--show-current').decode().strip(),'head':git('rev-parse','HEAD').decode().strip(),'index':digest(idx),'stage_sha256':hashlib.sha256(stage).hexdigest(),'staged_hex':staged.hex()}
m=meta()
a,b=paths('--cached'),paths('--others','--exclude-standard')
with ThreadPoolExecutor(8) as pool:
 ks=sorted(a|b)
 result={k:{'kind':'tracked' if k in a else 'nonignored_untracked',**v} for k,v in zip(ks,pool.map(digest,ks))}
out={'timestamp':datetime.datetime.now(datetime.timezone.utc).isoformat(),'before':m,'after':meta(),'list_drift':sorted((a^paths('--cached'))|(b^paths('--others','--exclude-standard'))),'tracked':len(a),'nonignored_untracked':len(b),'paths':result,'engine':digest(r'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'),'classcache':digest('.godot/global_script_class_cache.cfg')}
(d/sys.argv[1]).write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
print(len(a),len(b),out['list_drift'],sum('error' in v or v['drift'] for v in result.values()),m==out['after'],out['engine'],out['classcache'])



