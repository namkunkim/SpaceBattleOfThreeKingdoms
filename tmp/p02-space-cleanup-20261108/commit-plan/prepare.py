import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root = Path.cwd()
plan = Path(__file__).resolve().parent
snapshot = root / 'tmp/p02-seventh-20261108/project-after'
docs = Path('docs/battle-core/pc-campaign-design')
checklist = Path('docs/battle-core/CHECKLIST-OPEN.md')
private = Path('core/battle/operation_private_state.gd')

def git(*args, cwd=root, env=None, data=None):
    return subprocess.run(['git', *args], cwd=cwd, env=env, input=data,
                          stdout=subprocess.PIPE, check=True).stdout

head = git('rev-parse', 'HEAD').decode().strip()
index_before = hashlib.sha256((root / '.git/index').read_bytes()).hexdigest()
assert not git('diff', '--cached', '--name-only')
assert head == 'fb660cea69207fd332e26128643007694910a253'
tracked = {Path(p) for p in git('ls-tree', '-r', '--name-only', head).decode().splitlines()}
paths = [Path(p) for p in [
    'core/battle/operation_private_state.gd',
    'core/battle/operation_private_state.gd.uid',
    'core/battle/operation_replay.gd',
    'core/battle/operation_runtime_adapter.gd',
    'core/battle/operation_service_state.gd',
    'hud/ui_kit/command_deck.gd',
    'hud/ui_kit/org_screen.gd',
    'scripts/FleetBattle3D.gd',
    'scripts/world/auto_resolver.gd',
    'scripts/world/battle_outcome.gd',
    'tests/autoresolve.gd',
]]
paths.extend(p.relative_to(root) for p in (root / 'tests').glob('p02_*.gd'))
paths.extend(p.relative_to(root) for p in (root / 'tests/fixtures/p02').glob('*.json'))
paths.extend(p.relative_to(root) for glob in ('P02-*.md', 'SESSION-HANDOFF-P02-*.md')
             for p in (root / docs).glob(glob))
paths.append(checklist)
paths = sorted(set(paths))
repo = plan / 'patch-repo'
repo.mkdir(exist_ok=True)
git('init', '-q', str(repo))
env = os.environ.copy()
env['GIT_ALTERNATE_OBJECT_DIRECTORIES'] = str(root / '.git/objects')
git('read-tree', head, cwd=repo, env=env)
manifest = []
local_links = {}
for path in paths:
    source = snapshot / path if path == private else root / path
    source_bytes = source.read_bytes()
    if path == private:
        assert hashlib.sha256(source_bytes).hexdigest().startswith('c555099934')
    elif path.parent == Path('hud/ui_kit'):
        sixth = root / 'tmp/p02-sixth-20261108/closeout-v2/delivery-manifest.json'
        assert hashlib.sha256(source_bytes).hexdigest() == json.loads(
            sixth.read_text(encoding='utf-8'))['files'][path.as_posix()]['sha256']
    elif path.suffix in ('.gd', '.uid', '.json') and path.name != 'FleetBattle3D.gd':
        assert (snapshot / path).read_bytes() == source_bytes, path
    elif path.name == 'FleetBattle3D.gd':
        assert hashlib.sha256(source_bytes).hexdigest().startswith('604b79308')
    normalized = source_bytes.replace(b'\r\n', b'\n')
    if path.name == 'p02_worker_adapter.gd':
        normalized = normalized.rstrip(b'\n') + b'\n'
    if path == checklist:
        base = git('show', f'{head}:{path.as_posix()}')
        lines = [line for line in normalized.splitlines(keepends=True) if line.startswith(b'  - [ ] **P02 ')]
        assert len(lines) == 7
        marker = b'  - [ ] **I01b '
        position = base.index(marker)
        normalized = base[:position] + b''.join(lines) + base[position:]
    if path.name == 'P02-PROGRESS-CHECKLIST.md':
        title, separator, body = normalized.partition(b'\n\n')
        note = ('검증 근거의 원본 경로와 전달 ZIP은 작업 폴더에 보관한다. 새 Git 복제본에서 별도 확보해야 할 근거와 상위 체크리스트는 [근거 위치 목록](P02-EVIDENCE-LOCATIONS.md)을 참고한다.\n\n')
        normalized = title + separator + note.encode('utf-8') + body
    if path.suffix == '.md':
        for link in re.findall(r'\]\(([^)]+)\)', normalized.decode('utf-8')):
            if re.match(r'(https?:|#)', link):
                continue
            target = (root / path.parent / link.split('#')[0]).resolve()
            if not target.is_relative_to(root):
                continue
            relative = target.relative_to(root)
            if relative not in tracked and relative not in paths:
                entry = local_links.setdefault(relative.as_posix(), {
                    'exists': target.exists(), 'bytes': target.stat().st_size if target.is_file() else None,
                    'documents': []})
                entry['documents'].append(path.as_posix())
    blob = git('hash-object', '-w', '--stdin', cwd=repo, env=env, data=normalized).decode().strip()
    git('update-index', '--add', '--cacheinfo', '100644', blob, path.as_posix(), cwd=repo, env=env)
    manifest.append({'path': path.as_posix(), 'source': source.relative_to(root).as_posix(),
                     'sha256_raw': hashlib.sha256(source_bytes).hexdigest(),
                     'sha256_target': hashlib.sha256(normalized).hexdigest(),
                     'blob': blob, 'tracked_at_head': path in tracked})
