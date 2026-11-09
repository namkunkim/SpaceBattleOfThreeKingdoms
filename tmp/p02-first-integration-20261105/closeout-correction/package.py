from pathlib import Path
import difflib, hashlib, json, re, subprocess, zipfile
out = Path(__file__).resolve().parent
ev = out.parent
root = ev.parents[1]
zip_path = root / 'tmp/p02-first-headless-delivery-20261107-correction.zip'
def sha(data):
    return hashlib.sha256(data).hexdigest()
def dig(path):
    return sha(path.read_bytes())
def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))
def write(path, obj):
    with path.open('x', encoding='utf-8') as stream:
        json.dump(obj, stream, ensure_ascii=False, indent=2)
def name(path):
    return path.relative_to(root).as_posix()
def rows(paths):
    return [dict(path=name(p), bytes=p.stat().st_size, sha256=dig(p)) for p in sorted(set(paths))]
def delta(original):
    return [r['path'] for r in original if not (root / r['path']).is_file() or dig(root / r['path']) != r['sha256']]
proof = read(out / 'document-proof.json')
audit0 = read(ev / 'final-delivery-audit.json')
review = ev / 'REVIEW-5B-NON-ASTRA-20261107.md'
allowed = {'P02-FIRST-HEADLESS-RESULT-20261107.md': [1,3,47,49,51], 'P02-FIRST-HEADLESS-CHECKLIST-20261107.md':[3,10,11,13,20], 'SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md':[3,21,34,36], 'SESSION-REQUIREMENTS-CHECKLIST-20261031.md':[5,74,103,107,109], 'CHECKLIST-OPEN.md':[35]}
for r in proof['documents']:
    path = root / r['path']
    original = (out / (path.name + '.before.txt')).read_bytes()
    assert sha(original) == r['before_sha256']
    before = original.decode().splitlines(keepends=True)
    current = path.read_bytes().decode().splitlines(keepends=True)
    if path.name == 'SESSION-REQUIREMENTS-CHECKLIST-20261031.md':
        current[21] = before[21]
    if path.name == 'P02-FIRST-HEADLESS-RESULT-20261107.md':
        current[2] = current[2].replace('비-Astra 독립 5b 및 마감 재심사 수용은 보류 중이다.', '[비-Astra 독립 5b](../../../tmp/p02-first-integration-20261105/REVIEW-5B-NON-ASTRA-20261107.md)에서 구현의 차단 반례를 발견하지 못했고, 문서·마감은 반려되어 정정본 재심사를 기다린다.')
    if path.name == 'P02-FIRST-HEADLESS-CHECKLIST-20261107.md':
        current[9] = '- [ ] 5b [비-Astra 독립 구현 검토](../../../tmp/p02-first-integration-20261105/REVIEW-5B-NON-ASTRA-20261107.md)에서 차단 반례 미발견. gpt-6.1-sol 구현과 gpt-6.1-terra 검토는 별도 실제 세션이다. 과거 gpt-6-astra 심사는 이력으로 보존한다. 문서·마감 반려 후 정정본 재심사 대기.\n'
        current[10] = '- [ ] 6 결과·체크리스트·인계와 상위 P02 행을 정정하고 감사·manifest·ZIP 검증을 동결했다. 독립 마감 재심사 대기.\n'
    if path.name == 'SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md':
        current[2] = current[2].replace('비-Astra 독립 5b와 마감 재심사는 수용 보류 중이다.', '[비-Astra 독립 5b](../../../tmp/p02-first-integration-20261105/REVIEW-5B-NON-ASTRA-20261107.md)는 구현 범위에서 차단 반례를 발견하지 못했고, 문서·마감 정정본 재심사를 기다린다.')
    edits = [i+1 for i, pair in enumerate(zip(before,current)) if pair[0]!=pair[1]]
    assert len(before) == len(current) and edits == allowed[path.name]
    path.write_bytes(''.join(current).encode())
    r.update(lines=edits, after_sha256=dig(path), inverse_sha256=sha(''.join(before[i] if i+1 in edits else l for i,l in enumerate(current)).encode()))
    assert r['inverse_sha256'] == r['before_sha256']
    with (out / (path.name + '.final.diff')).open('xb') as stream:
        stream.write(''.join(difflib.unified_diff(before,current,fromfile=name(path),tofile=name(path))).encode())
write(out / 'final-document-proof.json', proof)
baseline = read(ev / 'baseline-files.json')
assert set(delta(baseline)) == {r['path'] for r in audit0['changed']}
source = read(root / 'tmp/i01b-p2c-20261101/source-before.json')
assert not delta(source)
quarantine = read(root / 'tmp/i01b-p2c-20261101/import-side-effects-manifest.json')
assert all(not Path(r['original']).exists() and dig(Path(r['preserved'])) == r['sha256'] for r in quarantine)
inputs = read(ev / 'attempt3-suite-inputs.json')['inputs']
assert not delta(inputs)
pre = read(ev / 'record-manifest-pre-review.json')['files']
assert not delta(pre)
old = read(ev / 'record-manifest.json')['files']
assert set(delta(old)) == {r['path'] for r in proof['documents']}
for r in proof['documents']:
    assert next(item['sha256'] for item in old if item['path'] == r['path']) == r['before_sha256']
