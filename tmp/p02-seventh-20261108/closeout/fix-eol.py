from pathlib import Path
import hashlib,json
d=Path(__file__).resolve().parent
p=Path('docs/battle-core/CHECKLIST-OPEN.md')
old=(d/(p.name+'.old-hunk.txt')).read_bytes()
before=(d/(p.name+'.before.txt')).read_bytes()
previous=(d/(p.name+'.new-hunk.txt')).read_bytes()
current=p.read_bytes()
assert current==before.replace(old,previous,1)
assert before[before.index(old)+len(old):].startswith(b'\n')
new=previous.replace(b'\r\n',b'\n')
after=before.replace(old,new,1)
assert after.replace(new,old,1)==before
for name in ['owned-diff-check.stdout','owned-diff-check.stderr','owned-diff-check.exit','docs-hunks.json']:
 f=d/name
 (d/(name+'.initial')).write_bytes(f.read_bytes())
p.write_bytes(after)
(d/(p.name+'.new-hunk.txt')).write_bytes(new)
manifest=d/'docs-hunks.json'
m=json.loads(manifest.read_bytes())
m[p.as_posix()]['after_sha256']=hashlib.sha256(after).hexdigest()
m[p.as_posix()]['new_hunk_sha256']=hashlib.sha256(new).hexdigest()
manifest.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf8')
