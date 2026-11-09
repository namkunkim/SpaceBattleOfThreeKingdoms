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
assert not any(p.exists() for p in new)
updates={}
def patch(path,old,new_text):
 raw=path.read_bytes()
 assert h(raw)==frozen(path),path
 nl='\r\n' if b'\r\n' in raw else '\n'
 a=old.replace('\n',nl).encode()
 b=new_text.replace('\n',nl).encode()
 assert raw.count(a)==1,path
 after=raw.replace(a,b,1)
 assert after.count(b)==1 and after.replace(b,a,1)==raw
 updates[path]=(raw,after,a,b)
old='- [ ] 사용자 HUD 오류 표시, 적벽 operation 지원, FleetBattle3D·WorldMap 제품 operation 연결과 P02 전체 인수는 남아 있다.'
patch(PROGRESS,old,'''## 7. 전투 준비 실패 안내와 최초 탈출

- [x] 지정 준비 실패에서 기존 전투 안내와 최초 종료·천하 복귀를 제공한다. 실제 Windows 입력과 현재 자동 해결 완료·취소, 고정 후속 트레이스를 검증했다. 최초 시작 strict 7/8, clean WorldLink 기존 단일 실패 및 K6 소모를 따로 기록했다. 독립 5-b 한정 수용. [결과](P02-PREP-ERROR-RESULT-20261108.md) · [전용 체크리스트](P02-PREP-ERROR-CHECKLIST-20261108.md) · [인계](SESSION-HANDOFF-P02-PREP-ERROR-20261108.md)
- [ ] 새 전달 ZIP 독립 마감 대기. [전달 ZIP](../../../tmp/p02-seventh-20261108/closeout/P02-PREP-ERROR-DELIVERY-20261108.zip)
- [ ] 적벽 operation 지원, FleetBattle3D·WorldMap 제품 operation 연결과 P02 전체 인수는 남아 있다.''')
old='[legacy FleetBattle3D 후보 준비](P02-HOST-PREP-RESULT-20261108.md)는 지정 오류와 동기 호출만 한정 수용. [진행표]'
patch(REQUIRE,old,old.replace(' [진행표]',' [전투 준비 실패 안내·최초 탈출](P02-PREP-ERROR-RESULT-20261108.md)도 지정 실패에서 한정 수용. [진행표]'))
upper_line=next(l for l in UPPER.read_text(encoding='utf8').splitlines() if '**P02 legacy FleetBattle3D 후보 준비' in l)
patch(UPPER,upper_line,upper_line+'\n  - [ ] **P02 전투 준비 실패 안내와 최초 탈출(2026-11-08)**. 지정 준비 실패 안내 및 최초 종료·천하 복귀는 독립 5-b 한정 수용됐다. 전체 P02와 제품 operation은 미완료다. [결과](pc-campaign-design/P02-PREP-ERROR-RESULT-20261108.md) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [인계](pc-campaign-design/SESSION-HANDOFF-P02-PREP-ERROR-20261108.md).')
hunks={}
for p,(raw,after,a,b) in updates.items():
 for suffix,value in [('before',raw),('old-hunk',a),('new-hunk',b)]:
  (D/(p.name+'.'+suffix+'.txt')).write_bytes(value)
 hunks[rel(p)]={'before_sha256':h(raw),'after_sha256':h(after),'old_hunk_sha256':h(a),'new_hunk_sha256':h(b),'reverse_exact':True}
dump(D/'docs-hunks.json',hunks)
for p,(raw,after,a,b) in updates.items():
 assert p.read_bytes()==raw
 p.write_bytes(after)
 assert p.read_bytes().replace(b,a,1)==raw
for p,body in new.items():
 with p.open('xb') as f:f.write(body)
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
a=audit();dump(D/'preservation-before-zip.json',a)
manifest=D/'delivery-manifest.json'; archive=D/'P02-PREP-ERROR-DELIVERY-20261108.zip'
files=set(owned)
files.update(f for f in P.iterdir() if f.is_file() and f.suffix in ('.md','.py','.gd','.json','.txt'))
files.update(f for f in D.iterdir() if f.is_file() and f.suffix!='.draft')
for folder in [P/'final-readonly-index',P/'k4-current',P/'k5-world-retry',P/'k6-worldlink-retry',P/'fixed-trace-attempt-03',*P.glob('*attempt-0[12]'),*P.glob('gui-*')]:
 for f in folder.iterdir():
  if f.is_file():files.add(f)
  elif f.is_dir() and f.name not in ('before','after','roaming','local'):
   for g in f.iterdir():
    if g.is_file():files.add(g)
 for f in folder.rglob('battle-*.jsonl'):
  if f.is_file():files.add(f)
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
