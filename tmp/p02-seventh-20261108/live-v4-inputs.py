import ast, hashlib, json, pathlib
from concurrent.futures import ThreadPoolExecutor
d=pathlib.Path(__file__).resolve().parent
r=pathlib.Path.cwd()
runner=d/'run-v2.py'
tree=ast.parse(runner.read_text(encoding='utf-8-sig'))
tree.body=[n for n in tree.body if (isinstance(n,(ast.Import,ast.ImportFrom)) or isinstance(n,ast.FunctionDef) and n.name in ['digest','source_paths'] or isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id in ['r','d','old','eng','exe','suites','cache'] for t in n.targets))]
ns={'__file__':str(runner)}
exec(compile(tree,str(runner),'exec'),ns)
def paths():
 return sorted(set(ns['source_paths']())|{x.relative_to(r).as_posix() for x in d.iterdir() if x.is_file() and x.suffix in ['.py','.gd','.md','.txt'] and not x.name.startswith('freeze-live-v4') and x.name!='live-v4-inputs.py'})
def digest(p):
 a=p.stat()
 with p.open('rb') as f: sha=hashlib.file_digest(f,'sha256').hexdigest()
 b=p.stat()
 return {'bytes':a.st_size,'sha256':sha,'drift':(a.st_size,a.st_mtime_ns)!=(b.st_size,b.st_mtime_ns)}
def snap(names):
 with ThreadPoolExecutor(8) as pool:return dict(zip(names,pool.map(lambda x:digest(r/x),names)))
names=paths()
first=snap(names)
second=snap(paths())
engine={str(x):digest(x) for x in [ns['eng'],ns['exe']]}
historical=json.loads((d/'after-attempt-02/inputs.json').read_bytes())
delta={k:[historical[k],first.get(k)] for k in historical if historical[k] != (first.get(k) or {}).get('sha256')}
diff=[k for k in sorted(first.keys()|second.keys()) if first.get(k)!=second.get(k) or (first.get(k) or {}).get('drift')]
out={'paths':first,'repeat_paths':len(second),'repeat_delta':diff,'historical_shared_delta':delta,'engine':engine}
(d/'live-v4-inputs.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
print(len(first),len(second),diff,list(delta))
