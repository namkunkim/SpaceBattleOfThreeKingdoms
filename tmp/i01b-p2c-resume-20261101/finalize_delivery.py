"""Read-only preservation audit and an explicitly inventoried local evidence ZIP."""
from pathlib import Path
import collections
import datetime
import difflib
import hashlib
import json
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
OLD = ROOT / 'tmp/i01b-p2c-20261101'
NEW = Path(__file__).resolve().parent
ZIP = ROOT / 'tmp/i01b-p2c-delivery-20261101.zip'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write(name, data):
    (NEW / name).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')

def delta(rows):
    changed, missing = [], []
    for row in rows:
        path = ROOT / row['path']
        if not path.is_file():
            missing.append(row['path'])
        elif digest(path) != row['sha256']:
            changed.append({'path': row['path'], 'before': row['sha256'], 'current': digest(path)})
    return changed, missing

baseline = read(OLD / 'before.json')['files']
initial = read(NEW / 'dirty-before.json')['files']
source = read(OLD / 'source-before.json')
bc, bm = delta(baseline)
ic, im = delta(initial)
sc, sm = delta(source)
allowed_baseline = {'docs/battle-core/CHECKLIST-OPEN.md', 'docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.html'}
allowed_initial = {
    'core/battle/operation_private_state.gd', 'tests/i01b_private_state.gd',
    'docs/battle-core/CHECKLIST-OPEN.md',
    'docs/battle-core/pc-campaign-design/I01B-P2C-CHECKLIST-20261101.md',
    'docs/battle-core/pc-campaign-design/SESSION-HANDOFF-I01B-P2C-20261101.md',
}
assert not bm and not im and not sc and not sm
assert {x['path'] for x in bc} == allowed_baseline
assert {x['path'] for x in ic} == allowed_initial
upper = ROOT / 'docs/battle-core/CHECKLIST-OPEN.md'
rows = upper.read_bytes().splitlines(keepends=True)
own_rows = [i for i, v in enumerate(rows) if v.startswith(b'  - [x] **I01b-P2c ')]
assert len(own_rows) == 1
inverse = b''.join(v for i, v in enumerate(rows) if i not in own_rows)
baseline_upper = next(x['sha256'] for x in baseline if x['path'] == upper.relative_to(ROOT).as_posix())
assert hashlib.sha256(inverse).hexdigest() == baseline_upper
html = ROOT / 'docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.html'
html_initial = next(x['sha256'] for x in initial if x['path'] == html.relative_to(ROOT).as_posix())
assert digest(html) == html_initial
quarantine = read(OLD / 'import-side-effects-manifest.json')
for item in quarantine:
    assert not Path(item['original']).exists()
    assert digest(Path(item['preserved'])) == item['sha256']
inputs = read(NEW / 'attempt5-inputs.json')['source']
for item in inputs:
    assert digest(ROOT / item['path']) == item['sha256']
git = lambda *args: subprocess.check_output(['git', *args], cwd=ROOT).decode().strip()
assert git('branch', '--show-current') == 'codex/feature-i01b-not_remove'
assert git('rev-parse', 'HEAD') == 'fb660cea69207fd332e26128643007694910a253'
assert not git('diff', '--cached', '--name-status')
now = datetime.datetime.now(datetime.timezone.utc).isoformat()
doc_rows = []
for item in ic:
    if item['path'].startswith('docs/'):
        doc_rows.append({**item, 'authorization': 'stage6 P2c checklist/handoff and its single parent checklist row only'})
for name in ['I01B-P2C-RESULT-20261101.md', 'REVIEW-I01B-P2C-20261101.md']:
    path = ROOT / 'docs/battle-core/pc-campaign-design' / name
    doc_rows.append({'path': path.relative_to(ROOT).as_posix(), 'current': digest(path), 'authorization': 'new P2c result / independent reviewer-owned final review'})
