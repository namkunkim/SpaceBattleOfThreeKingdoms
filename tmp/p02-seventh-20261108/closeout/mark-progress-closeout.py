from pathlib import Path
from zipfile import ZipFile
import hashlib,json,os,subprocess
D=Path(__file__).resolve().parent
R=Path.cwd()
P=R/'docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md'
Z=D/'P02-PREP-ERROR-DELIVERY-20261108.zip'
review=D/'REVIEW-CLOSEOUT-INDEPENDENT.md'
def h(b):return hashlib.sha256(b).hexdigest()
def g(*a):return subprocess.check_output(['git',*a],env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
def meta():return [g('rev-parse','HEAD').decode().strip(),h((R/'.git/index').read_bytes()),h(g('ls-files','--stage','-z'))]
m=meta()
zsha=h(Z.read_bytes()); assert zsha=='df72060b8db835b40e3f1e52124bd49f3807af37b0283558a2c21a47a26d35a7'
assert '판정: **한정 수용**' in review.read_text(encoding='utf8')
before=P.read_bytes()
with ZipFile(Z) as z:assert z.read(P.relative_to(R).as_posix())==before
a='- [ ] 새 전달 ZIP 독립 마감 대기. [전달 ZIP](../../../tmp/p02-seventh-20261108/closeout/P02-PREP-ERROR-DELIVERY-20261108.zip)'.encode()
b='- [x] 새 전달 ZIP이 독립 마감에서 한정 수용됐다. ZIP의 마감 대기 표기는 생성 시점 상태다. [전달 ZIP](../../../tmp/p02-seventh-20261108/closeout/P02-PREP-ERROR-DELIVERY-20261108.zip) · [독립 마감](../../../tmp/p02-seventh-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md)'.encode()
assert before.count(a)==1
after=before.replace(a,b,1)
assert after.replace(b,a,1)==before and P.read_bytes()==before
P.write_bytes(after)
assert meta()==m and h(Z.read_bytes())==zsha
e={'path':P.relative_to(R).as_posix(),'before_sha256':h(before),'after_sha256':h(after),'old_hunk_sha256':h(a),'new_hunk_sha256':h(b),'exact_reverse':True,'accepted_review_sha256':h(review.read_bytes()),'zip_sha256':zsha,'git_unchanged':True}
(D/'progress-after-closeout-old.txt').write_bytes(a)
(D/'progress-after-closeout-new.txt').write_bytes(b)
with (D/'progress-after-closeout.json').open('x',encoding='utf8') as f:json.dump(e,f,indent=2,ensure_ascii=False)
print(e)
