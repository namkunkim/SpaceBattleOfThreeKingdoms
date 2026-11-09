from stage import *
from collections import Counter
P=D/'k6-proposed-not-run'
P.mkdir(exist_ok=True)
S=R/'tmp/p02-seventh-20261108'
H=R/'tmp/p02-sixth-20261108'
defs={
 'native':(D/'native-probe-k3.gd',320),
 'alias':(D/'alias-k6-draft.gd',320),
 'retry':(D/'retry-terminal-k6.gd',630),
 'world-complete':(S/'k5-world-product.gd',320),
 'world-cancel':(S/'k5-world-product.gd',320),
 'world-clean':(H/'world-probe.gd',320),
 'world-returning':(H/'world-probe.gd',320),
 'injected':(D/'injected-probe.gd',320),
}
regression=['battle_flow','autoresolve','p02_headless_adapter','p02_worker_adapter','p02_replay_adapter','p02_viewer_events','i01b_private_state','i01b_service_state','i01b_active_replace']
replay=R/'tmp/p02-third-20261108'
supplemental=[R/'tools/scenario/cross_counter_drill.gd',replay/'oracle.native',*sorted((replay/'matrix').glob('*.json'))]
out_dirs=['i01b-next-20261031','i01b-active-replace-20261102','p02-first-integration-20261105','i01b-p2c-resume-20261101']
jobs=[]
for stage in ('before','after','instrumented'):
 tests=list(defs)+regression if stage in ('before','after') else ['injected','retry']
 tests=[x for x in tests if x!='injected' or stage=='instrumented']
 project=T/('instrumented-k4' if stage=='instrumented' else stage)
 for case in tests:
  dest=P/(stage+'-'+case)
  probe,timeout=defs.get(case,(None,630))
  relative=('res://_p02_k6_'+case.replace('-','_')+'.gd') if probe else 'res://tests/'+case+'.gd'
  args=[str(E),'--headless','--path',str(project),'--script',relative]
  if case=='native':args+=['--',stage,str(dest/'observations.gdvar')]
  if case=='retry':args+=['--',stage,str(dest/'observations.gdvar')]
  if case=='alias':args+=['--',str(dest/'observations.gdvar')]
  if case in ('world-complete','world-cancel'):args+=['--',case.split('-')[1],str(dest/'result.json')]
  if case in ('world-clean','world-returning'):args+=['--',str(dest/'result.json')]
  jobs.append(dict(stage=stage,case=case,probe=str(probe) if probe else None,probe_sha=sha(probe) if probe else sha(project/('tests/'+case+'.gd')),args=args,timeout_seconds=timeout,expected_exit=1 if case=='world-clean' else 0,user_config=str(H/'returning-settings.cfg') if case.startswith('world-') and case!='world-clean' else None,env={'APPDATA':str(dest/'roaming'),'LOCALAPPDATA':str(dest/'local'),'XDG_DATA_HOME':str(dest/'roaming'),'SBTK_SAFE_INSETS':'0,0,0','P02_PROBE_MODE':''}))
inputs={str(x):sha(x) for x in [D/'PLAN.md',D/'PLAN-v2.md',D/'REVIEW-PLAN-V2-INDEPENDENT.md',D/'K6-PREFLIGHT-DRAFT.md',Path(__file__),D/'gui8-k6-draft.gd',H/'returning-settings.cfg',T/'source.json',T/'after.json',T/'instrumented-k4.json',T/'engine.json',*supplemental,*[x for x,t in defs.values()]]}
dump(P/'proposed-jobs.json',dict(status='DRAFT_ONLY_NO_EXECUTION',jobs=jobs,inputs=inputs,copy_supplemental_rel_paths=[str(x.relative_to(R)) for x in supplemental],create_replica_output_dirs=['tmp/'+x for x in out_dirs],blocked_rows=[5,12,15,16],missing_per_row_details=[1,2,3,4,9,10,13,14],gui_block='No documented independent current owner PID/foreground/rect in Sky window API. No inputs permitted.'))
print(len(jobs),sha(P/'proposed-jobs.json'))
