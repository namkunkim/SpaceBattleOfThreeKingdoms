# P02 진행 체크리스트

갱신일 2026-11-08 KST. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 상위 인수 항목은 [세션 요구사항 체크리스트의 P02 행](SESSION-REQUIREMENTS-CHECKLIST-20261031.md)을 따른다.

## 한정 수용 완료

- [x] **첫 headless 연결.** 기존 실행기의 `--operation-input`이 제한된 runtime-ready 입력을 공통 어댑터로 한 번 검증해 private owner를 생성한다. 공개 투영을 쓰는 정책, 틱 진행과 순서 있는 사건 회수, 실패 시 출력 경계, legacy 출력 비교를 검증했다. 정본 3/K6. [결과](P02-FIRST-HEADLESS-RESULT-20261107.md) · [독립 구현 심사](../../../tmp/p02-first-integration-20261105/REVIEW-5B-NON-ASTRA-20261107.md) · [독립 마감](../../../tmp/p02-first-integration-20261105/REVIEW-CLOSEOUT-NON-ASTRA-20261107.md)
- [x] **CLI → AutoResolver worker.** `--operation-worker`는 명시 전원 delegate·policy none의 제한 입력을 받는다. worker가 owner를 생성·진행·종료하고, 메인은 join 후 결과 사본을 공개한다. 취소와 미게시 결과 폐기, 자연종료와 timeout, 동기 CLI 결과 대조를 검증했다. 정본 3/K6, 실제 53개 프로세스. [결과](P02-WORKER-RESULT-20261107.md) · [정본 실행](../../../tmp/p02-next-20261107/attempt3/results.json) · [독립 구현 심사](../../../tmp/p02-next-20261107/REVIEW-5B-INDEPENDENT.md) · [독립 마감](../../../tmp/p02-next-20261107/closeout/REVIEW-CLOSEOUT-INDEPENDENT-20261108.md)

## 한정 수용 완료 — 제한 fresh replay CLI

- [x] 기존 실행기에 `--operation-replay`를 추가하는 계획이 독립 심사에서 한정 수용됐다. 공통 어댑터가 만든 fresh owner에 명시 명령을 동틱 입력 순서대로 적용하는 새 CLI 소비자다. 제품 replay 및 legacy trace 재생은 별도 항목이다. [계획](../../../tmp/p02-third-20261108/PLAN.md) · [독립 계획 판정](../../../tmp/p02-third-20261108/REVIEW-PLAN-INDEPENDENT.md)
- [x] 실제 CLI와 native 오라클을 대조하고 독립 구현 5-b 한정 수용을 받았다. 2/K6 74/75 및 3/K6 BattleFlow 단일 재실행으로 최종 75사례를 통과했다. [결과](P02-REPLAY-RESULT-20261108.md) · [독립 판정](../../../tmp/p02-third-20261108/REVIEW-5B-INDEPENDENT.md)
- [x] 문서와 전달 ZIP이 독립 마감에서 한정 수용됐다. ZIP 안 문서의 마감 대기 표기는 생성 당시 상태다. 생성 후 독립 마감 판정은 별도 기록에 있다. [전용 체크리스트](P02-REPLAY-CHECKLIST-20261108.md) · [최신 인계](SESSION-HANDOFF-P02-REPLAY-20261108.md) · [전달 ZIP](../../../tmp/P02-REPLAY-DELIVERY-20261108.zip) · [독립 마감](../../../tmp/p02-third-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md)

## 한정 수용 완료 — private owner 표시용 사건 회수

- [x] 제한 private owner가 정수 0/1을 받아 기존 안개 규칙대로 사건을 회수한다. 공유 큐 소진·실패 불변·반환 사본을 native와 대조했다. 비-Astra 독립 재심에서 한정 수용됐다. 호출은 소유 스레드에서 직렬로 수행한다. 표시용 회수와 raw drain은 같은 큐를 소진하며, raw drain은 여전히 원본 사건을 반환한다. 기본 17개, 신규 검사 14행·148개 단언, 격리 보완 회귀 14개와 탐침 3개를 별도로 기록한다. 실제 제품 호스트 연결은 남은 인수에 해당한다. [결과](P02-VIEWER-EVENTS-RESULT-20261108.md) · [전용 체크리스트](P02-VIEWER-EVENTS-CHECKLIST-20261108.md) · [최신 인계](SESSION-HANDOFF-P02-VIEWER-EVENTS-20261108.md) · [독립 재심](../../../tmp/p02-fourth-20261108/REVIEW-5B-REBASELINE-INDEPENDENT.md)

