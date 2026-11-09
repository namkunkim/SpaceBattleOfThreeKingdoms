from pathlib import Path
import difflib,hashlib,json,re
p=Path('docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md')
e=Path(__file__).parent
old=p.read_bytes()
(e/'P02-PROGRESS-CHECKLIST.before.md').write_bytes(old)
key='## 한정 수용 — legacy FleetBattle3D 후보 준비'.encode()
assert old.count(key)==1
start=old.index(key)
end=old.index(b'## ',start+len(key))
section=old[start:end]
eol=b'\r\n' if b'\r\n' in section else b'\n'
replacement="""## 한정 수용 완료 — legacy FleetBattle3D 후보 준비

- [x] 실제 FleetBattle3D에서 새 전투 후보를 준비한 뒤 성공한 후보만 게시한다. 지정 bench patch의 두 명시 오류에서 기존 전투와 실제 출격·재시작·타이틀·편성 호출부의 동기 상태가 유지됐다. 공통 8행·27단언은 전후 일치했고 사후 10행·546단언과 복구 trace 대조를 통과했다. 예상 엔진 거절 진단 10건을 관측했다. clean-user WorldLink는 기존 단일 실패(exit 1), returning-user는 통과(exit 0)로 각각 기록했다. ObjectDB/리소스 종료 진단의 원인은 확정하지 않았다. [결과](P02-HOST-PREP-RESULT-20261108.md) · [전용 체크리스트](P02-HOST-PREP-CHECKLIST-20261108.md) · [인계](SESSION-HANDOFF-P02-HOST-PREP-20261108.md)

- [x] 최종 전달 ZIP은 독립 마감에서 한정 수용됐다. ZIP 안의 마감 대기 표기는 생성 당시 상태이며, 이후 판정은 외부 심사 기록에 있다. 마감 중 관측된 미귀속 경로 차이는 확인된 실행 입력 및 소유 파일과 겹치지 않았고 변경 주체는 확인되지 않았다. [최종 전달 ZIP](../../../tmp/p02-sixth-20261108/closeout-v2/P02-HOST-PREP-DELIVERY-20261108.zip) · [독립 마감](../../../tmp/p02-sixth-20261108/closeout-v2/REVIEW-CLOSEOUT-INDEPENDENT.md)

- [ ] 사용자 HUD 오류 표시, 적벽 operation 지원, FleetBattle3D·WorldMap 제품 operation 연결과 P02 전체 인수는 남아 있다.

""".encode().replace(b'\n',eol)
new=old[:start]+replacement+old[end:]
new=new.replace('**FleetBattle3D 제품 호스트.** 공통 입력으로'.encode(),'**FleetBattle3D 제품 operation 호스트.** 공통 operation 입력으로'.encode(),1)
digest=lambda x:hashlib.sha256(x).hexdigest()
links=[]
for target in re.findall(r'\]\(([^)]+)\)',replacement.decode()):
 q=(p.parent/target).resolve()
 assert q.is_file(),q
 links.append({'target':target,'bytes':q.stat().st_size,'sha256':digest(q.read_bytes())})
assert p.read_bytes()==old
p.write_bytes(new)
assert p.read_bytes()==new
diff=''.join(difflib.unified_diff(old.decode().splitlines(keepends=True),new.decode().splitlines(keepends=True),fromfile=str(p),tofile=str(p)))
(e/'P02-PROGRESS-CHECKLIST.diff').write_bytes(diff.encode())
(e/'verification.json').write_text(json.dumps({'before_sha256':digest(old),'after_sha256':digest(new),'before_bytes':len(old),'after_bytes':len(new),'links':links},indent=2),encoding='utf-8')
print(digest(old),digest(new),len(links))
