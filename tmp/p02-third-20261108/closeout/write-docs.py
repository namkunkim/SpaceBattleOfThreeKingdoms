from pathlib import Path
import hashlib,json,os
root=Path.cwd()
e=Path("tmp/p02-third-20261108")
out=e/"closeout"
docs=Path("docs/battle-core")
d=docs/"pc-campaign-design"
progress=d/"P02-PROGRESS-CHECKLIST.md"
requirements=d/"SESSION-REQUIREMENTS-CHECKLIST-20261031.md"
top=docs/"CHECKLIST-OPEN.md"
result=d/"P02-REPLAY-RESULT-20261108.md"
checklist=d/"P02-REPLAY-CHECKLIST-20261108.md"
handoff=d/"SESSION-HANDOFF-P02-REPLAY-20261108.md"
evidence="../../../tmp/p02-third-20261108/"
def digest(data): return hashlib.sha256(data).hexdigest()
def write(path,data):
 assert not path.exists(),path
 path.write_text(data,encoding="utf8",newline="\n")
before={}
for path in (progress,requirements,top):
 data=path.read_bytes()
 (out/(path.name+".before")).write_bytes(data)
 before[str(path.as_posix())]=digest(data)
post=json.loads((e/"post-baseline-files.json").read_text(encoding="utf8"))
assert all(post[p]["sha256"]==h for p,h in before.items())
write(result,f"""# P02 제한 fresh replay CLI 결과

2026-11-08 KST. 기존 autoresolve CLI의 `--operation-replay`가 독립 5-b에서 한정 수용됐다. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 문서·전달물 독립 마감은 별도 판정이다. [독립 구현 판정]({evidence}REVIEW-5B-INDEPENDENT.md)

```powershell
& C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/autoresolve.gd -- --operation-replay tests/fixtures/p02/replay-commands.json --out <새-절대경로>
```

최대 16 MiB의 fresh 입력 한 파일을 읽고 그 바이트의 SHA-256을 기록한다. 입력을 기존 factory에 그대로 한 번 전달한다. 명시 빈 controls 배열은 허용하며 필드 누락은 `missing_field / input.initial_controls`로 거부한다. 최대 18,000틱·18,000행에서 `move`, `stop`, `attack`을 검증하고 동틱 입력 순서대로 queue→advance→drain한다. 성공 및 일반 실패 모두 owner를 닫는다. 전술 거부는 native 사건으로 보존하며 자연종료 후 미소비 행은 출력 없이 거부한다. 검증 범위는 단일 프로세스의 일반 성공·오류 경로다. [계획]({evidence}PLAN.md) · [controls 판정]({evidence}REVIEW-PLAN-CONTROLS-CLARIFICATION.md)

## 관측 및 게이트

- 동틱 순서 교환으로 사건 순서·fingerprint가 변했고 마지막 명령을 제거하자 마지막 처리 틱의 rejected 사건과 소비 수가 변했다. 비가시 표적은 `no_contact`를 반환했다. 기본 controls의 자연종료 전 3틱에서 기존 BattleSim.replay fingerprint와 대조했다. 명시 direct/delegate는 native 상태에서 다르게 관측됐고 이 fixture의 공개 CLI DTO는 같았다. [오라클과 반례]({evidence}IMPLEMENTATION-5A-NOTES.md)
- services 자연종료는 tick 1,221·clock 122,050 ms에서 순서 있는 사건 19개를 반환했으며 동일 입력 sync CLI의 요약·전체 사건과 일치했다. 원거리 1틱은 clock 100 ms, over false와 종료 sentinel을 유지했다. 공급 완료 사건은 미관측이다. [2차 결과]({evidence}attempt2/results.json)
- 1/K6은 실제 74개 프로세스였다. 기본 controls 비교 시점이 잘못된 API 검사와 BattleFlow 종료 진단 분류에서 실패했다. 2/K6은 실제 75개 중 74개와 비교 36개가 통과했다. 3/K6은 2차의 유일한 실패인 BattleFlow 한 프로세스를 다시 실행해 통과했다. 최종 75개 사례는 exit 0 22개, 의도한 exit 1 53개, timeout 0이다. 새 replay CLI 성공 10회 및 네이티브 API 14사례·101개 검사를 포함한다. 1~3차 실제 실행 수는 150개다. [1차 실패]({evidence}attempt1/results.json) · [2차 74/75]({evidence}attempt2/results.json) · [3차 단일 재실행]({evidence}attempt3/results.json)
- legacy 통계와 기존 sync·worker 출력은 바이트가 일치했다. `--no-chain`, `--no-m9`, `--wind`는 기존대로 `unknown_option`으로 exit 1이다. WorldLink는 전후 exit 0이며 ObjectDB 154/리소스 20 종료 진단이 바이트 일치했다. BattleFlow는 exit 0이고 기존 10/28 PASS 이후 ObjectDB 153/리소스 18 진단과 일치했다. 두 회귀의 SCRIPT ERROR는 0이다. 새 CLI에선 SCRIPT ERROR, ERROR, WARNING이 모두 0이다. [기존 혼용 비교]({evidence}legacy-mixed/results.json) · [실행과 진단]({evidence}IMPLEMENTATION-5A-NOTES.md)

## 보존 및 인수 경계

구현 기준선 7,967개를 전수 대조했다. 기존 CLI의 추가 hunk와 신규 5경로, 별도 사용자 진행표를 구분했다. 구현 구간 P03 추가 차이는 0이다. 기존 index·cache와 전체 `git diff --check` exit 2 및 CHECKLIST-OPEN.md 33행 진단을 보존했다. 소유 CLI diff 검사는 exit 0이다. [구현 보존]({evidence}preservation.json)

제품 FleetBattle3D/UI와 WorldMap·BattleOutcome, 제품 replay 및 legacy trace, checkpoint/cursor, 외부 save, Android·성능은 별도 인수다. OS 동시 writer·디스크 장애·엔진 예외·강제종료는 미주입이다. [전용 체크리스트]({checklist.name}) · [최신 인계]({handoff.name})
""")
write(checklist,f"""# P02 제한 fresh replay CLI 체크리스트

2026-11-08 KST. 이 체크리스트는 새 제한 CLI 경로만 다룬다. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

- [x] 계획·controls 해석 독립 판정, 구현 전 기준선 7,967개 및 native oracle 동결. [계획]({evidence}PLAN.md) · [오라클]({evidence}oracle-freeze.json)
- [x] 실제 CLI opt-in에서 명시 순서·경계 틱·전술 거부·자연종료와 명령 소비, native 사건 순서·자료형 대조. [실행 결과]({result.name})
- [x] 명시 []·direct/delegate와 controls 필드 누락, 입력·출력 거부, 실패 시 출력 부재 및 기존 출력 보존. [실제 부정 케이스]({evidence}attempt2/results.json)
- [x] legacy·sync·worker 바이트 및 기존 회귀 확인. 2/K6 74/75, 3/K6 BattleFlow 1회 재실행. 진단과 실패 원문 보존. [5-a]({evidence}IMPLEMENTATION-5A-NOTES.md)
- [x] 구현 독립 5-b 한정 수용. [판정]({evidence}REVIEW-5B-INDEPENDENT.md)
- [ ] 문서·새 ZIP의 독립 마감 판정.
- [ ] 제품 UI host, WorldMap·BattleOutcome, 제품 replay 및 legacy trace, 전체 입력·외부 schema 공동 인수. [P02 진행표]({progress.name})
""")
write(handoff,f"""# P02 제한 fresh replay 이후 최신 인계

2026-11-08 KST. 기존 운용 CLI의 새 제한 fresh replay 소비자는 구현 독립 5-b에서 한정 수용됐다. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 문서와 ZIP의 독립 마감은 별도 상태다. [결과]({result.name}) · [전용 체크리스트]({checklist.name}) · [P02 진행표]({progress.name})

- 기존 CLI에 `--operation-replay`를 추가했다. 재생 모듈은 owner 한 개에서 검증된 명령을 순서대로 큐에 넣고 종료하거나 제한에 도달하면 닫는다. 새 결과 파일의 raw 입력 SHA와 동일 파일 반복 실행 SHA를 검증했다. [코드](../../../core/battle/operation_replay.gd) · [입력 예제](../../../tests/fixtures/p02/replay-commands.json)
- 2/K6의 74/75와 3/K6 BattleFlow 단일 재실행을 합쳐 75사례가 통과했다. 1·2차의 실패 판정과 원문, 기존 종료 진단, 세 legacy 옵션의 분류 편차, 기존 전체 diff-check exit 2는 그대로 기록했다. [5-a 기록]({evidence}IMPLEMENTATION-5A-NOTES.md) · [구현 5-b]({evidence}REVIEW-5B-INDEPENDENT.md)
- 다음 조각의 독립 계획에서 실제 제품 소비자와 종료·실패 경계를 확정한다. FleetBattle3D/UI, WorldMap 진행·결산, 제품 replay와 legacy trace, checkpoint/cursor, 외부 save, Android·성능의 검증 범위는 진행표를 따른다. [P02 진행표]({progress.name})
""")
edits={}
def edit(path, changes):
 data=path.read_bytes()
 nl="\r\n" if b"\r\n" in data else "\n"
 def raw(text): return text.replace("\n",nl).encode("utf8")
 for old,new in changes:
  assert data.count(raw(old))==1,(path,old)
  data=data.replace(raw(old),raw(new),1)
 path.write_bytes(data)
 reverse=data
 for old,new in reversed(changes):
  assert reverse.count(raw(new))==1
  reverse=reverse.replace(raw(new),raw(old),1)
 assert digest(reverse)==before[path.as_posix()]
 edits[path.as_posix()]={"before_sha256":digest(reverse),"after_sha256":digest(data),"hunks":len(changes),"reverse_bytes_match":True}
