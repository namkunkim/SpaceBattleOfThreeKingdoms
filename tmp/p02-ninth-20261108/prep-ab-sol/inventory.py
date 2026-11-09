import hashlib, json, re, subprocess, zipfile
from pathlib import Path

out = Path(__file__).parent
def git(*argv):
    return subprocess.check_output(['git', *argv])
def sha(value):
    return hashlib.sha256(value).hexdigest()
def ref_file(p):
    f = Path(p)
    return dict(path=p, sha256=sha(f.read_bytes()) if f.is_file() else None)

entries = {
    'p02_headless_adapter': ('p02-first-headless-delivery-20261107-correction.zip', 'p02-first-headless-delivery-20261107.zip'),
    'p02_worker_adapter': ('P02-WORKER-DELIVERY-20261107.zip',),
    'p02_replay_adapter': ('P02-REPLAY-DELIVERY-20261108.zip',),
    'p02_viewer_events': ('P02-VIEWER-EVENTS-DELIVERY-20261108.zip',),
    'i01b_private_state': ('i01b-p2c-delivery-20261101.zip','i01b-active-replace-delivery-20261104.zip'),
    'i01b_service_state': ('i01b-p2c-delivery-20261101.zip','i01b-active-replace-delivery-20261104.zip'),
    'i01b_active_replace': ('i01b-active-replace-delivery-20261104.zip',),
}
manifest = Path('tmp/p02-eighth-resume-8d838216ccfc/prepared/MANIFEST-V5-REVIEW-ONLY.json')
jobs = json.loads(manifest.read_bytes())['jobs']
def snapshot():
    watched = ['core/battle/operation_private_state.gd','tests/p02_worker_adapter.gd', *(f'tests/{k}.gd' for k in entries)]
    return dict(head=git('rev-parse','HEAD').decode().strip(),
                index_entries_sha256=sha(git('ls-files','--stage','-z')),
                staged=git('diff','--cached','--name-status').decode(),
                tracked_diff_sha256=sha(git('diff','--binary','--no-ext-diff')),
                watched={p:ref_file(p)['sha256'] for p in dict.fromkeys(watched)},
                status_porcelain_sha256=sha(git('status','--porcelain=v1','-z','--untracked-files=normal')))
before = snapshot()
report = dict(status='static source evidence; zero executed cases', plan=ref_file('tmp/p02-ninth-20261108/NEXT-PLAN.md'),
              manifest=ref_file(str(manifest)), model='gpt-6.1-sol', model_source='nodeRepl.requestMeta[x-codex-turn-metadata].model',
              before=before, suites={})
tracked = set(git('ls-tree','-r','--name-only','HEAD').decode().splitlines())
for suite, zipnames in entries.items():
    p = f'tests/{suite}.gd'
    wt = Path(p).read_bytes()
    h = git('show',f'HEAD:{p}') if p in tracked else None
    versions = dict(worktree=sha(wt), head=sha(h) if h is not None else None, packages=[])
    payloads = {}
    for name in zipnames:
        archive = Path('tmp')/name
        with zipfile.ZipFile(archive) as z:
            if p in z.namelist():
                payloads[name] = z.read(p)
        data = payloads.get(name)
        versions['packages'].append(dict(archive=ref_file(str(archive)), member=p,
            member_sha256=sha(data) if data is not None else None,
            exact_worktree=data==wt, exact_head=h is not None and data==h))
    canonical = h if h is not None else next(iter(payloads.values()))
    lines = canonical.decode('utf-8-sig').splitlines()
    funcs = {}
    literals = {}
    func = None
    for num, line in enumerate(lines,1):
        if line.startswith('func '):
            func = line.split('(')[0][5:]
            funcs[func] = dict(declaration=line, line=num, gates=[], calls=[])
        if func and line.startswith('\t'):
            if re.search(r'\b(?:check|_check|require|assert|quit|push_error)\(',line) or re.match(r'\s*(?:if|elif|else|while|for|match|return|continue|break)\b',line) or 'await ' in line:
                funcs[func]['gates'].append([num,line])
            calls = re.findall(r'(?<![\w.])([A-Za-z_]\w*)\(',line)
            funcs[func]['calls'].extend([num,c] for c in calls)
        for r in re.findall(r'"res://([^"]+)"',line):
            literals[r] = ref_file(r)
    for details in funcs.values():
        details['calls'] = [c for c in details['calls'] if c[1] in funcs]
    report['suites'][suite] = dict(source=p, canonical_sha256=sha(canonical), canonical_locator=f'HEAD:{p}' if h is not None else f'{next(iter(payloads))}:{p}',
        versions=versions, literal_resource_paths=literals, functions=funcs, manifest_jobs=[j for j in jobs if j.get('case_id')==suite and j.get('process_id','').startswith('19-')])
for leaf in ('oracle.native',*(f'matrix/{x}.json' for x in ['commands','reordered','removed','defaults','one-tick','natural','direct','delegate','late','order','policy','limit','rows','commands-shape'])):
    report.setdefault('replay_dynamic_resources',[]).append(ref_file(f'tmp/p02-third-20261108/{leaf}'))
report['after'] = snapshot()
report['observed_snapshot_equal'] = before == report['after']
(out/'source-evidence.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
