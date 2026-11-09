from pathlib import Path
import hashlib,json

root=Path.cwd()
out=root/"tmp/p02-fifth-20261108/closeout"
out.mkdir(exist_ok=True)
assert not (out/"docs-hunks.json").exists()
design="docs/battle-core/pc-campaign-design/"
result="P02-LEGACY-OUTCOME-RESULT-20261108.md"
handoff="SESSION-HANDOFF-P02-LEGACY-OUTCOME-20261108.md"
checklist="P02-LEGACY-OUTCOME-CHECKLIST-20261108.md"
archive="../../../tmp/p02-fifth-20261108/closeout/P02-LEGACY-OUTCOME-DELIVERY-20261108.zip"
progress="## 한정 수용 완료 — legacy WorldMap 결산 경계\n\n"
progress+=f"- [x] 실제 legacy 자동 해결 worker의 결산 사본과 메인 join 후 게시 경계를 분리했다. 제품 자동·직접 공통 18행·106단언은 전후 일치했고 사후 경계 7행·33단언은 통과했다. clean-user WorldLink 기존 단일 실패와 returning-user 통과를 따로 기록한다. 독립 5-b 한정 수용이며 제품 operation은 미완료다. [결과]({result}) · [전용 체크리스트]({checklist}) · [최신 인계]({handoff}) · [전달 ZIP]({archive})\n\n"
upper=f"  - [ ] **P02 legacy WorldMap 결산 경계(2026-11-08)**. 실제 legacy worker 결산 사본과 메인 join 후 게시를 분리하고 독립 5-b 한정 수용을 받았다. 제품 WorldMap operation·FleetBattle3D host·제품 replay는 미완료다. [결과](pc-campaign-design/{result}) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [인계](pc-campaign-design/{handoff}).\n"
old=" 구현 한정 수용. [진행표](P02-PROGRESS-CHECKLIST.md). I01/K01~08"
new=f" 구현 한정 수용. [legacy WorldMap 결산 경계]({result})도 한정 수용. [진행표](P02-PROGRESS-CHECKLIST.md). I01/K01~08"
entries=[
    (design+"P02-PROGRESS-CHECKLIST.md","98c88509a2513d700320707c411d8a2c9105ed61f35ed19c903a49ef2efb4ba7","## 남은 인수\n",progress+"## 남은 인수\n"),
    (design+"SESSION-REQUIREMENTS-CHECKLIST-20261031.md","fd37e0bb21cfe779ab16d7ee0d94550319ee52ee34c044c4bbf615ad96be89d6",old,new),
    ("docs/battle-core/CHECKLIST-OPEN.md","600665414657817a31225e889ebf75b8256ef3826638ab995f117313f7047c0e",None,upper),
]
def sha(b):return hashlib.sha256(b).hexdigest()
pending=[]
for name, expected, before_hunk, after_hunk in entries:
    path=root/name
    data=path.read_bytes()
    assert sha(data)==expected, (name, sha(data))
    anchor=(before_hunk or "  - [ ] **P02 private owner").split("\n")[0].encode()
    line="\r\n" if data[data.index(anchor):data.index(b"\n",data.index(anchor))].endswith(b"\r") else "\n"
    if before_hunk is None:
        prefix="  - [ ] **P02 private owner"
        assert data.count(prefix.encode())==1
        begin=data.index(prefix.encode())
        end=data.index(b"\n",begin)+1
        before_hunk=data[begin:end].decode().replace("\r\n","\n")
        after_hunk=before_hunk+after_hunk
    a=before_hunk.replace("\n",line).encode()
    b=after_hunk.replace("\n",line).encode()
    assert data.count(a)==1,name
    changed=data.replace(a,b,1)
    assert changed.count(b)==1 and changed.replace(b,a,1)==data
    pending.append((path,data,changed,a,b))
record={}
for path,data,changed,a,b in pending:
    assert path.read_bytes()==data
    name=path.relative_to(root).as_posix()
    key=path.name
    (out/(key+".before.txt")).write_bytes(data)
    (out/(key+".old-hunk.txt")).write_bytes(a)
    (out/(key+".new-hunk.txt")).write_bytes(b)
    path.write_bytes(changed)
    assert path.read_bytes().replace(b,a,1)==data
    record[name]={"before":sha(data),"after":sha(changed),"reverse_verified":True}
(out/"docs-hunks.json").write_text(json.dumps(record,indent=2)+"\n",encoding="utf8")
print(record)
