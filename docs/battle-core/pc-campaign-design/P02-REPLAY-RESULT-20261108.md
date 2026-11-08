# P02 제한 fresh replay CLI 결과

2026-11-08 KST. 기존 autoresolve CLI의 `--operation-replay`가 독립 5-b에서 한정 수용됐다. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 문서·전달물 독립 마감은 별도 판정이다. [독립 구현 판정](../../../tmp/p02-third-20261108/REVIEW-5B-INDEPENDENT.md)

```powershell
& C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/autoresolve.gd -- --operation-replay tests/fixtures/p02/replay-commands.json --out <새-절대경로>
```

최대 16 MiB의 fresh 입력 한 파일을 읽고 그 바이트의 SHA-256을 기록한다. 입력을 기존 factory에 그대로 한 번 전달한다. 명시 빈 controls 배열은 허용하며 필드 누락은 `missing_field / input.initial_controls`로 거부한다. 최대 18,000틱·18,000행에서 `move`, `stop`, `attack`을 검증하고 동틱 입력 순서대로 queue→advance→drain한다. 성공 및 일반 실패 모두 owner를 닫는다. 전술 거부는 native 사건으로 보존하며 자연종료 후 미소비 행은 출력 없이 거부한다. 검증 범위는 단일 프로세스의 일반 성공·오류 경로다. [계획](../../../tmp/p02-third-20261108/PLAN.md) · [controls 판정](../../../tmp/p02-third-20261108/REVIEW-PLAN-CONTROLS-CLARIFICATION.md)

## 관측 및 게이트

- 동틱 순서 교환으로 사건 순서·fingerprint가 변했고 마지막 명령을 제거하자 마지막 처리 틱의 rejected 사건과 소비 수가 변했다. 비가시 표적은 `no_contact`를 반환했다. 기본 controls의 자연종료 전 3틱에서 기존 BattleSim.replay fingerprint와 대조했다. 명시 direct/delegate는 native 상태에서 다르게 관측됐고 이 fixture의 공개 CLI DTO는 같았다. [오라클과 반례](../../../tmp/p02-third-20261108/IMPLEMENTATION-5A-NOTES.md)
- services 자연종료는 tick 1,221·clock 122,050 ms에서 순서 있는 사건 19개를 반환했으며 동일 입력 sync CLI의 요약·전체 사건과 일치했다. 원거리 1틱은 clock 100 ms, over false와 종료 sentinel을 유지했다. 공급 완료 사건은 미관측이다. [2차 결과](../../../tmp/p02-third-20261108/attempt2/results.json)
- 1/K6은 실제 74개 프로세스였다. 기본 controls 비교 시점이 잘못된 API 검사와 BattleFlow 종료 진단 분류에서 실패했다. 2/K6은 실제 75개 중 74개와 비교 36개가 통과했다. 3/K6은 2차의 유일한 실패인 BattleFlow 한 프로세스를 다시 실행해 통과했다. 최종 75개 사례는 exit 0 22개, 의도한 exit 1 53개, timeout 0이다. 새 replay CLI 성공 10회 및 네이티브 API 14사례·101개 검사를 포함한다. 1~3차 실제 실행 수는 150개다. [1차 실패](../../../tmp/p02-third-20261108/attempt1/results.json) · [2차 74/75](../../../tmp/p02-third-20261108/attempt2/results.json) · [3차 단일 재실행](../../../tmp/p02-third-20261108/attempt3/results.json)
- legacy 통계와 기존 sync·worker 출력은 바이트가 일치했다. `--no-chain`, `--no-m9`, `--wind`는 기존대로 `unknown_option`으로 exit 1이다. WorldLink는 전후 exit 0이며 ObjectDB 154/리소스 20 종료 진단이 바이트 일치했다. BattleFlow는 exit 0이고 기존 10/28 PASS 이후 ObjectDB 153/리소스 18 진단과 일치했다. 두 회귀의 SCRIPT ERROR는 0이다. 새 CLI에선 SCRIPT ERROR, ERROR, WARNING이 모두 0이다. [기존 혼용 비교](../../../tmp/p02-third-20261108/legacy-mixed/results.json) · [실행과 진단](../../../tmp/p02-third-20261108/IMPLEMENTATION-5A-NOTES.md)

## 보존 및 인수 경계

구현 기준선 7,967개를 전수 대조했다. 기존 CLI의 추가 hunk와 신규 5경로, 별도 사용자 진행표를 구분했다. 구현 구간 P03 추가 차이는 0이다. 기존 index·cache와 전체 `git diff --check` exit 2 및 CHECKLIST-OPEN.md 33행 진단을 보존했다. 소유 CLI diff 검사는 exit 0이다. [구현 보존](../../../tmp/p02-third-20261108/preservation.json)

제품 FleetBattle3D/UI와 WorldMap·BattleOutcome, 제품 replay 및 legacy trace, checkpoint/cursor, 외부 save, Android·성능은 별도 인수다. OS 동시 writer·디스크 장애·엔진 예외·강제종료는 미주입이다. [전용 체크리스트](P02-REPLAY-CHECKLIST-20261108.md) · [최신 인계](SESSION-HANDOFF-P02-REPLAY-20261108.md)