evidence_path = docs / 'P02-EVIDENCE-LOCATIONS.md'
local_links.pop(evidence_path.as_posix(), None)
assert all(entry['exists'] for entry in local_links.values())
note = [
    '# P02 검증 근거 위치',
    '',
    'P02 결과·인계 문서의 기존 링크는 당시 작업 폴더의 경로를 가리킨다. 아래 원본 근거와 전달 ZIP은 검증이 이루어진 작업 폴더에 보관되어 있다. 새 Git 복제본에는 아래 파일이 없으므로 원본 작업 폴더에서 별도로 확보해야 한다.',
    '',
    '상위 세션 요구사항 체크리스트는 P02 외 요구사항과 P03 이력을 함께 관리하는 작업 폴더의 별도 문서다. P02 범위와 남은 인수는 [P02 진행 체크리스트](P02-PROGRESS-CHECKLIST.md)에 기록되어 있다.',
    '',
    '## 별도 관리 문서',
    '',
]
note.extend(f'- `{name}`' for name in sorted(local_links) if not name.startswith('tmp/'))
note += [
    '',
    '## 별도 테스트 실행 준비',
    '',
    '- `tests/p02_headless_adapter.gd`는 `tmp/p02-first-integration-20261105/`에 관측 JSON을 쓴다. 격리 복제본에 이 빈 디렉터리를 먼저 만들면 원본 관측 파일을 보존할 수 있다.',
    '- `tests/p02_replay_adapter.gd`는 로컬 `tmp/p02-third-20261108/oracle.native`와 같은 디렉터리의 `matrix/`에서 commands, reordered, removed, defaults, one-tick, natural, direct, delegate, late, order, policy, limit, rows, commands-shape JSON을 읽는다. 원본 입력을 같은 상대경로에 복제한 뒤 실행한다.',
    '- CLI의 `--operation-input`, `--operation-worker`, `--operation-replay`는 커밋에 포함된 `tests/fixtures/p02/`의 입력으로 실행할 수 있다.',
]
note += ['', '## 로컬 실행 근거와 전달 ZIP', '']
note.extend(f'- `{name}`' for name in sorted(local_links) if name.startswith('tmp/'))
evidence_bytes = ('\n'.join(note) + '\n').encode('utf-8')
(plan / evidence_path.name).write_bytes(evidence_bytes)
blob = git('hash-object', '-w', '--stdin', cwd=repo, env=env, data=evidence_bytes).decode().strip()
git('update-index', '--add', '--cacheinfo', '100644', blob, evidence_path.as_posix(), cwd=repo, env=env)
manifest.append({'path': evidence_path.as_posix(),
                 'source': (plan / evidence_path.name).relative_to(root).as_posix(),
                 'sha256_raw': hashlib.sha256(evidence_bytes).hexdigest(),
                 'sha256_target': hashlib.sha256(evidence_bytes).hexdigest(),
                 'blob': blob, 'tracked_at_head': False})
patch = git('diff', '--cached', '--binary', '--full-index', '--no-ext-diff', head, cwd=repo, env=env)
(plan / 'accepted-p02.patch').write_bytes(patch)
(plan / 'manifest.json').write_text(json.dumps({
    'base': head, 'patch_sha256': hashlib.sha256(patch).hexdigest(),
    'original_index_sha256': index_before, 'paths': manifest,
    'links_outside_commit': local_links,
}, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print(git('diff', '--cached', '--stat', head, cwd=repo, env=env).decode())
git('diff', '--cached', '--check', head, cwd=repo, env=env)
assert hashlib.sha256((root / '.git/index').read_bytes()).hexdigest() == index_before
print(f'{len(manifest)} paths, {len(local_links)} local-only link targets')
