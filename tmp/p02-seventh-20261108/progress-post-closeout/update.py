from pathlib import Path
import difflib,hashlib,json,re
p=Path('docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md')
out=Path('tmp/p02-seventh-20261108/progress-post-closeout')
out.mkdir()
before=p.read_bytes()
start=before.index(b'## 7.')
end=before.index(b'## ',start+4)
old=before[start:end]
eol=b'\r\n' if b'\r\n' in old else b'\n'
new="""## 한정 수용 완료 — 전투 준비 실패 안내와 최초 탈출

- [x] 지정 준비 오류에서 기존 전투의 비모달 안내와 정상 게시 뒤 제거를 확인했다. 최초 실패에서는 구형 출격을 차단하고 단독 실행 종료 또는 결과 없는 천하 복귀를 제공한다. 사용자가 Escape로 실제 Windows 입력 검사를 멈춘 뒤 요청에 따라 재개했다. 기존 제품 버튼 03~08과 단독 종료는 이전 동결 입력의 Windows 근거이며, 현재 동결 입력에서 천하 복귀의 실제 마우스·키보드 입력 및 네이티브 렌더를 다시 확인했다. WorldMap 자동 해결 완료·취소는 제품 버튼에 전달한 자동 viewport 입력으로 별도 검증했다. [결과](P02-PREP-ERROR-RESULT-20261108.md) · [전용 체크리스트](P02-PREP-ERROR-CHECKLIST-20261108.md) · [인계](SESSION-HANDOFF-P02-PREP-ERROR-20261108.md)
- [x] 독립 구현 5-b와 전달 ZIP의 독립 마감은 이 범위를 한정 수용했다. ZIP 내부 마감 대기는 생성 당시 표기이며, 최종 판정은 ZIP 외부 독립 마감 기록에 있다. 최초 randomize 시작 트레이스 strict 비교는 7/8이었다. 고정 RNG의 별도 init_game 후속 한 행 전체 일치는 최초 시작 비교와 별개다. K1~K6을 사용했고 clean-user WorldLink의 기존 서막 단일 실패(exit 1)와 returning-user 통과(exit 0)를 재현했다. 기존 ObjectDB·리소스 종료 진단의 원인은 확정하지 않았다. [독립 5-b](../../../tmp/p02-seventh-20261108/REVIEW-5B-INDEPENDENT.md) · [최종 전달 ZIP](../../../tmp/p02-seventh-20261108/closeout/P02-PREP-ERROR-DELIVERY-20261108.zip) · [독립 마감](../../../tmp/p02-seventh-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md)
- [ ] 적벽 operation 지원, FleetBattle3D·WorldMap 제품 operation 연결과 P02 전체 인수는 남아 있다.

""".encode().replace(b'\n',eol)
after=before[:start]+new+before[end:]
links=[m.decode() for m in re.findall(rb'\]\(([^)]+)\)',new)]
assert all((p.parent/x).is_file() for x in links)
zip_path=p.parent/next(x for x in links if x.endswith('.zip'))
sha=lambda b:hashlib.sha256(b).hexdigest()
zip_sha=sha(zip_path.read_bytes())
assert zip_sha=='df72060b8db835b40e3f1e52124bd49f3807af37b0283558a2c21a47a26d35a7'
(out/(p.name+'.before.md')).write_bytes(before)
(out/'update.py').write_bytes(Path(__file__).read_bytes())
diff=b''.join(difflib.diff_bytes(difflib.unified_diff,before.splitlines(keepends=True),after.splitlines(keepends=True),str(p).encode(),str(p).encode()))
(out/'P02-PROGRESS-CHECKLIST.diff').write_bytes(diff)
assert p.read_bytes()==before
p.write_bytes(after)
assert p.read_bytes().replace(new,old,1)==before
assert sha(zip_path.read_bytes())==zip_sha
meta=dict(path=str(p),before_sha256=sha(before),after_sha256=sha(after),diff_sha256=sha(diff),zip_sha256=zip_sha,verified_links=links,reverse_hunk_matches=True)
(out/'verification.json').write_text(json.dumps(meta,indent=2),encoding='utf8')
print(json.dumps(meta))
