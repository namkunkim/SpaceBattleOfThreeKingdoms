"""P02 append-only local delivery audit. No Git mutation or engine execution."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
ZIP = ROOT / 'tmp/p02-first-headless-delivery-20261107.zip'
DOC = ROOT / 'docs/battle-core/pc-campaign-design'
OWNED = [ROOT / 'core/battle/operation_runtime_adapter.gd',
         ROOT / 'core/battle/operation_private_state.gd',
         ROOT / 'tests/autoresolve.gd', ROOT / 'tests/p02_headless_adapter.gd']
NEW_DOCS = [DOC / 'P02-FIRST-HEADLESS-RESULT-20261107.md',
            DOC / 'P02-FIRST-HEADLESS-CHECKLIST-20261107.md',
            DOC / 'SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md']
UPPER = [ROOT / 'docs/battle-core/CHECKLIST-OPEN.md',
         DOC / 'SESSION-REQUIREMENTS-CHECKLIST-20261031.md']


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(name, value):
    path = OUT / name
    assert not path.exists(), f'Preserve existing evidence: {path}'
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')


def delta(rows):
    changed, missing = [], []
    for row in rows:
        path = ROOT / row['path']
        if not path.is_file():
            missing.append(row['path'])
        elif digest(path) != row['sha256']:
            changed.append(dict(path=row['path'], before=row['sha256'], current=digest(path)))
    return changed, missing


assert not ZIP.exists(), 'Do not overwrite prior archives'
baseline = read(OUT / 'baseline-files.json')
changed, missing = delta(baseline)
allowed = {'core/battle/operation_private_state.gd',
           'docs/battle-core/CHECKLIST-OPEN.md',
           'docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md'}
assert not missing and {row['path'] for row in changed} == allowed
source = read(ROOT / 'tmp/i01b-p2c-20261101/source-before.json')
source_changed, source_missing = delta(source)
assert not source_changed and not source_missing
quarantine = read(ROOT / 'tmp/i01b-p2c-20261101/import-side-effects-manifest.json')
for row in quarantine:
    assert not Path(row['original']).exists()
    assert digest(Path(row['preserved'])) == row['sha256']
pre_manifest = read(OUT / 'record-manifest-pre-review.json')
pre_changed, pre_missing = delta(pre_manifest['files'])
assert not pre_changed and not pre_missing
inputs = read(OUT / 'attempt3-suite-inputs.json')['inputs']
input_changed, input_missing = delta(inputs)
assert not input_changed and not input_missing
accepted = {
    'core/battle/operation_runtime_adapter.gd': '0c0cad3e6e4e15887dcd75f9d5b57dbbe2690bfdcafd1caac163909b5421173a',
    'core/battle/operation_private_state.gd': 'dd47ceebaad2c5139bd8012deb841815cf0707c2231de202a00756913c0fa427',
    'tests/autoresolve.gd': 'a6c3ee903e2365569a31aa0194acb426d87c5856a74a9c7dcaaedeaeea18b5b8',
    'tests/p02_headless_adapter.gd': 'e44e964ed76f4d7d2edab8ebffa238672c70717670b6d82738120c72dfea9583',
}
assert all(digest(ROOT / path) == value for path, value in accepted.items())
proof = read(OUT / 'documents-owned-proof.json')
for row in proof:
    assert digest(ROOT / row['path']) == row['after_sha256']
    assert row['before_sha256'] == row['inverse_sha256']
cache = ROOT / '.godot/global_script_class_cache.cfg'
assert digest(cache) == '0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1'
prior_archives = {
    'tmp/i01b-p2c-delivery-20261101.zip': '99a4a1adca1bdc3bf7e56baa9112c1625ab6c6371bfaafa0482b3471903a2971',
    'tmp/i01b-active-replace-delivery-20261104.zip': '87a090a8d891391473fd9dfa9627dcd4430af234359e06d0b78e9e7b5f005eae',
}
assert all(digest(ROOT / path) == value for path, value in prior_archives.items())
html_path = 'docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.html'
html_sha = next(row['sha256'] for row in baseline if row['path'] == html_path)
assert digest(ROOT / html_path) == html_sha
git = lambda *args: subprocess.check_output(['git', *args], cwd=ROOT).decode().strip()
assert git('branch', '--show-current') == 'codex/feature-i01b-not_remove'
assert git('rev-parse', 'HEAD') == 'fb660cea69207fd332e26128643007694910a253'
assert git('diff', '--cached', '--name-only') == ''
whitespace = []
for path in OWNED + NEW_DOCS:
    bad = [i + 1 for i, line in enumerate(path.read_bytes().splitlines()) if line.rstrip() != line]
    assert not bad
    whitespace.append(dict(path=path.relative_to(ROOT).as_posix(), trailing_whitespace=bad, final_newline=path.read_bytes().endswith(b'\n')))
full = subprocess.run(['git', 'diff', '--check'], cwd=ROOT, capture_output=True)
(OUT / 'closeout-full-diff-check.log').write_bytes(full.stdout + full.stderr)
owned_check = subprocess.run(['git', 'diff', '--check', '--', 'tests/autoresolve.gd'], cwd=ROOT, capture_output=True)
(OUT / 'closeout-owned-diff-check.log').write_bytes(owned_check.stdout + owned_check.stderr)
assert full.returncode == 2 and owned_check.returncode == 0
assert b'CHECKLIST-OPEN.md:33: trailing whitespace' in full.stdout

# Local links may point to the archive metadata created below, or to the future
# independent closeout. No fabricated closeout file is created by this agent.
pending = {OUT / 'final-delivery-audit.json', OUT / 'record-manifest.json', ZIP,
           OUT / 'archive-verification.json', OUT / 'REVIEW-CLOSEOUT-20261107.md'}
link_failures = []
for path in NEW_DOCS:
    for target in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
        if '://' in target:
            continue
        destination = (path.parent / target.split('#')[0]).resolve()
        if not destination.exists() and destination not in pending:
            link_failures.append(dict(document=str(path), target=target))
assert not link_failures
write('final-delivery-audit.json', dict(
    client_date='2026-11-07 Asia/Seoul', stage='P02 first headless opt-in closeout payload',
    baseline_count=len(baseline), changed=changed, missing=missing,
    clean_tracked_autoresolve='separate original/inverse byte SHA in preservation-pre-review.json',
    source_count=len(source), source_changed=source_changed, source_missing=source_missing,
    quarantine_count=len(quarantine), quarantine_sha_matches=len(quarantine), original_paths_absent=len(quarantine),
    pre_review_manifest_count=pre_manifest['count'], pre_review_mismatches=[],
    attempt3_inputs_count=len(inputs), attempt3_input_mismatches=[], code_changes_after_5b=False,
    final_code=accepted, documents=proof, owned_whitespace=whitespace,
    cache_sha256=digest(cache), html_sha256=html_sha, prior_archive_sha256=prior_archives,
    full_diff_check_actual_exit=full.returncode, owned_tracked_diff_check_actual_exit=owned_check.returncode,
    full_diff_check_diagnosis='unchanged prior P2c upper CHECKLIST row33; never whole gate PASS',
    local_link_failures=link_failures, pending_independent_closeout='REVIEW-CLOSEOUT-20261107.md is external later judgement',
    attempts=3, limit=6, previous_p2c_attempts=5, previous_active_attempts=2,
    processes=dict(api=1, cli_negative=14, cli_success=2, legacy=2, regressions=2, total=21),
    no_engine_reexecution_during_closeout=True, editor_import=False,
    branch=git('branch', '--show-current'), head=git('rev-parse', 'HEAD'), index=[],
    known_deviations=['--no-chain/--no-m9/--wind unknown_option classification', 'no new CLI supply-completion E2E', 'no disk fault injection/concurrent-writer guarantee'],
    scope='restricted first headless opt-in accepted; entire P02/I01/I01b/A04-A06 NOT_READY; external save schema UNCLASSIFIED',
    archive=ZIP.relative_to(ROOT).as_posix(), archive_integrity='archive-verification.json external to avoid recursive digest',
))

paths = OWNED + NEW_DOCS + UPPER + list((ROOT / 'tests/fixtures/p02').glob('*.json'))
paths += [path for path in OUT.rglob('*') if path.is_file() and path.name not in
          {'record-manifest.json', 'archive-contents.json', 'archive-verification.json', 'REVIEW-CLOSEOUT-20261107.md'}]
# Exact payload, never an engine binary, .git, whole repository, or old ZIP.
paths = sorted(set(paths))
entries = [dict(path=path.relative_to(ROOT).as_posix(), bytes=path.stat().st_size, sha256=digest(path)) for path in paths]
write('record-manifest.json', dict(count=len(entries), files=entries,
      self_reference_policy='manifest itself listed in external archive-contents; independent closeout later and external'))
paths.append(OUT / 'record-manifest.json')
archive_entries = [dict(path=path.relative_to(ROOT).as_posix(), bytes=path.stat().st_size, sha256=digest(path)) for path in paths]
with zipfile.ZipFile(ZIP, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for path in paths:
        archive.write(path, path.relative_to(ROOT).as_posix())
write('archive-contents.json', archive_entries)
with zipfile.ZipFile(ZIP) as archive:
    assert archive.testzip() is None
    assert sorted(archive.namelist()) == sorted(row['path'] for row in archive_entries)
    for row in archive_entries:
        data = archive.read(row['path'])
        assert len(data) == row['bytes'] and hashlib.sha256(data).hexdigest() == row['sha256']
write('archive-verification.json', dict(
    client_date='2026-11-07 Asia/Seoul', archive=ZIP.relative_to(ROOT).as_posix(),
    zip_bytes=ZIP.stat().st_size, zip_sha256=digest(ZIP), entry_count=len(archive_entries),
    crc_failures=0, entry_sha_mismatches=0, entry_size_mismatches=0, entry_list_exact=True,
    archive_contents_sha256=digest(OUT / 'archive-contents.json'),
    final_audit_sha256=digest(OUT / 'final-delivery-audit.json'),
    record_manifest_sha256=digest(OUT / 'record-manifest.json'),
    independent_closeout='later external record; not retroactively included in this ZIP',
))
print(json.dumps(dict(baseline=len(baseline), source=len(source), quarantine=len(quarantine),
      manifest_count=len(entries), archive_entries=len(archive_entries), zip_bytes=ZIP.stat().st_size, zip_sha256=digest(ZIP))))
