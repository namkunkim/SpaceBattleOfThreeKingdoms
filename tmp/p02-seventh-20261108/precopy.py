import hashlib,json,os,pathlib,subprocess
from concurrent.futures import ThreadPoolExecutor
p=pathlib.Path(__file__).resolve().parent
r=pathlib.Path.cwd()
def sha(f):
 with open(f,'rb') as x:return hashlib.file_digest(x,'sha256').hexdigest()
def git(*a):return subprocess.check_output(['git',*a],env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
def inventory():
 return sorted({x for x in git('ls-files','--cached','--others','--exclude-standard','-z').decode().split('\0') if x and not x.startswith('tmp/p02-seventh-20261108/')})
def record(x):
 f=r/x
 if not f.is_file():return None
 a=f.stat()
 h=sha(f)
 b=f.stat()
 return dict(bytes=a.st_size,sha256=h,drift=(a.st_size,a.st_mtime_ns)!=(b.st_size,b.st_mtime_ns))
b=json.loads((p/'baseline.json').read_bytes())
ls=inventory()
with ThreadPoolExecutor(8) as ex:
 a=dict(zip(ls,ex.map(record,ls)))
delta={x:[b['paths'].get(x),a.get(x)] for x in sorted(set(a)|set(b['paths'])) if {k:v for k,v in b['paths'].get(x,{}).items() if k!='kind'} != (a.get(x) or {})}
exe=[str(x) for x in pathlib.Path('C:/Tools/Godot').glob('*4.7.2*.exe')]
meta=dict(branch=git('branch','--show-current').decode().strip(),head=git('rev-parse','HEAD').decode().strip(),index=record('.git/index'),stage_sha256=hashlib.sha256(git('ls-files','--stage','-z')).hexdigest(),staged_hex=git('diff','--cached','--raw','-z').hex())
report=dict(metadata=meta,baseline_metadata=b['before'],paths=len(ls),list_drift=sorted(set(ls)^set(inventory())),delta=delta,engine={x:sha(x) for x in exe},classcache=record('.godot/global_script_class_cache.cfg'))
(p/'precopy-workspace.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('delta:',len(delta),'metadata matches:',meta==b['before'],'list_drift:',len(report['list_drift']))
print('\n'.join(x for x in delta if not x.startswith('tmp/p03-')))
