import hashlib,json,pathlib
d=pathlib.Path(__file__).resolve().parent
k4=d/'k4-current';k5=d/'k5-world-retry'
def read(p):return json.loads(p.read_bytes())
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def process(root):
 out={}
 for p in sorted(root.glob('*/process.json')):
  q=read(p)
  err=(p.parent/'stderr').read_text(encoding='utf8',errors='replace')
  q['diagnostics']=[l for l in err.splitlines() if l.startswith(('ERROR:','WARNING:','SCRIPT ERROR:'))]
  out[p.parent.name]=q
 return out
proof=read(k4/'preflight.json')
fixed=read(k4/'fixed-trace-comparison.json')
world={}
for lane in ('complete','cancel'):
 xs=[read(k5/f'{s}-{lane}/result.json') for s in ('before','after')]
 assert all(all(r['ok'] for r in x) for x in xs)
 bs,as_=xs
 assert len(bs)==len(as_) and [r['assertion'] for r in bs]==[r['assertion'] for r in as_]
 world[lane]={'checks_per_side':len(bs),'brief':next(r['details']['brief'] for r in bs if r['assertion']=='sortie-brief')}
 assert world[lane]['brief']==next(r['details']['brief'] for r in as_ if r['assertion']=='sortie-brief')
 if lane=='complete':
  be,ae=[next(r['details'] for r in x if r['assertion']=='result-join') for x in xs]
  assert be==ae and be['fingerprint']==be['outcome']['fingerprint'] and be['show_count']==1
  world[lane]['result']=be
gui={}
for lane in ('mouse','key'):
 p=k4/f'after-routed-{lane}'
 rows=[json.loads(x) for x in (p/'result.json').read_bytes().splitlines()]
 assert rows[0]['focus'].endswith('/ExitBattlePrepareError') and not rows[0]['host_process']
 assert rows[-1]=={'brief_null':True,'last_difficulty':'표준','last_mode':'auto','outcome_null':True,'phase':'return','scene':'res://scenes/WorldMap.tscn'}
 assert rows[-2]['type']==lane and rows[-2]['code']==(1 if lane=='mouse' else 4194309)
 cmd=read(p/'command.json');proc=read(p/'process.json')
 assert proc['exit']==0 and not proc['timeout'] and proc['inputs_unchanged']
 assert cmd['user_before']['settings.cfg']==proc['user_after']['settings.cfg']
 assert not any('battle_traces/' in k for k in proc['user_after'])
 gui[lane]={'records':rows,'hwnd':1052082 if lane=='mouse' else 4721236,'os_action':'Sky.click' if lane=='mouse' else 'Sky.press_key Return'}
report={'k4':process(k4),'k5':process(k5),'world_product':world,'routed':gui,'fixed':{k:fixed[k] for k in ('fixed_seed','fixed_rng_input','fixed_equal','fixed_rows_per_process','mutations','ignored','startup_matched','startup_totals','startup_strict','historical_startup_strict')},'owner_delta':proof['drift'],'cases_sha256':h(d/'K4-CASES.txt')}
(d/'K4-K5-OBSERVATIONS.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(len(report['k4']),len(report['k5']),world['complete']['result']['fingerprint'])