cache = root / '.godot/global_script_class_cache.cfg'
html = root / 'docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.html'
assert dig(cache) == audit0['cache_sha256'] and dig(html) == audit0['html_sha256']
past = audit0['prior_archive_sha256'] | {'tmp/p02-first-headless-delivery-20261107.zip': read(ev / 'archive-verification.json')['zip_sha256']}
for path, digest in (past | audit0['final_code']).items():
    assert dig(root / path) == digest
git = lambda *args: subprocess.check_output(['git', *args],cwd=root).decode().strip()
assert git('rev-parse','HEAD') == audit0['head'] and git('branch','--show-current') == audit0['branch']
assert not git('diff','--cached','--name-only')
check = subprocess.run(['git','diff','--check'],cwd=root,capture_output=True)
with (out / 'final-full-diff-check.log').open('xb') as f:
    f.write(check.stdout + check.stderr)
diag = r'CHECKLIST-OPEN\.md:(\d+): trailing whitespace'
assert proof['before_exit'] == proof['after_exit'] == check.returncode == 2
assert re.findall(diag,(out/'before-full-diff-check.log').read_text(encoding='utf-8')) == ['33','35']
assert re.findall(diag,check.stdout.decode()) == ['33']
assert b'CHECKLIST-OPEN.md:35' not in check.stdout
links_pending = {out / 'audit.json', out / 'manifest.json', out / 'archive-verification.json', zip_path}
for r in proof['documents'][:3]:
    for dest in re.findall(r'\]\(([^)]+)\)', (root/r['path']).read_text(encoding='utf-8')):
        path = ((root/r['path']).parent / dest).resolve()
        assert path.exists() or path in links_pending, (r['path'],dest)
write(out / 'audit.json', dict(
    stage='correction package awaiting independent closeout', review=name(review), review_sha256=dig(review),
    implementation_model='gpt-6.1-sol', review_model='gpt-6.1-terra', review_session='01a1b5b5-7f97-7232-a17a-5aefa63cbc20',
    historical_review_model='gpt-6-astra', historical_review_role='history',
    implementation_review='no blocking counterexample found in scope; documents and closeout returned for correction',
    baseline_count=len(baseline), baseline_delta=delta(baseline), source_count=len(source), source_mismatches=[],
    quarantine_count=len(quarantine), quarantine_mismatches=[], quarantine_originals_present=[],
    attempt3_input_count=len(inputs), attempt3_input_mismatches=[], pre_review_manifest_count=len(pre),
    code_sha256=audit0['final_code'], prior_archive_sha256=past, html_sha256=dig(html), cache_sha256=dig(cache),
    before_git_actual_exit=proof['before_exit'], before_diagnostics=[33,35], final_git_actual_exit=check.returncode,
    final_diagnostics=[33], git_wrapper_exit1='excluded; wrapper status differs from direct subprocess',
    overall_git_diff_check_pass=False, changed_documents=proof['documents'],
    engine_reexecution=False, branch=audit0['branch'], head=audit0['head'], index=[],
    scope='P02 limited headless opt-in correction; entire P02/I01/I01b/A04-A06 NOT_READY; external save schema UNCLASSIFIED',
    known_deviations=audit0['known_deviations']))
items = [root / r['path'] for r in old] + [ev / f for f in ('record-manifest.json','archive-verification.json','archive-contents.json')] + [review] + list(ev.glob('non-astra-diff-check.*'))
items += [p for p in out.iterdir() if p.is_file() and not (p.name.endswith('.diff') and not p.name.endswith('.final.diff')) and p.name not in {'document-proof.json','prepare.py'}]
manifest = out / 'manifest.json'
manifest_rows = rows(items)
write(manifest, dict(count=len(manifest_rows), files=manifest_rows))
contents = rows(items + [manifest])
with zipfile.ZipFile(zip_path, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for r in contents:
        z.write(root / r['path'],r['path'])
with zipfile.ZipFile(zip_path) as z:
    assert z.testzip() is None and sorted(z.namelist()) == sorted(r['path'] for r in contents)
    for r in contents:
        data = z.read(r['path'])
        assert len(data) == r['bytes'] and sha(data) == r['sha256']
write(out / 'archive-verification.json', dict(archive=name(zip_path), zip_sha256=dig(zip_path), zip_bytes=zip_path.stat().st_size, entry_count=len(contents), crc_failures=0, entry_sha_mismatches=0, entry_size_mismatches=0, entry_list_exact=True, manifest_sha256=dig(manifest), audit_sha256=dig(out/'audit.json')))
print(len(manifest_rows), len(contents), dig(zip_path))