old="- [ ] 구현 진행 중. 사전 native 오라클을 준비하고 있으며 새 CLI의 정본 K6 실행 및 독립 구현 5-b는 대기 중이다. 동틱 순서·명령 누락, 초기 controls, 실제 clock·종료 틱·사건 순서, 자연종료 뒤 미적용 명령 거부와 출력 부재, legacy·동기·worker 회귀를 확인한 뒤 상태를 갱신한다. [사전 오라클 출력](../../../tmp/p02-third-20261108/oracle.stdout)"
edit(progress,[("## 진행 중 — 제한 fresh replay CLI","## 한정 구현 수용 — 제한 fresh replay CLI"),(old,f"- [x] 실제 CLI와 native 오라클을 대조하고 독립 구현 5-b 한정 수용을 받았다. 2/K6 74/75 및 3/K6 BattleFlow 단일 재실행으로 최종 75사례를 통과했다. [결과]({result.name}) · [독립 판정]({evidence}REVIEW-5B-INDEPENDENT.md)\n- [ ] 문서·새 ZIP의 독립 마감 판정 진행 중. [전용 체크리스트]({checklist.name}) · [최신 인계]({handoff.name})"),("공급 완료 사건 E2E는 두 완료 조각에서 미관측이다.","공급 완료 사건 E2E는 앞선 제한 CLI와 이번 replay 검사에서 미관측이다.")])
old=next(l for l in requirements.read_text(encoding="utf8").splitlines() if l.startswith("| P02 |"))
edit(requirements,[(old,old.replace("구현 한정 수용.",f"및 [제한 fresh replay CLI]({result.name}) 구현 한정 수용. [진행표]({progress.name}).").replace("UI host·replay는","UI host·제품 replay는"))])
old=next(l for l in top.read_text(encoding="utf8").splitlines() if "P02 제한 CLI worker 연결" in l)
edit(top,[(old,old+f"\n  - [ ] **P02 제한 fresh replay CLI(2026-11-08):** 기존 실행기의 명시 입력·명령 재생 경로가 독립 5-b 한정 수용됐다. 2/K6 74/75 및 3/K6 단일 재실행 통과. 전체 P02 NOT_READY이며 제품 host/UI·WorldMap·replay 인수가 남는다. [결과](pc-campaign-design/{result.name}) · [진행표](pc-campaign-design/{progress.name}) · [최신 인계](pc-campaign-design/{handoff.name}).")])
(out/"document-proof.json").write_text(json.dumps(edits,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
print(edits)
