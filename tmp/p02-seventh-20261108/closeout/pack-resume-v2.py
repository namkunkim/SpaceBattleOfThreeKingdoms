from pathlib import Path, PurePosixPath
from concurrent.futures import ThreadPoolExecutor
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib,json,os,subprocess
R=Path.cwd();D=Path(__file__).resolve().parent;P=D.parent
DOC=R/'docs/battle-core/pc-campaign-design'
PROGRESS=DOC/'P02-PROGRESS-CHECKLIST.md'
REQUIRE=DOC/'SESSION-REQUIREMENTS-CHECKLIST-20261031.md'
UPPER=DOC.parent/'CHECKLIST-OPEN.md'
SOURCE=R/'scripts/FleetBattle3D.gd'
def read(f):return json.loads(f.read_bytes())
def dump(f,o):
 with f.open('x',encoding='utf8') as s:json.dump(o,s,ensure_ascii=False,indent=2)
def h(x):
 if isinstance(x,bytes):return hashlib.sha256(x).hexdigest()
 with x.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def info(f):return {'bytes':f.stat().st_size,'sha256':h(f)}
def rel(f):return f.relative_to(R).as_posix()
def git(*args):return subprocess.run(['git',*args],capture_output=True,env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
def git_ok(*args):
 x=git(*args);assert x.returncode==0,x.stderr
 return x.stdout
def meta():
 return dict(head=git_ok('rev-parse','HEAD').decode().strip(),branch=git_ok('branch','--show-current').decode().strip(),index_sha256=h(R/'.git/index'),stage_sha256=h(git_ok('ls-files','--stage','-z')),staged_hex=git_ok('diff','--cached','--raw','-z').hex())
sample=read(P/'final-readonly-index/sample-2.json')
assert meta()==sample['meta_end']==sample['meta_begin']
def frozen(f):return sample['workspace'][rel(f)]['sha256']
assert h(SOURCE)==frozen(SOURCE)=='604b79308d9b3dbab84dced32456a4f41b28686c8eec748073d3816892cffc5c'
docs=sorted(D.glob('*.md.draft'))
assert len(docs)==3
new={DOC/f.name.removesuffix('.draft'):f.read_bytes() for f in docs}
assert all(p.read_bytes()==body for p,body in new.items())
hunks=read(D/'docs-hunks.json')
updates={}
for p in (PROGRESS,REQUIRE,UPPER):
 raw=(D/(p.name+'.before.txt')).read_bytes()
 after=p.read_bytes()
 a=(D/(p.name+'.old-hunk.txt')).read_bytes()
 b=(D/(p.name+'.new-hunk.txt')).read_bytes()
 assert h(raw)==frozen(p)==hunks[rel(p)]['before_sha256']
 assert h(after)==hunks[rel(p)]['after_sha256'] and after.replace(b,a,1)==raw
 updates[p]=(raw,after,a,b)
owned={SOURCE,*updates,*new}
for label,paths in [('owned-diff-check',[SOURCE,*updates]),('global-diff-check',[])]:
 x=git('diff','--check','--',*[rel(p) for p in paths])
 (D/(label+'.stdout')).write_bytes(x.stdout);(D/(label+'.stderr')).write_bytes(x.stderr);(D/(label+'.exit')).write_text(str(x.returncode)+'\n',encoding='utf8')
 assert label!='owned-diff-check' or x.returncode==0 or (b'CHECKLIST-OPEN.md:33:' in x.stdout and x.stdout.count(b'trailing whitespace')==1)
def audit():
 def listing(*a):return {x for x in git_ok('ls-files',*a,'-z').decode().split('\0') if x and not x.startswith(rel(P)+'/')}
 t,u=listing('--cached'),listing('--others','--exclude-standard')
 before=meta()
 names=sorted(t|u)
 def get(p):
  try:return info(R/p)
  except OSError as e:return {'error':str(e)}
 with ThreadPoolExecutor(8) as e: current=dict(zip(names,e.map(get,names)))
 assert meta()==before==sample['meta_end']
 assert not any('error' in i for i in current.values())
 delta={n:[sample['workspace'].get(n),current.get(n)] for n in set(names)|set(sample['workspace']) if (sample['workspace'].get(n) or {}).get('sha256')!=(current.get(n) or {}).get('sha256')}
 owned_delta=set(delta)&{rel(p) for p in owned}
 assert owned_delta=={rel(p) for p in (*updates,*new)}
 protected=[p for p in delta if p.lower().endswith(('.zip','.html'))]
 assert not protected,protected
 overlap=sorted(set(delta)&set(read(P/'k4-current/preflight.json')['inputs']))
 assert not overlap,overlap
 return {'git':before,'tracked':len(t),'nonignored_untracked':len(u),'changes_since_sample_2':delta,'unattributed_changes':{p:v for p,v in delta.items() if p not in owned_delta},'protected_zip_html_delta':protected,'execution_input_overlap':overlap,'list_drift':sorted((t^listing('--cached'))|(u^listing('--others','--exclude-standard'))),'owned':{rel(p):info(p) for p in owned}}
a=audit();dump(D/'preservation-before-zip-v2.json',a)
manifest=D/'delivery-manifest.json'; archive=D/'P02-PREP-ERROR-DELIVERY-20261108.zip'
files=set(owned)
files.update(f for f in P.iterdir() if f.is_file() and f.suffix in ('.md','.py','.gd','.json','.txt'))
files.update(f for f in D.iterdir() if f.is_file() and f.suffix!='.draft')
for folder in [P/'final-readonly-index',P/'k4-current',P/'k5-world-retry',P/'k6-worldlink-retry',P/'fixed-trace-attempt-03',*P.glob('*attempt-0[12]'),*(f for f in P.glob('gui-*') if f.is_dir())]:
 for f in folder.iterdir():
  if f.is_file():files.add(f)
  elif f.is_dir() and f.name not in ('before','after','roaming','local'):
   for g in f.iterdir():
    if g.is_file():files.add(g)
 for f in folder.rglob('battle-*.jsonl'):
  if f.is_file():files.add(f)
reference=R/'tmp/p02-sixth-20261108'
files.update(reference/n for n in ('product-host-common-v2.gd','product-host-atomic-v4.gd','native-oracle.json','trace-oracle-v4.json','world-probe.gd','returning-settings.cfg','verify-trace-v4.py'))
records={rel(f):info(f) for f in sorted(files)}
dump(manifest,{'scope':'designated battle preparation failure UI and initial escape','implementation_5b':'limited acceptance','closeout':'pending independent review','paths':records})
members={**records,rel(manifest):info(manifest)}
with ZipFile(archive,'x',ZIP_DEFLATED,compresslevel=6) as z:
 for n in sorted(members):
  assert not PurePosixPath(n).is_absolute() and '..' not in PurePosixPath(n).parts
  z.write(R/n,n)
with ZipFile(archive) as z:
 assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))==len(members) and set(z.namelist())==set(members)
 for n,i in members.items():
  data=z.read(n)
  assert {'bytes':len(data),'sha256':h(data)}==i==info(R/n),n
dump(D/'archive-verification.json',{'archive':rel(archive),**info(archive),'entries':len(members),'crc':'pass','entry_sha256_and_live_bytes':'pass','manifest_sha256':h(manifest)})
after=audit();dump(D/'preservation-after-zip.json',after)
assert a['owned']==after['owned'] and a['git']==after['git']
print(info(archive),len(members),len(a['unattributed_changes']),len(after['unattributed_changes']))