- [x] 문서와 전달 ZIP이 비-Astra 독립 마감에서 한정 수용됐다. ZIP 안의 마감 대기 표기는 생성 당시 상태이며, 이후 판정은 외부 심사 기록에 있다. [전달 ZIP](../../../tmp/P02-VIEWER-EVENTS-DELIVERY-20261108.zip) · [독립 마감](../../../tmp/p02-fourth-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md)

## 한정 수용 완료 — legacy WorldMap 결산 경계

- [x] 실제 legacy 자동 해결 worker의 결산 사본과 메인 join 후 게시 경계를 분리했다. 제품 자동·직접 공통 18행·106단언은 전후 일치했고 사후 경계 7행·33단언은 통과했다. clean-user WorldLink 기존 단일 실패와 returning-user 통과를 따로 기록한다. 독립 5-b 한정 수용이며 제품 operation은 미완료다. [결과](P02-LEGACY-OUTCOME-RESULT-20261108.md) · [전용 체크리스트](P02-LEGACY-OUTCOME-CHECKLIST-20261108.md) · [최신 인계](SESSION-HANDOFF-P02-LEGACY-OUTCOME-20261108.md) · [전달 ZIP](../../../tmp/p02-fifth-20261108/closeout/P02-LEGACY-OUTCOME-DELIVERY-20261108.zip)

- [x] 전달 ZIP은 독립 마감 재심에서 한정 수용됐다. ZIP 안의 마감 대기 표기는 생성 당시 상태이며, 최종 판정은 별도 재심 기록에 있다. ZIP 이후 미귀속 파일 한 개의 변경과 새 경로 여섯 개를 관측했다. 이후 두 관측에서 미귀속 193개 경로의 해시가 일치했고 실행 입력과 겹치지 않았다. 순차 관측은 앞선 바이트나 변경 주체를 확정하지 못한다. [독립 마감 재심](../../../tmp/p02-fifth-20261108/closeout/REVIEW-CLOSEOUT-RECHECK-INDEPENDENT.md) · [보존 감사](../../../tmp/p02-fifth-20261108/closeout/post-zip-preservation-audit.json)

- [ ] 제품 적벽 operation 프로필과 WorldMap·FleetBattle3D UI 연결은 남아 있다. 이번 결산 검사는 기존 legacy 제품 경로와 headless 호출을 다뤘다. 실제 1,800초 상한 도달과 수동 GUI 확인은 미검증이다.

## 한정 수용 완료 — legacy FleetBattle3D 후보 준비

- [x] 실제 FleetBattle3D에서 새 전투 후보를 준비한 뒤 성공한 후보만 게시한다. 지정 bench patch의 두 명시 오류에서 기존 전투와 실제 출격·재시작·타이틀·편성 호출부의 동기 상태가 유지됐다. 공통 8행·27단언은 전후 일치했고 사후 10행·546단언과 복구 trace 대조를 통과했다. 예상 엔진 거절 진단 10건을 관측했다. clean-user WorldLink는 기존 단일 실패(exit 1), returning-user는 통과(exit 0)로 각각 기록했다. ObjectDB/리소스 종료 진단의 원인은 확정하지 않았다. [결과](P02-HOST-PREP-RESULT-20261108.md) · [전용 체크리스트](P02-HOST-PREP-CHECKLIST-20261108.md) · [인계](SESSION-HANDOFF-P02-HOST-PREP-20261108.md)

- [x] 최종 전달 ZIP은 독립 마감에서 한정 수용됐다. ZIP 안의 마감 대기 표기는 생성 당시 상태이며, 이후 판정은 외부 심사 기록에 있다. 마감 중 관측된 미귀속 경로 차이는 확인된 실행 입력 및 소유 파일과 겹치지 않았고 변경 주체는 확인되지 않았다. [최종 전달 ZIP](../../../tmp/p02-sixth-20261108/closeout-v2/P02-HOST-PREP-DELIVERY-20261108.zip) · [독립 마감](../../../tmp/p02-sixth-20261108/closeout-v2/REVIEW-CLOSEOUT-INDEPENDENT.md)

## 한정 수용 완료 — 전투 준비 실패 안내와 최초 탈출