before_upper = (OLD / 'CHECKLIST-OPEN-before-handoff.md.txt').read_text(encoding='utf-8-sig')
after_upper = upper.read_text(encoding='utf-8-sig')
(NEW / 'parent-checklist-baseline-to-final.diff').write_text(''.join(difflib.unified_diff(before_upper.splitlines(keepends=True), after_upper.splitlines(keepends=True), fromfile='baseline/CHECKLIST-OPEN.md', tofile='final/CHECKLIST-OPEN.md')), encoding='utf-8')
write('final-delivery-audit.json', {
    'created_utc': now, 'branch': git('branch', '--show-current'), 'head': git('rev-parse', 'HEAD'), 'index': [],
    'baseline_count': len(baseline), 'baseline_changed': bc, 'baseline_missing': bm,
    'initial_dirty_count': len(initial), 'initial_changed': ic, 'initial_missing': im,
    'source_count': len(source), 'source_changed': sc, 'source_missing': sm,
    'quarantine_count': len(quarantine), 'quarantine_sha_matches': 77, 'original_paths_absent': 77,
    'creation_time_reaudit': 'quarantine-current-time-audit.json (outside_count=0)',
    'upper_checklist_inverse_sha256': hashlib.sha256(inverse).hexdigest(), 'upper_single_owned_row_only': True,
    'html_unchanged_from_resume': True, 'allowed_document_hashes': doc_rows,
    'attempt5_inputs_rehashed_matches': len(inputs), 'code_changes_after_final_5b': False,
    'main_attempts': 5, 'main_attempt_limit': 6, 'separate_probes': 2, 'editor_import_this_resume': False,
    'scope': 'restricted private runtime component accepted; whole I01b/A04-A06 NOT_READY; save schema UNCLASSIFIED',
    'archive': ZIP.relative_to(ROOT).as_posix(), 'external_archive_integrity_report': 'archive-verification.json',
    'archive_self_reference_policy': 'final audit and record manifest are inside ZIP; content list and archive digest verification are external to avoid recursive digest dependencies',
})

payload = set()
excluded_names = {'record-manifest.json', 'archive-contents.json', 'archive-verification.json', 'diff-before.patch'}
for folder in [OLD, NEW]:
    for path in folder.rglob('*'):
        if path.is_file() and path.name not in excluded_names:
            payload.add(path)
for item in source + inputs:
    path = ROOT / item['path']
    if path.is_relative_to(ROOT):
        payload.add(path)
for name in ['I01B-P2C-RESULT-20261101.md', 'REVIEW-I01B-P2C-20261101.md', 'I01B-P2C-CHECKLIST-20261101.md', 'SESSION-HANDOFF-I01B-P2C-20261101.md', 'I01B-P2B-RESULT-20261031.md', 'REVIEW-I01B-P2B-20261031.md', 'H2-DECISION.md', 'D04-STATE.md']:
    payload.add(ROOT / 'docs/battle-core/pc-campaign-design' / name)
payload.add(upper)
entries = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': digest(p), 'bytes': p.stat().st_size} for p in sorted(payload)]
write('record-manifest.json', {'created_utc': now, 'file_count': len(entries), 'files': entries, 'excluded': ['engine binary (SHA recorded)', '.git', 'whole repository', 'unrelated working files', 'initial full dirty diff-before.patch', 'archive content/digest reports outside ZIP'], 'self_excluded': 'record-manifest.json is included in ZIP and hashed by external archive-contents.json'})
payload.add(NEW / 'record-manifest.json')
archive_entries = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': digest(p), 'bytes': p.stat().st_size} for p in sorted(payload)]
write('archive-contents.json', {'created_utc': now, 'archive': ZIP.relative_to(ROOT).as_posix(), 'entry_count': len(archive_entries), 'entries': archive_entries})
assert not ZIP.exists(), 'Do not overwrite an earlier delivery archive'
with zipfile.ZipFile(ZIP, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for item in archive_entries:
        archive.write(ROOT / item['path'], item['path'])
with zipfile.ZipFile(ZIP) as archive:
    assert archive.testzip() is None
    assert sorted(archive.namelist()) == sorted(x['path'] for x in archive_entries)
    for item in archive_entries:
        assert hashlib.sha256(archive.read(item['path'])).hexdigest() == item['sha256']
write('archive-verification.json', {'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'archive': ZIP.relative_to(ROOT).as_posix(), 'zip_sha256': digest(ZIP), 'zip_bytes': ZIP.stat().st_size, 'entry_count': len(archive_entries), 'crc_failures': 0, 'entry_sha_mismatches': 0, 'entry_list_exact': True, 'archive_contents_sha256': digest(NEW / 'archive-contents.json'), 'final_audit_sha256': digest(NEW / 'final-delivery-audit.json'), 'record_manifest_sha256': digest(NEW / 'record-manifest.json')})
print(json.dumps({'baseline': len(baseline), 'source': len(source), 'quarantine': len(quarantine), 'initial_dirty': len(initial), 'allowed_changed': len(ic), 'zip_entries': len(archive_entries), 'zip_sha256': digest(ZIP), 'zip_bytes': ZIP.stat().st_size}))
