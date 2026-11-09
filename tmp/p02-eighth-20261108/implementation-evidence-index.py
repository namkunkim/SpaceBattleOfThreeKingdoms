from stage import *
from collections import Counter
attempts=[]
for k in range(1,6):
 p=D/f'gate-k{k}'
 rows=[]
 for d in sorted(p.iterdir()):
  if not d.is_dir():continue
  info={}
  for f in ('process.json','stdout','stderr','command.json','pid.json','result.json','observations.gdvar'):
   q=d/f
   if not q.is_file():continue
   info[f]=dict(sha256=sha(q),bytes=q.stat().st_size)
   if f=='process.json':info[f].update(json.loads(q.read_bytes()))
   if f in ('stdout','stderr'):
    s=q.read_text(encoding='utf-8',errors='replace')
    info[f].update(assert_ok=sum(l.startswith('ASSERT ') and l.endswith(' true') for l in s.splitlines()),assert_false=sum(l.startswith('ASSERT ') and l.endswith(' false') for l in s.splitlines()),os_mouse=sum(l.startswith('P02_GUI ["OS_MOUSE"') for l in s.splitlines()),os_key=sum(l.startswith('P02_GUI ["OS_KEY"') for l in s.splitlines()),diagnostics=[l for l in s.splitlines() if l.startswith(('ERROR:','SCRIPT ERROR:','WARNING:'))])
  rows.append(dict(path=d.relative_to(D).as_posix(),files=info))
 attempts.append(dict(attempt=k,rows=rows,preflight=sha(p/'preflight.json') if (p/'preflight.json').is_file() else None,postflight=sha(p/'postflight.json') if (p/'postflight.json').is_file() else None))
dump(D/'implementation-evidence-index.json',attempts)
for a in attempts:
 print(a['attempt'],len(a['rows']),Counter(str(row['files'].get('process.json',{}).get('exit')) for row in a['rows']))
for g,n in (('gate-k3','native'),('gate-k4','world-complete'),('gate-k4','world-cancel')):
 f='observations.gdvar' if n=='native' else 'result.json'
 a=(D/g/('before-'+n)/f).read_bytes()
 b=(D/g/('after-'+n)/f).read_bytes()
 print(g,n,len(a),len(b),b.startswith(a) if n=='native' else a==b)
