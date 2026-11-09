from pathlib import Path
src=Path(__file__).with_name('k4-compare.py').read_text(encoding='utf-8-sig')
exec(src.split('def inspect():')[0])
before,bdata=tr('before')
after,adata=tr('after')
assert before==after and bdata==adata
negative=[]
for field,value in [('control','wrong-control'),('pos',[123456,654321])]:
 change=json.loads(canonical(after))
 change['data']['fleet_state'][0][field]=value
 assert change!=before
 negative.append({'field':field,'value':value,'rejected':True})
x,y=startup('before'),startup('after')
result={'fixed_seed':adata['seed'],'fixed_rng_input':adata['rng_seed'],'fixed_equal':True,'fixed_rows_per_process':[1,1],'fixed_row':after,'fallback_and_roster':adata,'mutations':negative,'ignored':['wall_time','mono_ms'],'startup_matched':sum((x&y).values()),'startup_totals':[sum(x.values()),sum(y.values())],'startup_strict':x==y,'startup_unmatched':[[json.loads(k) for k in (x-y).elements()],[json.loads(k) for k in (y-x).elements()]],'historical_startup_strict':'7/8'}
assert read(d/'before-common/result.json')==read(d/'after-common/result.json')
(d/'fixed-trace-comparison.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
print({k:result[k] for k in ('fixed_seed','fixed_equal','startup_matched','startup_totals','startup_strict')})
