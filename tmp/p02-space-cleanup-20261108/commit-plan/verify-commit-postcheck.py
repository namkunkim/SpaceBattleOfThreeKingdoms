import json
from pathlib import Path
import shutil

plan_path = Path(__file__).resolve().parent
transaction = json.loads((plan_path / 'commit-transaction.json').read_text(encoding='utf8'))
source = (plan_path / 'commit-approved.py').read_text(encoding='utf-8-sig')
exec(source.split('\ntry:\n')[0])
audit = plan / 'commit-postcheck.json'
head = git('rev-parse', 'HEAD')
assert head == '0be09755b70378286105972f35ac5b7031715664'
assert git('rev-parse', 'HEAD^') == base
assert git('rev-parse', 'HEAD^{tree}') == tree
assert git('branch', '--show-current') == branch
assert not git('diff', '--cached', '--name-only')
assert len(git('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD').splitlines()) == 48
assert git('diff', '--numstat', '--', private).split('\t')[:2] == ['9', '0']
after = target_hashes()
after_status = unrelated_status()
before_status = transaction['unrelated_status_before']
state.update(head=head, source_after=after, unrelated_status_after=after_status,
             unrelated_status_added=sorted(set(after_status) - set(before_status)),
             unrelated_status_removed=sorted(set(before_status) - set(after_status)),
             free_after=shutil.disk_usage(root).free)
save()
assert after == transaction['source_before'], 'target SHA drift'
assert after_status == before_status, 'unrelated status drift'
state['result'] = 'complete'
save()
print(f'{head} {tree} free_bytes={state["free_after"]}')
