import json,pathlib,collections
d=pathlib.Path('tmp/p02-seventh-20261108')
def traces(stage):
 p=d/stage/'common/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces'
 return [[{k:v for k,v in json.loads(x).items() if k not in ('wall_time','mono_ms')} for x in f.read_bytes().splitlines()] for f in sorted(p.glob('*.jsonl'))]
a,b=map(traces,('before-attempt-01','after-attempt-02'))
print(len(a),len(b),[len(x) for x in a],[len(x) for x in b])
for i,(x,y) in enumerate(zip(a,b)):
 for j,(u,v) in enumerate(zip(x,y)):
  if u!=v:
   diff={k:[u.get(k),v.get(k)] for k in set(u)|set(v) if u.get(k)!=v.get(k)}
   if 'data' in diff: diff['data']={k:[u['data'].get(k),v['data'].get(k)] for k in set(u['data'])|set(v['data']) if u['data'].get(k)!=v['data'].get(k)}
   print(i,j,str(diff)[:550]);break
