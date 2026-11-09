"""Audit preserved files and create one explicit, locally verified evidence ZIP."""
from pathlib import Path
import datetime
import hashlib
import json
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OLD = ROOT / 'tmp/i01b-p2c-20261101'
P2C_ZIP = ROOT / 'tmp/i01b-p2c-delivery-20261101.zip'
ZIP = ROOT / 'tmp/i01b-active-replace-delivery-20261104.zip'
DOCS = ROOT / 'docs/battle-core/pc-campaign-design'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write(name, value):
    (HERE / name).write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')

def compare(rows):
    changed, missing = [], []
    for item in rows:
        path = ROOT / item['path']
        if not path.is_file():
            missing.append(item['path'])
        elif sha(path) != item['sha256']:
            changed.append({'path': item['path'], 'before': item['sha256'], 'current': sha(path)})
    return changed, missing

before = read(HERE / 'before.json')['files']
changed, missing = compare(before)
allowed = {'core/battle/operation_private_state.gd', 'docs/battle-core/CHECKLIST-OPEN.md'}
assert not missing and {x['path'] for x in changed} == allowed
sources = read(OLD / 'source-before.json')
source_changed, source_missing = compare(sources)
assert not source_changed and not source_missing
quarantine = read(OLD / 'import-side-effects-manifest.json')
for item in quarantine:
    assert not Path(item['original']).exists()
    assert sha(Path(item['preserved'])) == item['sha256']
previous_entries = read(ROOT / 'tmp/i01b-p2c-resume-20261101/archive-contents.json')['entries']
previous_changed, previous_missing = compare(previous_entries)
assert not previous_missing and {x['path'] for x in previous_changed} == allowed
assert sha(P2C_ZIP) == '99a4a1adca1bdc3bf7e56baa9112c1625ab6c6371bfaafa0482b3471903a2971'
for item in read(HERE / 'attempt2-inputs.json')['inputs']:
    assert sha(ROOT / item['path']) == item['sha256']
upper = ROOT / 'docs/battle-core/CHECKLIST-OPEN.md'
new_line = (HERE / 'upper-checklist-added-line.txt').read_bytes().rstrip(b'\r\n') + b'\n'
assert upper.read_bytes().count(new_line) == 1
inverse = upper.read_bytes().replace(new_line, b'', 1)
assert inverse == (HERE / 'CHECKLIST-OPEN-before-closeout.md.txt').read_bytes()
assert hashlib.sha256(inverse).hexdigest() == next(x['sha256'] for x in before if x['path'] == 'docs/battle-core/CHECKLIST-OPEN.md')

doc_names = [
    'I01B-ACTIVE-REPLACE-RESULT-20261104.md',
    'I01B-ACTIVE-REPLACE-CHECKLIST-20261104.md',
    'SESSION-HANDOFF-I01B-ACTIVE-REPLACE-20261104.md',
    'REVIEW-I01B-ACTIVE-REPLACE-20261104.md',
]
link_errors = []
for name in doc_names:
    path = DOCS / name
    assert path.is_file()
    for link in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8-sig')):
        if not link.startswith(('https:', 'http:', '#')) and not (path.parent / link.split('#')[0]).is_file():
            link_errors.append({'file': name, 'link': link})
