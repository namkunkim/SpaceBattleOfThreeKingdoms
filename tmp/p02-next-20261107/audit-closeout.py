from pathlib import Path
from collections import Counter
import difflib,hashlib,json,subprocess,zipfile

root=Path.cwd()
e=root/'tmp/p02-next-20261107'
out=e/'closeout'
out.mkdir()
d=root/'docs/battle-core/pc-campaign-design'
docs=[root/'docs/battle-core/CHECKLIST-OPEN.md', d/'SESSION-REQUIREMENTS-CHECKLIST-20261031.md']
new_docs=[d/f for f in ('P02-WORKER-RESULT-20261107.md','P02-WORKER-CHECKLIST-20261107.md','SESSION-HANDOFF-P02-WORKER-20261107.md')]
def sha(b): return hashlib.sha256(b).hexdigest()
def stat(p): return {'bytes':p.stat().st_size,'sha256':sha(p.read_bytes())}
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def write(p,obj):
    with p.open('x',encoding='utf-8') as stream: json.dump(obj,stream,ensure_ascii=False,indent=2)

owned_docs={p.relative_to(root).as_posix() for p in docs}
new_doc_paths={p.relative_to(root).as_posix() for p in new_docs}
impl=load(e/'implementation-manifest.json')
assert all(stat(e/n)==meta for n,meta in impl['records'].items())
assert all(stat(root/n)==meta for n,meta in impl['owned_sources'].items())
assert stat(e/'REVIEW-5B-INDEPENDENT.md')['sha256']=='e2fc0b229ca6fd739490c21507f485edc1670c30f67145f9d6998874078117d0'
owned_code={'scripts/world/auto_resolver.gd','tests/autoresolve.gd'}
p03={'tmp/p03-state-checkpoint-20261105/'+n+'.py' for n in ('inventory','run_gate','test_inventory')}
rows=load(e/'baseline-files.json')
counts=Counter()
differences=[]
archive_html=[]
for row in rows:
    name=row['path']
    path=root/name
    assert path.is_file(),name
    current=stat(path)
    expected={k:row[k] for k in current}
    if current==expected:
        counts['identical']+=1
        if path.suffix.lower() in ('.zip','.html'):
            archive_html.append({'path':name,**current})
        continue
    assert name in owned_docs|owned_code|p03,name
    group='owned_document' if name in owned_docs else 'owned_code' if name in owned_code else 'concurrent_p03'
    if group!='concurrent_p03':
        assert stat(e/'before'/(path.name+'.txt'))==expected
    differences.append({'path':name,'group':group,'original':expected,'observed':current})
    counts[group]+=1
