import collections, hashlib, json, pathlib
d=pathlib.Path(__file__).resolve().parent/'k4-current'
def read(p):return json.loads(p.read_bytes())
def rows(f):return [json.loads(x) for x in f.read_bytes().splitlines()]
def norm(r):return {k:v for k,v in r.items() if k not in ("wall_time","mono_ms")}
def canonical(o):return json.dumps(o,sort_keys=True,ensure_ascii=False)
def tr(stage):
 p=d/(stage+'-fixed'); m=read(p/'result.json'); raw=rows(pathlib.Path(m['trace']))
 assert read(p/'process.json')['exit']==0
 assert len(raw)==1 and raw[0]['seq']==1 and raw[0]['kind']=='session_start'
 assert raw[0]['data']['seed']==m['seed']==m['expected_candidate_seed']
 assert m['rng_seed']==27182818 and m['seq']==1 and m['result']=={'ok':True} and not m['routed']
 assert m['message']=='시나리오를 읽지 못해 시험 전장으로 엽니다'
 assert raw[0]['data']['profile_path']==m['path']=='res://data/profiles/p02_sixth_missing.json'
 assert m['trace']!=m['initial_trace']
 (p/'fixed-session-start.jsonl').write_bytes(pathlib.Path(m['trace']).read_bytes())
 (p/'startup-and-close.jsonl').write_bytes(pathlib.Path(m['initial_trace']).read_bytes())
 return norm(raw[0]),{k:v for k,v in m.items() if k not in ('trace','initial_trace','pid')}
def startup(stage):
 root=d/(stage+'-common')/'roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces'
 return collections.Counter(canonical([norm(r) for r in rows(p)]) for p in root.glob('*.jsonl'))
def inspect():
 for p in sorted(d.glob('*/process.json')):
  data=read(p); err=(p.parent/'stderr').read_text(encoding='utf8',errors='replace')
  print(p.parent.name,data['exit'],data['timeout'],[l for l in err.splitlines() if l.startswith(('ERROR:','SCRIPT ERROR:','WARNING:'))])
 b,bo=tr('before');a,ao=tr('after')
 assert a==b and ao==bo
 for field,value in [('control','wrong-control'),('pos',[123456,654321])]:
  changed=json.loads(canonical(a)); changed['data']['fleet_state'][0][field]=value
  assert changed!=b
 x,y=startup('before'),startup('after')
 result={'fixed_strict_pass':True,'fixed_row':a,'mutations_rejected':['control','pos'],'startup_strict_match':sum((x&y).values()),'startup_totals':[sum(x.values()),sum(y.values())],'startup_unmatched':[[json.loads(k) for k in (x-y).elements()],[json.loads(k) for k in (y-x).elements()]],'historical_startup_strict':'7/8'}
 assert read(d/'before-common/result.json')==read(d/'after-common/result.json')
 for lane in ['complete','cancel']:
  bs=read(d/f'before-world-{lane}/result.json');as_=read(d/f'after-world-{lane}/result.json')
  result[f'world_{lane}']={'before':bs,'after':as_}
  assert len(bs)==len(as_) and all(r['ok'] for r in bs+as_)
  assert [r['details'] for r in bs if r['assertion'] in ('sortie-brief','result-join')]==[r['details'] for r in as_ if r['assertion'] in ('sortie-brief','result-join')]
  if lane=='complete':
   final=next(r['details'] for r in as_ if r['assertion']=='result-join')
   assert final['fingerprint']==final['outcome']['fingerprint']
 (d/'comparison.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
inspect()
