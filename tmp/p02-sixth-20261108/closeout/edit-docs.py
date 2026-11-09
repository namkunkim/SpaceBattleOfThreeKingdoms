from pathlib import Path
import hashlib,json
root=Path.cwd()
d=Path(__file__).resolve().parent
design="docs/battle-core/pc-campaign-design/"
result="P02-HOST-PREP-RESULT-20261108.md"
progress="P02-PROGRESS-CHECKLIST.md"
handoff="SESSION-HANDOFF-P02-HOST-PREP-20261108.md"
checks="P02-HOST-PREP-CHECKLIST-20261108.md"
ziprel="../../../tmp/p02-sixth-20261108/closeout/P02-HOST-PREP-DELIVERY-20261108.zip"
anchor="## 남은 인수"
block=f"""## 한정 수용 — legacy FleetBattle3D 후보 준비

- [x] 지정 bench patch 두 오류에서 기존 전투와 deck·편성 화면의 동기 상태를 보존한다. 공통 8행·27단언이 전후 일치했고 사후 10행·546단언과 전체 복구 trace 대조가 통과했다. clean WorldLink 기존 실패, 종료 진단, HUD 오류 표시 미검증을 별도로 기록했다. 제품 operation은 미연결이다. [결과]({result}) · [전용 체크리스트]({checks}) · [인계]({handoff}) · [전달 ZIP]({ziprel})

"""
upper=f"  - [ ] **P02 legacy FleetBattle3D 후보 준비(2026-11-08)**. 지정 bench patch 두 오류와 제품 동기 호출 경계는 독립 5-b 한정 수용됐다. 제품 operation host와 전체 P02 인수는 남는다. [결과](pc-campaign-design/{result}) · [진행표](pc-campaign-design/{progress}) · [인계](pc-campaign-design/{handoff})."
entries=[
(design+progress,"6fe7e83fdbc627ddd62897202bc542bdab915a017958d94a1568b48aadc5a30f",anchor,block+anchor),
(design+"SESSION-REQUIREMENTS-CHECKLIST-20261031.md","2dd3ef6251a01ea3c4fe2a11fa400e901beb0c193839164bee532beeb070d188",f"도 한정 수용. [진행표]({progress})",f"도 한정 수용. [legacy FleetBattle3D 후보 준비]({result})는 지정 오류와 동기 호출만 한정 수용. [진행표]({progress})"),
("docs/battle-core/CHECKLIST-OPEN.md","56e74e9bb1b55de0008ce31034111ee71b840de4d3787dc8c17ecb909567a4d1",f"[인계](pc-campaign-design/SESSION-HANDOFF-P02-LEGACY-OUTCOME-20261108.md).",f"[인계](pc-campaign-design/SESSION-HANDOFF-P02-LEGACY-OUTCOME-20261108.md).\n{upper}")]
def sha(data):return hashlib.sha256(data).hexdigest()
assert not (d/"docs-hunks.json").exists()
work=[]
for name,digest,old,new in entries:
 p=root/name
 data=p.read_bytes()
 assert sha(data)==digest
 sep="\r\n" if b"\r\n" in data else "\n"
 a,b=(s.replace("\n",sep).encode() for s in (old,new))
 assert data.count(a)==1
 updated=data.replace(a,b,1)
 assert updated.count(b)==1 and updated.replace(b,a,1)==data
 work.append((p,data,updated,a,b))
proof={}
for p,data,updated,a,b in work:
 assert p.read_bytes()==data
 for suffix,content in (("before",data),("old-hunk",a),("new-hunk",b)):
  (d/(p.name+"."+suffix+".txt")).write_bytes(content)
 p.write_bytes(updated)
 assert p.read_bytes().replace(b,a,1)==data
 proof[p.relative_to(root).as_posix()]={"before":sha(data),"after":sha(updated),"reverse_verified":True}
(d/"docs-hunks.json").write_text(json.dumps(proof,indent=2)+"\n",encoding="utf8")