assert counts=={'identical':7071,'owned_code':2,'owned_document':2,'concurrent_p03':3}
listed=subprocess.run(['git','ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True)
paths={x.decode() for x in listed.stdout.split(b'\0') if x}
new=paths-{r['path'] for r in rows}
evidence_new={x for x in new if x.startswith('tmp/p02-next-20261107/')}
p03_new={x for x in new if x.startswith(('tmp/p03-state-checkpoint-20261105/','tmp/p03-command-suffix-20261107/'))}
new_code={n.replace('\\','/') for n in impl['owned_sources']}-owned_code
assert new-evidence_new-p03_new==new_code|new_doc_paths,new-evidence_new-p03_new-new_code-new_doc_paths
doc_proof=[]
for p in docs:
    orig=(e/'before'/(p.name+'.txt')).read_bytes()
    new_content=p.read_bytes()
    a,b=orig.splitlines(keepends=True),new_content.splitlines(keepends=True)
    changes=[(i,j,k,l) for op,i,j,k,l in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes() if op!='equal']
    assert len(changes)==1
    i,j,k,l=changes[0]
    inverse=b''.join(b[:k]+a[i:j]+b[l:])
    assert inverse==orig
    patch=b''.join(difflib.diff_bytes(difflib.unified_diff,a,b,fromfile=b'a/'+p.relative_to(root).as_posix().encode(),tofile=b'b/'+p.relative_to(root).as_posix().encode()))
    f=out/(p.name+'.owned.diff')
    f.write_bytes(patch)
    doc_proof.append({'path':p.relative_to(root).as_posix(),'before_sha256':sha(orig),'after_sha256':sha(new_content),'inverse_sha256':sha(inverse),'owned_diff_sha256':sha(patch),'owned_hunks':1})
    for line in b[k:l]:
        assert line==line.rstrip()+b'\n'
write(out/'document-proof.json',doc_proof)
commands={'head':['rev-parse','HEAD'],'branch':['branch','--show-current'],'index':['diff','--cached','--name-status'],
          'index_tree':['ls-files','--stage','-z'],'diff-check':['diff','--check']}
context={}
for name,args in commands.items():
    p=subprocess.run(['git',*args],capture_output=True)
    (out/f'{name}.stdout').write_bytes(p.stdout)
    (out/f'{name}.stderr').write_bytes(p.stderr)
    assert p.stdout==(e/f'{name}.stdout').read_bytes() and p.stderr==(e/f'{name}.stderr').read_bytes()
    assert p.returncode==(2 if name=='diff-check' else 0)
    context[name]={'exit':p.returncode,'stdout_sha256':sha(p.stdout),'stderr_sha256':sha(p.stderr),'byte_exact_before':True}
for p in [*new_docs,*[root/n for n in new_code]]:
    assert all(line.rstrip()==line for line in p.read_bytes().splitlines()),p
patches=sorted(out.glob('*.owned.diff'))
for file in patches:
    p=subprocess.run(['git','apply','--reverse','--check','--whitespace=error-all',str(file)],capture_output=True)
    (out/(file.name+'.apply.stdout')).write_bytes(p.stdout)
    (out/(file.name+'.apply.stderr')).write_bytes(p.stderr)
    # Reverse-check is only auxiliary: new lines and byte-exact reverse hunks were checked directly.
    if p.returncode: print(file.name,p.returncode,p.stderr.decode(errors='replace'))
core_diff=subprocess.run(['git','diff','--check','--',*sorted(owned_code)],capture_output=True)
assert core_diff.returncode==0
cache=root/'.godot/global_script_class_cache.cfg'
assert stat(cache)['sha256']=='0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1'
write(out/'preservation.json',{'baseline':len(rows),'missing':0,'groups':dict(counts),'differences':differences,'new_p03_observed':sorted(p03_new),'new_owned_source':sorted(new_code),'new_owned_documents':sorted(new_doc_paths),'baseline_zip_html':archive_html,'owned_code_diff_check_exit':core_diff.returncode,'owned_document_hunks_trailing_whitespace':0,'context':context,'cache':stat(cache)})
write(out/'model-independence.json',{'parent_session':'01a1ac09-125c-71d0-b13b-721727506c85','implementation':{'agent_path':'/root/p02_next_impl','session':'01a1b5c4-0cb0-75c3-8287-d0c2646f51f7','model':'gpt-6.1-sol'},'plan_and_implementation_review':{'agent_path':'/root/p02_next_review','session':'01a1b5bf-e9fe-7383-8dc9-aec906ab2995','model':'gpt-6.1-terra','plan_review':stat(e/'REVIEW-PLAN-INDEPENDENT.md'),'implementation_review':stat(e/'REVIEW-5B-INDEPENDENT.md')},'source':'independent implementation review directly checked both session_meta and turn_context','delivery_closeout':'pending'})
archive=root/'tmp/P02-WORKER-DELIVERY-20261107.zip'
assert not archive.exists()
members=sorted({*docs,*new_docs,*[root/n for n in impl['owned_sources']],*[p for p in e.rglob('*') if p.is_file()]})
manifest=out/'manifest.json'
table={p.relative_to(root).as_posix():stat(p) for p in members}
write(manifest,{'plan_sha256':stat(e/'PLAN.md')['sha256'],'implementation_manifest_sha256':stat(e/'implementation-manifest.json')['sha256'],'content_files':len(table),'files':table})
with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in [*members,manifest]:
        z.write(p,p.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    names=z.namelist()
    expected={**table,manifest.relative_to(root).as_posix():stat(manifest)}
    assert len(names)==len(expected) and set(names)==set(expected)
    for name,record in expected.items():
        blob=z.read(name)
        assert len(blob)==record['bytes'] and sha(blob)==record['sha256'],name
write(out/'archive-verification.json',{'archive':archive.relative_to(root).as_posix(),**stat(archive),'zip_members':len(expected),'zip_manifest':stat(manifest),'member_sha_size_mismatches':0,'zip_test':None})
print(json.dumps({'groups':dict(counts),'P03_new':len(p03_new),'baseline_zip_html':len(archive_html),'archive':stat(archive),'members':len(expected),'manifest':stat(manifest)},ensure_ascii=False,indent=2))
