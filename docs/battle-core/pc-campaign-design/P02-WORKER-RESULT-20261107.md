# P02 제한 CLI worker 결과

2026-11-07 KST. 제한 CLI → AutoResolver worker 구현과 독립 5-b 한정 수용을 기록했다. 전달물의 독립 마감 판정은 [마감 기록 위치](../../../tmp/p02-next-20261107/)를 따른다. 전체 P02/I01/I01b/A04~A06는 **NOT_READY**, 외부 save schema는 **UNCLASSIFIED**다. 제품 WorldMap operation 입력·BattleOutcome 결산·진행 표시, UI host, replay, 전체 K01~08은 미완료다.

## 실행 경로

```powershell
& C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/autoresolve.gd -- --operation-worker tests/fixtures/p02/worker-poc.json --out <새-출력-경로>
```

전원 delegate, policy none, 최대 18,000틱의 runtime-ready 입력을 받는다. CLI는 한 번 읽은 바이트로 JSON을 해석하고 입력 SHA를 계산한다. 메인에서 plain data와 사본 경계를 검사하고, worker 안에서 private owner를 만들어 summary/advance/drain/close를 수행한다. 메인은 join 후 결과 사본을 공개한다. 호출자는 poll 또는 cancel로 join을 끝낸다. 미게시 작업을 취소하면 결과를 폐기한다. 기존 출력 경로와 parent는 사전 검사하고 WRITE 직전에 다시 검사한다. [계획](../../../tmp/p02-next-20261107/PLAN.md) · [소유 hunk 역변환](../../../tmp/p02-next-20261107/owned-diff-proof.json)

## 정본 실행

| 입력 | tick | clock_ms | 종료 | 사건 |
|---|---:|---:|---|---|
| POC | 16 | 1,600 | annihilation | battle_end 1 |
| services | 1,221 | 122,050 | flagship_lost | contact 1, salvo 9, ship_lost 5, battle_end 1 |
| 원거리 1틱 | 1 | 100 | timeout, over false | spawn 2, end_tick/end_ms -1 |

Attempt 3/K6의 실제 53개 프로세스는 exit 0 19개, 의도한 거부 exit 1 34개였다. worker·기존 CLI 거부는 각각 17개다. worker API 고정 검사 59개, 관측 running frame 58개, 외부 비교 9개가 통과했다. 412개 동결 입력의 실행 전후 SHA가 일치했다. 직접 BattleSim 오라클은 요약과 사건의 순서·자료형을 대조했다. worker CLI의 세 성공 출력은 executor 메타 외에 동기 출력과 일치했다. 서비스 보급 완료 사건은 관측 0건으로 E2E 미검증이다. [실행 결과](../../../tmp/p02-next-20261107/attempt3/results.json) · [fixture 출처](../../../tmp/p02-next-20261107/fixture-provenance.json)

기존 POC/services 동기 출력과 legacy 통계 출력은 전후 각각 바이트가 일치했다. 기존 P02 8 사례·13,417 검사, private 70 사례·11,553 검사 및 core 회귀는 exit 0이었다. WorldLink 전후의 전체 결산 JSON과 stderr는 각각 바이트가 일치했다. 계측 전후의 ObjectDB 154개·리소스 20개, 순정 WorldLink의 150개·18개는 기존 종료 진단으로 세 실행 모두 exit 0, WORLD_LINK_PASS와 WARNING/ERROR 각 1건을 기록했다. 나머지 50개 프로세스에서 SCRIPT ERROR/ERROR/WARNING은 0건이었다. 기존 `--no-chain`, `--no-m9`, `--wind`는 기존 기대 `conflicting_option`과 달리 실제 `unknown_option`이며 exit 1로 닫힌다. [5-a 기록](../../../tmp/p02-next-20261107/IMPLEMENTATION-5A-NOTES.md)

시도 1의 테스트 파서 오류, 시도 2의 부정 fixture 분류 불일치·90초 WorldLink timeout·사후 freeze 불일치는 원 로그와 함께 남겼다. Thread.start OS 실패, 엔진 예외, 디스크 장애, 동시 writer는 미주입이다. 제품 화면, Android, 성능 및 진행값 공개는 별도 검증 대상이다. [구현 독립 5-b](../../../tmp/p02-next-20261107/REVIEW-5B-INDEPENDENT.md)

## 보존

7078개 기준선 중 P02 코드 2개 및 이 문서 갱신에서 소유한 상위 문서 2개만 P02가 변경했다. 별도 P03의 증거 스크립트 3개 동시변경은 관측 차이로 분리했다. 기준선 누락은 0이다. branch·HEAD·index 및 canonical cache 원문을 대조했다. 전체 `git diff --check`는 기존 CHECKLIST-OPEN 33행 진단으로 실제 exit 2이며 소유 diff 검사는 exit 0이다. [마감 보존 감사](../../../tmp/p02-next-20261107/closeout/preservation.json)
