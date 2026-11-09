import subprocess, hashlib, json, pathlib, sys
def git(*args):
    return subprocess.check_output(['git',*args])
def sha(p):
    if not p.is_file():
        return None
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1048576),b''): h.update(b)
    return h.hexdigest()
mode=sys.argv[1]
out=pathlib.Path('tmp/pc-first-operation-contract-20261109')
def snapshot():
    status=git('status','--porcelain=v1','-z','-uall').decode().split('\0')[:-1]
    assert all(s[:2].strip() not in ('R','C') for s in status)
    return {'head':git('rev-parse','HEAD').decode().strip(),
            'branch':git('branch','--show-current').decode().strip(),
            'index':sha(pathlib.Path('.git/index')),
            'staged':git('diff','--cached','--name-only').decode(),
            'class_cache':sha(pathlib.Path('.godot/global_script_class_cache.cfg')),
            'dirty':{s[3:]:[s[:2],sha(pathlib.Path(s[3:]))] for s in status if not s[3:].startswith(out.as_posix()+'/')}}
data=snapshot()
out.mkdir(exist_ok=True)
if mode=='before':
    (out/'before.json').open('x',encoding='utf-8').write(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
else:
    old=json.loads((out/'before.json').read_text(encoding='utf-8'))
    assert old==data, 'baseline drift'
print({k:v for k,v in data.items() if k!='dirty'}, len(data['dirty']))
