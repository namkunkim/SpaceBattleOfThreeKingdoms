# P02 진행 체크리스트

갱신일 2026-11-08 KST. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 상위 인수 항목은 [세션 요구사항 체크리스트의 P02 행](SESSION-REQUIREMENTS-CHECKLIST-20261031.md)을 따른다.

## 한정 수용 완료

- [x] **첫 headless 연결.** 기존 실행기의 `--operation-input`이 제한된 runtime-ready 입력을 공통 어댑터로 한 번 검증해 private owner를 생성한다. 공개 투영을 쓰는 정책, 틱 진행과 순서 있는 사건 회수, 실패 시 출력 경계, legacy 출력 비교를 검증했다. 정본 3/K6. [결과](P02-FIRST-HEADLESS-RESULT-20261107.md) · [독립 구현 심사](../../../tmp/p02-first-integration-20261105/REVIEW-5B-NON-ASTRA-20261107.md) · [독립 마감](../../../tmp/p02-first-integration-20261105/REVIEW-CLOSEOUT-NON-ASTRA-20261107.md)
- [x] **CLI → AutoResolver worker.** `--operation-worker`는 명시 전원 delegate·policy none의 제한 입력을 받는다. worker가 owner를 생성·진행·종료하고, 메인은 join 후 결과 사본을 공개한다. 취소와 미게시 결과 폐기, 자연종료와 timeout, 동기 CLI 결과 대조를 검증했다. 정본 3/K6, 실제 53개 프로세스. [결과](P02-WORKER-RESULT-20261107.md) · [정본 실행](../../../tmp/p02-next-20261107/attempt3/results.json) · [독립 구현 심사](../../../tmp/p02-next-20261107/REVIEW-5B-INDEPENDENT.md) · [독립 마감](../../../tmp/p02-next-20261107/closeout/REVIEW-CLOSEOUT-INDEPENDENT-20261108.md)

## 한정 구현 수용 — 제한 fresh replay CLI

- [x] 기존 실행기에 `--operation-replay`를 추가하는 계획이 독립 심사에서 한정 수용됐다. 공통 어댑터가 만든 fresh owner에 명시 명령을 동틱 입력 순서대로 적용하는 새 CLI 소비자다. 제품 replay 및 legacy trace 재생은 별도 항목이다. [계획](../../../tmp/p02-third-20261108/PLAN.md) · [독립 계획 판정](../../../tmp/p02-third-20261108/REVIEW-PLAN-INDEPENDENT.md)
- [x] 실제 CLI와 native 오라클을 대조하고 독립 구현 5-b 한정 수용을 받았다. 2/K6 74/75 및 3/K6 BattleFlow 단일 재실행으로 최종 75사례를 통과했다. [결과](P02-REPLAY-RESULT-20261108.md) · [독립 판정](../../../tmp/p02-third-20261108/REVIEW-5B-INDEPENDENT.md)
- [ ] 문서·새 ZIP의 독립 마감 판정 진행 중. [전용 체크리스트](P02-REPLAY-CHECKLIST-20261108.md) · [최신 인계](SESSION-HANDOFF-P02-REPLAY-20261108.md)

## 남은 인수

- [ ] **FleetBattle3D 제품 호스트.** 공통 입력으로 새 후보를 준비하고 검증 성공 후에만 화면에 게시한다. 시계와 초기 controls, 배치/명령, 투영/사건, UI 선택·카메라·trace의 소유권과 실패 시 기존 세션 보존을 함께 검증한다.
- [ ] **WorldMap 제품 경로.** 제품 operation 입력, 실제 작업 시작·취소·join 책임, 진행 표시와 `BattleOutcome` 결산을 연결하고 기존 `BattleBrief` 경로와 대조한다. 현재 CLI worker 요약·사건 DTO는 제품 결산의 인수 근거로 쓰지 않는다.
- [ ] **제품 replay 소비 경로.** 현재 `BattleSim.replay`의 확인된 호출자는 테스트다. 제품 진입점과 초기화·명령/사건 적용 책임을 정하고 검증한다. 기존 진단 trace의 재생, checkpoint·cursor, 외부 저장/재개는 별도 계약이다.
- [ ] **I01/K01~08 소비자 공동 인수.** 지원 프로필과 source→effective 변환·ID, 실제 초기화/시계/controls, 명령·사건 순서와 경계, 지원 밖 입력의 명시 실패와 실패 원자성, legacy 호환을 실제 소비자들에서 함께 확인한다. 제한 CLI의 identity 경로와 부분 회귀는 이 전체 인수와 분리한다.
- [ ] **미검증 항목.** 공급 완료 사건 E2E는 앞선 제한 CLI와 이번 replay 검사에서 미관측이다. OS 수준 `Thread.start` 실패, 엔진 예외, 디스크 쓰기 장애 및 동시 writer는 주입 검증을 하지 않았다. 제품 화면, Android, 성능도 미검증이다.
- [ ] **기존 진단과 편차.** `--no-chain`, `--no-m9`, `--wind` 혼용은 기대한 `conflicting_option` 대신 `unknown_option`으로 exit 1 거부된다. WorldLink는 통과했고 기존 ObjectDB/리소스 종료 진단이 남는다. 전체 `git diff --check`는 기존 `CHECKLIST-OPEN.md` 33행의 후행 공백으로 exit 2다. [worker 정본 결과](P02-WORKER-RESULT-20261107.md) · [현재 조각 계획 기준선](../../../tmp/p02-third-20261108/baseline-context.json)

## 갱신 기준

구현 중에는 미완료 상태와 다음 판정만 기록한다. 실제 실행과 독립 5-b의 정본이 생기면 날짜, 적용 범위, 실행·심사 링크와 관측된 편차를 갱신한다. 이전 문서의 당시 판정은 보존하고, 후속 독립 마감은 이 파일에서 별도로 연결한다. 제품 소비자 공동 인수와 외부 schema 판정은 각각의 정본 근거로만 변경한다.
