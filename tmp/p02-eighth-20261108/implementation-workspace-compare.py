from stage import *
from collections import Counter
names=['baseline-longpaths-03.json','implementation-workspace-pre.json','implementation-workspace-post.json']
obs=[json.loads((D/x).read_bytes()) for x in names]
steps=[]
for (an,a),(bn,b) in zip(zip(names,obs),zip(names[1:],obs[1:])):
 old,new=a['paths'],b['paths']
 paths=sorted(n for n in set(old)|set(new) if old.get(n)!=new.get(n))
 steps.append(dict(before=an,after=bn,metadata_equal=a['after']==b['before'],classes=dict(Counter('p03_path' if n.startswith('tmp/p03-') else 'other_path' for n in paths)),delta={n:[old.get(n),new.get(n)] for n in paths},before_scan_drift=a['list_drift'],after_scan_drift=b['list_drift']))
dump(D/'workspace-timed-delta.json',steps)
print([(x['before'],x['after'],x['metadata_equal'],x['classes']) for x in steps])
