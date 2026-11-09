import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

root = Path.cwd()
plan = Path(__file__).resolve().parent
patch = plan / 'accepted-p02.patch'
private = 'core/battle/operation_private_state.gd'
base = 'fb660cea69207fd332e26128643007694910a253'
tree = 'b54d9b37f3775c57860d3dfca9f4df572cba4cf7'
branch = 'codex/feature-i01b-not_remove'
patch_sha = '0f1adc97a1b4a014e285522d75a22ef45a90100bce4fd810626d3f4c03d29ae3'
private_sha = '46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3'
manifest = json.loads((plan / 'manifest.json').read_text(encoding='utf8'))
targets = {item['path']: item for item in manifest['paths']}
env = dict(os.environ, GIT_OPTIONAL_LOCKS='0')
assert not any(name in env for name in ('GIT_INDEX_FILE', 'GIT_DIR', 'GIT_WORK_TREE', 'GIT_ALTERNATE_OBJECT_DIRECTORIES'))
audit = plan / 'commit-transaction.json'
steps = []
state = {'steps': steps}

def save():
    audit.write_text(json.dumps(state, ensure_ascii=False, indent=2) + '\n', encoding='utf8')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

def git(*args):
    result = subprocess.run(['git', *args], cwd=root, env=env, capture_output=True)
    stdout = result.stdout.decode('utf8', errors='replace').strip()
    stderr = result.stderr.decode('utf8', errors='replace').strip()
    steps.append({'args': args, 'exit': result.returncode, 'stdout': stdout, 'stderr': stderr})
    save()
    if result.returncode:
        raise RuntimeError(f'git {args[0]} exit {result.returncode}: {stderr}')
    return stdout

def target_hashes():
    return {name: sha(root / name) for name in targets}

def verify_sources(hashes):
    assert hashes[private] == private_sha, 'P03 private state changed'
    for name, entry in targets.items():
        if name == private:
            assert sha(root / entry['source']) == entry['sha256_raw']
        elif name == 'docs/battle-core/pc-campaign-design/P02-EVIDENCE-LOCATIONS.md':
            assert hashes[name] is None, f'Existing path appeared: {name}'
            assert sha(root / entry['source']) == entry['sha256_raw']
        else:
            assert hashes[name] == entry['sha256_raw'], f'Live target changed: {name}'

def unrelated_status():
    result = subprocess.run(
        ['git', 'status', '--porcelain=v1', '-z', '--untracked-files=all', '--no-renames'],
        cwd=root, env=env, check=True, capture_output=True)
    return sorted(row for row in result.stdout.decode('utf8').split('\0')
                  if row and row[3:] not in targets and not row[3:].startswith(
                      'tmp/p02-space-cleanup-20261108/commit-plan/'))

try:
    assert sha(patch) == patch_sha == manifest['patch_sha256']
    assert len(targets) == 48
    assert git('rev-parse', 'HEAD') == base
    assert git('branch', '--show-current') == branch
    assert not git('diff', '--cached', '--name-only')
    initial_index = sha(root / '.git/index')
    first = target_hashes()
    verify_sources(first)
    before_status = unrelated_status()
    state.update(source_before=first, initial_index=initial_index,
                 unrelated_status_before=before_status, free_before=shutil.disk_usage(root).free)
    save()
    assert git('rev-parse', 'HEAD') == base
    assert git('branch', '--show-current') == branch
    assert not git('diff', '--cached', '--name-only')
    assert sha(root / '.git/index') == initial_index
    second = target_hashes()
    verify_sources(second)
    assert second == first and sha(patch) == patch_sha
    git('apply', '--cached', '--whitespace=error', str(patch))
    assert git('write-tree') == tree
    git('diff', '--cached', '--check', base)
    assert set(git('diff', '--cached', '--name-only', base).splitlines()) == set(targets)
    assert git('diff', '--numstat', '--', private).split('\t')[:2] == ['9', '0']
    assert target_hashes() == first
    assert git('rev-parse', 'HEAD') == base
    assert git('branch', '--show-current') == branch
    assert git('write-tree') == tree
    git('commit', '-m', 'feat(battle): integrate accepted P02 operation paths')
    head = git('rev-parse', 'HEAD')
    assert git('rev-parse', 'HEAD^') == base
    assert git('rev-parse', 'HEAD^{tree}') == tree
    assert git('branch', '--show-current') == branch
    assert not git('diff', '--cached', '--name-only')
    assert git('diff', '--numstat', '--', private).split('\t')[:2] == ['9', '0']
    after = target_hashes()
    after_status = unrelated_status()
    state.update(head=head, source_after=after, unrelated_status_after=after_status,
                 free_after=shutil.disk_usage(root).free)
    assert after == first, 'Concurrent target source changed after commit'
    assert after_status == before_status, 'Unrelated status changed during commit'
    state['result'] = 'complete'
    save()
    print(f'{head} {tree} free_bytes={state["free_after"]}')
except BaseException as exc:
    state['result'] = f'stopped: {exc}'
    save()
    raise