- [x] 지정 준비 오류에서 기존 전투의 비모달 안내와 정상 게시 뒤 제거를 확인했다. 최초 실패에서는 구형 출격을 차단하고 단독 실행 종료 또는 결과 없는 천하 복귀를 제공한다. 사용자가 Escape로 실제 Windows 입력 검사를 멈춘 뒤 요청에 따라 재개했다. 기존 제품 버튼 03~08과 단독 종료는 이전 동결 입력의 Windows 근거이며, 현재 동결 입력에서 천하 복귀의 실제 마우스·키보드 입력 및 네이티브 렌더를 다시 확인했다. WorldMap 자동 해결 완료·취소는 제품 버튼에 전달한 자동 viewport 입력으로 별도 검증했다. [결과](P02-PREP-ERROR-RESULT-20261108.md) · [전용 체크리스트](P02-PREP-ERROR-CHECKLIST-20261108.md) · [인계](SESSION-HANDOFF-P02-PREP-ERROR-20261108.md)
- [x] 독립 구현 5-b와 전달 ZIP의 독립 마감은 이 범위를 한정 수용했다. ZIP 내부 마감 대기는 생성 당시 표기이며, 최종 판정은 ZIP 외부 독립 마감 기록에 있다. 최초 randomize 시작 트레이스 strict 비교는 7/8이었다. 고정 RNG의 별도 init_game 후속 한 행 전체 일치는 최초 시작 비교와 별개다. K1~K6을 사용했고 clean-user WorldLink의 기존 서막 단일 실패(exit 1)와 returning-user 통과(exit 0)를 재현했다. 기존 ObjectDB·리소스 종료 진단의 원인은 확정하지 않았다. [독립 5-b](../../../tmp/p02-seventh-20261108/REVIEW-5B-INDEPENDENT.md) · [최종 전달 ZIP](../../../tmp/p02-seventh-20261108/closeout/P02-PREP-ERROR-DELIVERY-20261108.zip) · [독립 마감](../../../tmp/p02-seventh-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md)
- [ ] 적벽 operation 지원, FleetBattle3D·WorldMap 제품 operation 연결과 P02 전체 인수는 남아 있다.

## 남은 인수

- [ ] **FleetBattle3D 제품 operation 호스트.** 공통 operation 입력으로 새 후보를 준비하고 검증 성공 후에만 화면에 게시한다. 시계와 초기 controls, 배치/명령, 투영/사건, UI 선택·카메라·trace의 소유권과 실패 시 기존 세션 보존을 함께 검증한다.
- [ ] **WorldMap 제품 경로.** 제품 operation 입력, 실제 작업 시작·취소·join 책임, 진행 표시와 `BattleOutcome` 결산을 연결하고 기존 `BattleBrief` 경로와 대조한다. 현재 CLI worker 요약·사건 DTO는 제품 결산의 인수 근거로 쓰지 않는다.
- [ ] **제품 replay 소비 경로.** 현재 `BattleSim.replay`의 확인된 호출자는 테스트다. 제품 진입점과 초기화·명령/사건 적용 책임을 정하고 검증한다. 기존 진단 trace의 재생, checkpoint·cursor, 외부 저장/재개는 별도 계약이다.
- [ ] **I01/K01~08 소비자 공동 인수.** 지원 프로필과 source→effective 변환·ID, 실제 초기화/시계/controls, 명령·사건 순서와 경계, 지원 밖 입력의 명시 실패와 실패 원자성, legacy 호환을 실제 소비자들에서 함께 확인한다. 제한 CLI의 identity 경로와 부분 회귀는 이 전체 인수와 분리한다.
- [ ] **미검증 항목.** 공급 완료 사건 E2E는 앞선 제한 CLI와 이번 replay 검사에서 미관측이다. OS 수준 `Thread.start` 실패, 엔진 예외, 디스크 쓰기 장애 및 동시 writer는 주입 검증을 하지 않았다. 제품 화면, Android, 성능도 미검증이다.
- [ ] **기존 진단과 편차.** `--no-chain`, `--no-m9`, `--wind` 혼용은 기대한 `conflicting_option` 대신 `unknown_option`으로 exit 1 거부된다. WorldLink는 통과했고 기존 ObjectDB/리소스 종료 진단이 남는다. 전체 `git diff --check`는 기존 `CHECKLIST-OPEN.md` 33행의 후행 공백으로 exit 2다. [worker 정본 결과](P02-WORKER-RESULT-20261107.md) · [현재 조각 계획 기준선](../../../tmp/p02-third-20261108/baseline-context.json)

## 갱신 기준

구현 중에는 미완료 상태와 다음 판정만 기록한다. 실제 실행과 독립 5-b의 정본이 생기면 날짜, 적용 범위, 실행·심사 링크와 관측된 편차를 갱신한다. 이전 문서의 당시 판정은 보존하고, 후속 독립 마감은 이 파일에서 별도로 연결한다. 제품 소비자 공동 인수와 외부 schema 판정은 각각의 정본 근거로만 변경한다.
