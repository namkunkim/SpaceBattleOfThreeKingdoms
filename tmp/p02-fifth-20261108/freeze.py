import hashlib,json,pathlib,subprocess
root=pathlib.Path.cwd()
out=root/'tmp/p02-fifth-20261108'
def git(*args): return subprocess.check_output(['git',*args])
def sha(p):
    before=p.stat()
    with p.open('rb') as stream: digest=hashlib.file_digest(stream,'sha256').hexdigest()
    after=p.stat()
    return {'bytes':after.st_size,'sha256':digest,'changed_while_reading':(before.st_size,before.st_mtime_ns)!=(after.st_size,after.st_mtime_ns)}
queries={'branch':('branch','--show-current'),'head':('rev-parse','HEAD'),'index':('ls-files','--stage','-z'),'tracked':('ls-files','--cached','-z'),'untracked':('ls-files','--others','--exclude-standard','-z')}
def capture(): return {key:git(*args) for key,args in queries.items()}
def paths(data): return {p for p in data.decode('utf-8').split('\0') if p and not p.startswith('tmp/p02-fifth-20261108/')}
index_path=root/git('rev-parse','--git-path','index').decode().strip()
first=capture()
index_start=sha(index_path)
for key,data in first.items(): (out/(key+'.raw')).write_bytes(data)
tracked,untracked=(paths(first[key]) for key in ('tracked','untracked'))
rows={}
for name in sorted(tracked|untracked):
    try: rows[name]=sha(root/name)
    except FileNotFoundError: rows[name]={'missing':True}
last=capture()
runtime_paths=[pathlib.Path(r'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'),root/'.godot/global_script_class_cache.cfg']
report={'tracked':len(tracked),'untracked':len(untracked),'paths':rows,'raw_sha256':{k:hashlib.sha256(v).hexdigest() for k,v in first.items()},'index_start':index_start,'index_end':sha(index_path),'metadata_drift':[k for k in ('branch','head','index','tracked') if first[k]!=last[k]],'untracked_added':sorted(paths(last['untracked'])-untracked),'untracked_removed':sorted(untracked-paths(last['untracked'])),'runtime':{str(p):sha(p) for p in runtime_paths}}
(out/'baseline.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print({k:v for k,v in report.items() if k!='paths'})
