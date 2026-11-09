import collections, json, hashlib, pathlib, re
d=pathlib.Path(__file__).resolve().parent
before=d/'before-attempt-01'
after=d/'after-attempt-02'
def read(p):return json.loads(p.read_bytes())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def suites(p):
 out={}
 for x in sorted(p.glob('*/process.json')):
  err=(x.parent/'stderr').read_text(encoding='utf-8',errors='replace')
  err=[l for l in err.splitlines() if l.startswith(('ERROR:','SCRIPT ERROR:','WARNING:'))]
  out[x.parent.name]={'process':read(x),'errors':err}
 return out
def hashes(p):
 rows=collections.Counter()
 root=p/'common/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces'
 for f in root.glob('*.jsonl'):
  entries=[{k:v for k,v in json.loads(l).items() if k not in ('wall_time','mono_ms')} for l in f.read_bytes().splitlines()]
  rows[hashlib.sha256(json.dumps(entries,sort_keys=True,ensure_ascii=False).encode('utf8')).hexdigest()]+=1
 return dict(rows)
native=read(before/'common/result.json')
baseline=read(d.parent/'p02-sixth-20261108/native-oracle.json')
report={
 'common_before_matches_prior_sha':sha(before/'common/result.json')==baseline['common'],
 'common_result_equal':native==read(after/'common/result.json'),
 'common_trace_equal':hashes(before)==hashes(after),
 'common_trace_before':hashes(before),'common_trace_after':hashes(after),
 'assertions_sha':sha(d/'assertions.txt'),
 'baseline_plan_sha':sha(d/'PLAN-v2.md'),
 'before':suites(before),'after':suites(after),
 'before_world_retry':suites(d/'before-attempt-02')}
(d/'comparison-02.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print({k:v for k,v in report.items() if k.startswith('common') and not isinstance(v,dict)})
