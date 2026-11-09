import collections, hashlib, json, pathlib
d=pathlib.Path(__file__).resolve().parent
def norm(stage, seed=False):
 p=d/stage/'common/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces'
 rows=[]
 for f in p.glob('*.jsonl'):
  a=[{k:v for k,v in json.loads(x).items() if k not in ('wall_time','mono_ms')} for x in f.read_bytes().splitlines()]
  if seed and len(a)==1 and a[0]['kind']=='session_start':
   a[0]['data'].pop('seed',None)
  rows.append(json.dumps(a,sort_keys=True,ensure_ascii=False))
 return collections.Counter(rows)
a,b='before-attempt-01','after-attempt-02'
x,y=norm(a),norm(b)
m1,m2=list((x-y).elements()),list((y-x).elements())
report={'matched_files':sum((x&y).values()),'before_unmatched':[json.loads(t) for t in m1],'after_unmatched':[json.loads(t) for t in m2],'strict_pass':x==y,'diagnostic_only_ignoring_seed':norm(a,True)==norm(b,True)}
(d/'trace-comparison-detail.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(report['matched_files'],report['strict_pass'],report['diagnostic_only_ignoring_seed'],[(t[0]['kind'],t[0]['data'].get('seed')) for t in report['before_unmatched']+report['after_unmatched']])
