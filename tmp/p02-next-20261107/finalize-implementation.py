from pathlib import Path
import hashlib,json
e=Path('tmp/p02-next-20261107')
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
out=e/'attempt3'
results=load(out/'results.json')
diagnostics={}
for name in ('world-before','world-after','world-stock'):
 row=load(out/f'{name}.exit.json')
 diagnostics[name]={'exit':row['actual_exit'],'counts':row['diagnostics'],'stderr_sha256':digest(out/f'{name}.stderr'),'stdout_has_pass':'WORLD_LINK_PASS' in (out/f'{name}.stdout').read_text(encoding='utf-8')}
assert results['passed'] and len(results['rows'])==53
assert diagnostics['world-before']['stderr_sha256']==diagnostics['world-after']['stderr_sha256']
assert all(x['counts']=={'script_errors':0,'errors':1,'warnings':1} and x['exit']==0 and x['stdout_has_pass'] for x in diagnostics.values())
assert all(not any(r['diagnostics'].values()) for r in results['rows'] if r['label'] not in diagnostics)
def stat(p): return {'bytes':p.stat().st_size,'sha256':digest(p)}
manifest={
 'plan':stat(e/'PLAN.md'),
 'review_plan':stat(e/'REVIEW-PLAN-INDEPENDENT.md'),
 'stage':'5-a pass; independent implementation and closeout decisions pending',
 'results':{'attempt':3,'subprocesses':len(results['rows']),'expected_0':sum(r['actual_exit']==0 for r in results['rows']),'expected_1':sum(r['actual_exit']==1 for r in results['rows']),'comparisons':results['comparisons'],'world_legacy_diagnostics':diagnostics},
 'owned_sources':{str(p):stat(p) for p in [Path('scripts/world/auto_resolver.gd'),Path('tests/autoresolve.gd'),Path('tests/p02_worker_adapter.gd'),*Path('tests/fixtures/p02').glob('worker-*.json')]},
 'records':{p.relative_to(e).as_posix():stat(p) for p in sorted(set([e/'owned-diff-proof.json',e/'preservation.json',e/'preservation-stop.json',e/'fixture-provenance.json',e/'IMPLEMENTATION-5A-NOTES.md', e/'baseline-files.json', e/'baseline-context.json',e/'preimplementation-inputs.json',*e.glob('*.owned.diff'),*e.glob('post-*.*'),*e.glob('attempt?/**/*')])) if p.is_file()}
}
(e/'implementation-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(manifest['results'],ensure_ascii=False,indent=2))