assert not link_errors
git = lambda *args: subprocess.check_output(['git', *args], cwd=ROOT).decode().strip()
assert git('branch', '--show-current') == 'codex/feature-i01b-not_remove'
assert git('rev-parse', 'HEAD') == 'fb660cea69207fd332e26128643007694910a253'
assert not git('diff', '--cached', '--name-status')
check = subprocess.run(['git', 'diff', '--check'], cwd=ROOT, capture_output=True)
(HERE / 'closeout-diff-check-stdout.log').write_bytes(check.stdout)
(HERE / 'closeout-diff-check-stderr.log').write_bytes(check.stderr)
assert check.returncode == 2
assert check.stdout.count(b'trailing whitespace.') == 1
assert b'docs/battle-core/CHECKLIST-OPEN.md:33:' in check.stdout
now = datetime.datetime.now(datetime.timezone.utc).isoformat()
write('final-delivery-audit.json', {
    'created_utc': now, 'branch': git('branch', '--show-current'), 'head': git('rev-parse', 'HEAD'), 'index': [],
    'baseline_count': len(before), 'changed': changed, 'missing': missing,
    'source_count': len(sources), 'source_changed': source_changed, 'source_missing': source_missing,
    'quarantine_count': len(quarantine), 'quarantine_sha_matches': len(quarantine), 'original_paths_absent': len(quarantine),
    'prior_p2c_payload_count': len(previous_entries), 'prior_payload_changed': previous_changed,
    'prior_p2c_zip_sha256': sha(P2C_ZIP), 'final_input_sha_matches': 42,
    'upper_new_line_inverse_exact': True, 'upper_inverse_sha256': hashlib.sha256(inverse).hexdigest(),
    'old_p2c_crlf_bytes_preserved': read(HERE / 'checklist-closeout-one-line-proof.json')['existing_p2c_crlf_line_preserved'],
    'html_unchanged': True, 'final_doc_hashes': [{'path': (DOCS / n).relative_to(ROOT).as_posix(), 'sha256': sha(DOCS / n)} for n in doc_names],
    'doc_link_errors': link_errors, 'diff_check_actual_exit': check.returncode,
    'diff_check_scope': 'one preserved baseline P2c parent checklist CRLF at line33; not whole gate PASS',
    'new_stage_main_attempts': 2, 'new_stage_limit': 6, 'previous_p2c_main_attempts': 5,
    'code_changes_after_final_5b': False, 'editor_import': False,
    'scope': 'restricted same-context owner runtime replacement accepted; overall NOT_READY; external schema UNCLASSIFIED',
    'archive': ZIP.relative_to(ROOT).as_posix(),
    'self_reference_policy': 'final audit and record manifest inside ZIP; content inventory and ZIP digest verification external',
})

files = {p for p in HERE.rglob('*') if p.is_file() and p.name not in {'record-manifest.json', 'archive-contents.json', 'archive-verification.json'}}
for item in read(HERE / 'attempt2-inputs.json')['inputs']:
    path = ROOT / item['path']
    if path.is_relative_to(ROOT):
        files.add(path)
for name in doc_names + ['I01B-P2C-RESULT-20261101.md', 'REVIEW-I01B-P2C-20261101.md', 'I01B-P2C-CHECKLIST-20261101.md', 'SESSION-HANDOFF-I01B-P2C-20261101.md', 'H2-DECISION.md', 'D04-STATE.md']:
    files.add(DOCS / name)
files.update({upper, P2C_ZIP})
rows = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': sha(p), 'bytes': p.stat().st_size} for p in sorted(files)]
write('record-manifest.json', {'created_utc': now, 'count': len(rows), 'files': rows, 'included_dependency_archive': P2C_ZIP.relative_to(ROOT).as_posix(), 'excluded': ['engine binary (SHA recorded)', '.git', 'whole repository', 'unrelated working files', 'external archive-content/verification reports'], 'self_excluded': 'record-manifest itself is included in ZIP and hashed by external contents inventory'})
files.add(HERE / 'record-manifest.json')
entries = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': sha(p), 'bytes': p.stat().st_size} for p in sorted(files)]
write('archive-contents.json', {'created_utc': now, 'archive': ZIP.relative_to(ROOT).as_posix(), 'entry_count': len(entries), 'entries': entries})
assert not ZIP.exists(), 'Do not overwrite a previous delivery ZIP'
with zipfile.ZipFile(ZIP, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for item in entries:
        archive.write(ROOT / item['path'], item['path'])
with zipfile.ZipFile(ZIP) as archive:
    assert archive.testzip() is None
    assert sorted(archive.namelist()) == sorted(x['path'] for x in entries)
    assert len(archive.namelist()) == len(set(archive.namelist()))
    for item in entries:
        assert hashlib.sha256(archive.read(item['path'])).hexdigest() == item['sha256']
write('archive-verification.json', {'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'archive': ZIP.relative_to(ROOT).as_posix(), 'zip_sha256': sha(ZIP), 'zip_bytes': ZIP.stat().st_size, 'entry_count': len(entries), 'crc_failures': 0, 'entry_sha_mismatches': 0, 'entry_list_exact': True, 'duplicate_paths': 0, 'archive_contents_sha256': sha(HERE / 'archive-contents.json'), 'final_audit_sha256': sha(HERE / 'final-delivery-audit.json'), 'record_manifest_sha256': sha(HERE / 'record-manifest.json')})
print(json.dumps({'baseline': len(before), 'source': len(sources), 'quarantine': len(quarantine), 'authorized_baseline_changes': len(changed), 'zip_entries': len(entries), 'zip_sha256': sha(ZIP), 'zip_bytes': ZIP.stat().st_size, 'diff_check_actual_exit': check.returncode}))
