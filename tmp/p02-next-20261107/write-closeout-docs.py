from pathlib import Path

e=Path('tmp/p02-next-20261107')
d=Path('docs/battle-core/pc-campaign-design')
r='../../../tmp/p02-next-20261107'
result='P02-WORKER-RESULT-20261107.md'
check='P02-WORKER-CHECKLIST-20261107.md'
handoff='SESSION-HANDOFF-P02-WORKER-20261107.md'
docs={
result:f'''# P02 제한 CLI worker 결과

2026-11-07 KST. 제한 CLI → AutoResolver worker 구현과 독립 5-b 한정 수용을 기록했다. 전달물의 독립 마감 판정은 [마감 기록 위치]({r}/)를 따른다. 전체 P02/I01/I01b/A04~A06는 **NOT_READY**, 외부 save schema는 **UNCLASSIFIED**다. 제품 WorldMap operation 입력·BattleOutcome 결산·진행 표시, UI host, replay, 전체 K01~08은 미완료다.

## 실행 경로

```powershell
& C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/autoresolve.gd -- --operation-worker tests/fixtures/p02/worker-poc.json --out <새-출력-경로>
```

전원 delegate, policy none, 최대 18,000틱의 runtime-ready 입력을 받는다. CLI는 한 번 읽은 바이트로 JSON을 해석하고 입력 SHA를 계산한다. 메인에서 plain data와 사본 경계를 검사하고, worker 안에서 private owner를 만들어 summary/advance/drain/close를 수행한다. 메인은 join 후 결과 사본을 공개한다. 호출자는 poll 또는 cancel로 join을 끝낸다. 미게시 작업을 취소하면 결과를 폐기한다. 기존 출력 경로와 parent는 사전 검사하고 WRITE 직전에 다시 검사한다. [계획]({r}/PLAN.md) · [소유 hunk 역변환]({r}/owned-diff-proof.json)

## 정본 실행

| 입력 | tick | clock_ms | 종료 | 사건 |
|---|---:|---:|---|---|
| POC | 16 | 1,600 | annihilation | battle_end 1 |
| services | 1,221 | 122,050 | flagship_lost | contact 1, salvo 9, ship_lost 5, battle_end 1 |
| 원거리 1틱 | 1 | 100 | timeout, over false | spawn 2, end_tick/end_ms -1 |

Attempt 3/K6의 실제 53개 프로세스는 exit 0 19개, 의도한 거부 exit 1 34개였다. worker·기존 CLI 거부는 각각 17개다. worker API 고정 검사 59개, 관측 running frame 58개, 외부 비교 9개가 통과했다. 412개 동결 입력의 실행 전후 SHA가 일치했다. 직접 BattleSim 오라클은 요약과 사건의 순서·자료형을 대조했다. worker CLI의 세 성공 출력은 executor 메타 외에 동기 출력과 일치했다. 서비스 보급 완료 사건은 관측 0건으로 E2E 미검증이다. [실행 결과]({r}/attempt3/results.json) · [fixture 출처]({r}/fixture-provenance.json)

기존 POC/services 동기 출력과 legacy 통계 출력은 전후 각각 바이트가 일치했다. 기존 P02 8 사례·13,417 검사, private 70 사례·11,553 검사 및 core 회귀는 exit 0이었다. WorldLink 전후의 전체 결산 JSON과 stderr는 각각 바이트가 일치했다. 계측 전후의 ObjectDB 154개·리소스 20개, 순정 WorldLink의 150개·18개는 기존 종료 진단으로 세 실행 모두 exit 0, WORLD_LINK_PASS와 WARNING/ERROR 각 1건을 기록했다. 나머지 50개 프로세스에서 SCRIPT ERROR/ERROR/WARNING은 0건이었다. 기존 `--no-chain`, `--no-m9`, `--wind`는 기존 기대 `conflicting_option`과 달리 실제 `unknown_option`이며 exit 1로 닫힌다. [5-a 기록]({r}/IMPLEMENTATION-5A-NOTES.md)

시도 1의 테스트 파서 오류, 시도 2의 부정 fixture 분류 불일치·90초 WorldLink timeout·사후 freeze 불일치는 원 로그와 함께 남겼다. Thread.start OS 실패, 엔진 예외, 디스크 장애, 동시 writer는 미주입이다. 제품 화면, Android, 성능 및 진행값 공개는 별도 검증 대상이다. [구현 독립 5-b]({r}/REVIEW-5B-INDEPENDENT.md)

## 보존

7078개 기준선 중 P02 코드 2개 및 이 문서 갱신에서 소유한 상위 문서 2개만 P02가 변경했다. 별도 P03의 증거 스크립트 3개 동시변경은 관측 차이로 분리했다. 기준선 누락은 0이다. branch·HEAD·index 및 canonical cache 원문을 대조했다. 전체 `git diff --check`는 기존 CHECKLIST-OPEN 33행 진단으로 실제 exit 2이며 소유 diff 검사는 exit 0이다. [마감 보존 감사]({r}/closeout/preservation.json)
''',
check:f'''# P02 제한 CLI worker 체크리스트

- [x] 계획 SHA와 비-Astra 독립 계획 수용. [계획 판정]({r}/REVIEW-PLAN-INDEPENDENT.md)
- [x] 실제 CLI의 명시 `--operation-worker`, 제한된 입력과 기존 `--operation-input` 상호배제, join 후 결과. W1/W2 자연종료와 W3 timeout 및 clock/sentinel 대조.
- [x] 직접 native 요약·사건 순서·타입과 기존 동기 CLI 출력 일치. W4/W6 원본 및 반환 사본 분리, 중복 시작, legacy guard, 미게시 취소, 실패 후 재시작 확인.
- [x] W5 거부 17개 exit 1, 오류·경로 일치, 새 출력 부재 및 기존 target 보존. 기존 부정 CLI 17개 재실행. 이전 세 옵션의 `unknown_option` 분류 편차 기록.
- [x] 기존 동기 출력·통계 바이트 및 P02/private/core/WorldLink 회귀. WorldLink 종료 진단과 전체 diff-check의 기존 33행 실패 기록.
- [x] 시도 1/2 반례 및 시도 3의 입력·실행·보존 SHA 기록. [결과]({result}) · [구현 독립 5-b]({r}/REVIEW-5B-INDEPENDENT.md)
- [ ] 전달물의 독립 마감 판정.
- [ ] 전체 P02/K01~08 및 WorldMap operation 입력·BattleOutcome·진행 표시, UI host, replay. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED.
- [ ] 서비스 보급 완료 E2E, Thread.start OS 실패 주입, 엔진 예외, 디스크 장애, 동시 writer 및 제품 화면·Android·성능 검증.
''',
handoff:f'''# P02 제한 CLI worker 세션 인계

2026-11-07 KST. 시작 자료는 [결과]({result}), [전용 체크리스트]({check}), [계획]({r}/PLAN.md), [독립 5-b]({r}/REVIEW-5B-INDEPENDENT.md)다. 전달물 마감 판정은 증거 디렉터리에서 확인한다.

- 실제 진입점은 `tests/autoresolve.gd -- --operation-worker <runtime-ready JSON> --out <새 경로>`다. `AutoResolver.start_operation/poll_operation/cancel_operation`의 소유자는 join을 마친다. 바뀐 기존 소스는 `scripts/world/auto_resolver.gd`, `tests/autoresolve.gd` 두 개이며 새 소스는 worker API 검사와 fixture 3개다.
- 정본은 worker K6 attempt 3이다. 기존 첫 headless K6와 분리한다. 시도 1/2 로그와 사전 동결본을 보존했다. [정본 결과]({r}/attempt3/results.json) · [구현 매니페스트]({r}/implementation-manifest.json) · [전달물 감사]({r}/closeout/preservation.json)
- 심사자의 세션 메타로 구현 `/root/p02_next_impl`, `01a1b5c4-0cb0-75c3-8287-d0c2646f51f7`, 실제 gpt-6.1-sol과 독립 심사 `/root/p02_next_review`, `01a1b5bf-e9fe-7383-8dc9-aec906ab2995`, 실제 gpt-6.1-terra를 확인했다. parent는 둘 다 `01a1ac09-125c-71d0-b13b-721727506c85`다.
- 제품 WorldMap operation 입력과 결산, UI host, replay, 전체 K01~08이 남았다. 전체 P02/I01/I01b/A04~A06는 NOT_READY이며 외부 save schema는 UNCLASSIFIED다. 제한 worker DTO의 summary/events를 제품 BattleOutcome으로 간주하면 안 된다.
- 작업은 원본 workspace에서 수행했다. 최초 7078 기준선에 포함된 P03 소유 파일 3개의 동시변경은 별도 기록했다. 이 작업에서 기존 ZIP/HTML은 갱신하지 않았다.
'''
}
patches=[
(Path('docs/battle-core/CHECKLIST-OPEN.md'), b'  - [ ] **P02 ', f'  - [ ] **P02 제한 CLI worker 연결(2026-11-07):** `--operation-worker`를 실제 AutoResolver 별도 스레드에 연결했고 독립 5-b 한정 수용을 받았다. Worker K6 attempt 3에서 실제 프로세스 53개 및 비교 9개 통과. 전체 P02와 제품 WorldMap operation·UI host·replay는 미완료다. [결과](pc-campaign-design/{result}) · [체크리스트](pc-campaign-design/{check}) · [인계](pc-campaign-design/{handoff}).'),
(d/'SESSION-REQUIREMENTS-CHECKLIST-20261031.md',b'| P02 |',f'| P02 | 미완료 | 실제 host/headless/replay의 공통 adapter와 신규 opt-in 경로 | [제한 headless](P02-FIRST-HEADLESS-RESULT-20261107.md) 및 [CLI→AutoResolver worker](%s) 구현 한정 수용. I01/K01~08 전체 입력·초기화/실패 공동 인수, 제품 WorldMap operation/결산/진행 표시, UI host·replay는 남는다. legacy 불변/중복 변환 금지 |'%result)
]
orig={}
for path,prefix,line in patches:
 raw=path.read_bytes()
 assert raw==(e/'before'/(path.name+'.txt')).read_bytes()
 match=[x for x in raw.splitlines(keepends=True) if x.startswith(prefix)]
 assert len(match)==1 and match[0].endswith(b'\n') and not match[0].endswith(b'\r\n')
 old=match[0]
 new=(old if prefix.startswith(b'  -') else b'')+line.encode()+b'\n'
 proposed=raw.replace(old,new)
 assert proposed.replace(new,old)==raw
 orig[path]=(raw,proposed)
for name in docs:
 assert not (d/name).exists()
for path,(raw,proposed) in orig.items():
 assert path.read_bytes()==raw
 path.write_bytes(proposed)
for name,value in docs.items():
 with (d/name).open('xb') as f:
  f.write(value.encode())
