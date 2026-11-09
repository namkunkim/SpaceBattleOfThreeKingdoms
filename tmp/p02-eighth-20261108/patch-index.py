from stage import *
from difflib import unified_diff
out=[]
for n in (O,F,A):
 a=(T/'before'/n).read_text(encoding='utf-8').splitlines(keepends=True)
 b=(T/'after'/n).read_text(encoding='utf-8').splitlines(keepends=True)
 out += list(unified_diff(a,b,fromfile='a/'+n,tofile='b/'+n))
(D/'candidate-product.patch').write_text(''.join(out),encoding='utf-8',newline='\n')
a=json.loads((T/'source.json').read_bytes())
b=json.loads((T/'after.json').read_bytes())
i=json.loads((T/'instrumented-k4.json').read_bytes())
dump(D/'candidate-path-audit.json',dict(paths=len(a),changed={n:[a[n],b[n]] for n in a if a[n]!=b[n]},instrument_changed={n:[b[n],i[n]] for n in b if b[n]!=i[n]},patch_sha=sha(D/'candidate-product.patch')))
