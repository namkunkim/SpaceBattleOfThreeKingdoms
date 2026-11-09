# P02 진행 체크리스트

갱신 2026-11-09 KST. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 상위 인수 항목은 [세션 요구사항 체크리스트의 P02 행](SESSION-REQUIREMENTS-CHECKLIST-20261031.md)을 따른다.

## 최신 상태 — 직접 출격 난이도 적용 검증

- [x] **K6 현황과 P03 공유 쓰기 순서 기록.** K1~K5 이력과 미실행 K6 한 회, 최종 독립 수용 부재를 구분했다. FleetBattle3D·adapter·owner 등의 현재 SHA와 hunk별 쓰기 창 제안 및 재동결 조건을 기록했다. 이는 상대 작업의 실제 쓰기 예약이나 공동 인수가 아니다. [공유 쓰기 조율](P02-P03-WRITE-COORDINATION-20261109.md)
- [x] **문제 확인과 격리 후보 준비.** 천하 지도에서 선택한 난이도가 전투 명세와 결과에는 전달되지만 직접 전투 준비의 시나리오에는 호스트 기본값이 쓰이는 경로를 확인했다. 선택 난이도를 준비 후보에 적용하고 성공한 경우에만 게시하는 수정은 격리 후보에만 있다. [계획 독립 심사](../../../tmp/p02-pc-next3-20261109/REVIEW-PLAN-V2-INDEPENDENT.md)
- [ ] **난이도 동작 검증 및 원본 반영.** 첫 격리 실행은 import 통과 후 D01 검증 스크립트의 타입 추론 오류로 중단됐다. 실제 난이도 단언·수정 후보·GUI 검증은 실행되지 않았으며 이 오류를 예상된 기준선 실패로 집계하지 않는다. 실행 세트 1회는 소진됐다. 타입 명시만 바꾼 검증 스크립트 후보를 준비했으나 재검증은 하지 않았다. 별도 실행 계획과 독립 심사, 실제 GUI 검증 및 구현 심사가 남아 있다. [실행 결과 독립 심사](../../../tmp/p02-pc-next3-20261109/prepare-01/REVIEW-ATTEMPT-01-INDEPENDENT.md) · [실행 기록](../../../tmp/p02-pc-next3-20261109/prepare-01/ATTEMPT-01-RESULT.md)
- [ ] **검증 공간 확보.** 실패한 격리 실행의 `.godot` 캐시 334,714,530 bytes를 경로·reparse point·Godot 프로세스 부재 확인 후 정리했다. 정리 직후 C: 여유 공간은 2,565,124,096 bytes로 기존 실행 계획의 시작 기준 2.9 GB 미만이다. 격리 프로젝트의 나머지와 로그·원본·다른 작업은 보존했다. 재실행 전 공간과 대상 경계를 다시 확인한다.
- [ ] **첫 PC 플레이와 P02 전체 인수.** PC0의 기존 2회는 소진됐고 실제 입력·전투·자연 종료 근거는 없다. 별도 여덟째 K6은 미실행이며 첫 PC 플레이의 기술적 선행조건으로 취급하지 않는다. 제품 operation과 동일 버전 저장·재개를 포함한 남은 인수는 아래 항목과 상위 요구사항을 따른다.

## 최신 상태 — 천하 복귀 실패 안내

- [x] **즉시 복귀 거절과 재시도 안내.** 일시정지·결과·최초 준비 실패에서 한글 안내를 표시한다. 격리 28개 명령·728개 단언과 1600×900 앱 viewport PNG 18개를 검토했고 네 파일을 반영했다. 준비 화면 버튼은 기준선보다 25px 내려갔다. 원본 반영 후 Godot은 재실행하지 않았다. [결과](P02-WORLD-RETURN-NOTICE-RESULT-20261109.md) · [체크리스트](P02-WORLD-RETURN-NOTICE-CHECKLIST-20261109.md) · [인계](SESSION-HANDOFF-P02-WORLD-RETURN-NOTICE-20261109.md).
- [ ] **전달 독립 마감 대기.** OS 입력·다른 DPI·자연 종료·제품 operation은 미검증이다. PC0 2/2와 별도 여덟째 K6 상태를 유지한다. [전달 ZIP](../../../tmp/p02-return-notice-20261109/P02-WORLD-RETURN-NOTICE-DELIVERY-20261109.zip).

- [x] **전달 독립 마감 후속.** 즉시 복귀 거절 안내를 한정 수용했다. ZIP의 마감 대기는 생성 시점 기록이다. 완료된 이번 격리 실행의 Godot 생성 캐시 한 곳을 정리해 C: 자유 공간이 약 335 MB 늘었다. 로그·PNG·ZIP을 보존했으며 동일 격리 프로젝트 재실행에는 재임포트가 필요하다. [독립 마감](../../../tmp/p02-return-notice-20261109/REVIEW-CLOSEOUT-INDEPENDENT.md) · [공간 정리](../../../tmp/p02-return-notice-20261109/CACHE-CLEANUP-RESULT.json).

## 최신 상태 — 전장 → 천하 전환 거절

- [x] **기존 복귀의 즉시 전환 오류 복구.** 결과·일시정지·최초 준비 실패의 실제 로더 거절에서 Brief와 이전 대기 Outcome 참조를 복원한다. 2회차 격리 20개 실행·210개 단언을 통과했다. 후보는 각 경로에서 실제 거절 두 번 뒤 같은 전장과 버튼으로 재시도했다. 원본 한 함수 반영과 후보 바이트 일치, 기존 출격 hunk 보존을 독립 확인했다. 반영 뒤 Godot은 미실행이다. [결과](P02-WORLD-RETURN-REJECT-RESULT-20261109.md) · [체크리스트](P02-WORLD-RETURN-REJECT-CHECKLIST-20261109.md) · [인계](SESSION-HANDOFF-P02-WORLD-RETURN-REJECT-20261109.md).
- [ ] **전달 독립 마감.** ZIP 생성 시점의 상태다. 이 조각 2/6회 사용. PC0 2/2 소진, 별도 여덟째 K6 미실행, 첫 PC 플레이·자연 종료·제품 operation은 미인수다. [전달 ZIP](../../../tmp/p02-pc-next2-20261109/delivery-precloseout/P02-WORLD-RETURN-REJECT-DELIVERY-20261109.zip).

- [x] **전달 독립 마감 후속.** ZIP 외부의 독립 심사에서 기존 즉시 복귀 거절 조각을 한정 수용했다. 닫힌 격리 실행의 Godot 캐시 세 곳을 정리해 C: 여유가 약 1.01 GB 늘었다. 검증 로그·입력 매니페스트·ZIP은 보존했으며 캐시 재현에는 재임포트가 필요하다. [독립 마감](../../../tmp/p02-pc-next2-20261109/REVIEW-CLOSEOUT-INDEPENDENT.md) · [공간 정리](../../../tmp/p02-pc-next2-20261109/cache-cleanup-result.json).

## 최신 상태 — 직접 출격 장면 전환 거절

갱신 2026-11-09 03:44 KST.

- [x] **기존 직접 출격의 즉시 전환 오류 복구.** 장면 전환이 즉시 거절되면 WorldLink의 이전 명세·결과 참조와 난이도·모드를 되돌리고, 천하 지도의 출격 전 화면·입력·결산을 복구해 다시 출격할 수 있게 한다. 실제 씬 로더 거절은 양쪽 각 4회, 후보 복구는 45/45다. 격리 14개 lane과 독립 5-b를 통과했고 원본 반영 뒤 후보 바이트와의 일치를 독립 확인했다. 반영 뒤 Godot·OS 입력은 미실행이다. 이 조각은 3/6회 사용했다. [결과](P02-DIRECT-SCENE-REJECT-RESULT-20261109.md) · [전용 체크리스트](P02-DIRECT-SCENE-REJECT-CHECKLIST-20261109.md) · [인계](SESSION-HANDOFF-P02-DIRECT-SCENE-REJECT-20261109.md).

- [x] **전달 독립 마감.** 기존 직접 출격의 즉시 전환 거절 복구를 한정 수용했다. 전달 ZIP의 마감 대기는 생성 당시 상태이며 최종 판정은 ZIP 밖에 있다. 원본 반영 뒤 Godot은 미실행이며 첫 PC 플레이·자연 종료·제품 operation은 미인수다. PC0 2/2 소진과 별도 여덟째 K6 미사용을 유지한다. [전달 ZIP](../../../tmp/p02-pc-next-20261109/delivery-precloseout/P02-DIRECT-SCENE-REJECT-DELIVERY-20261109.zip) · [독립 마감](../../../tmp/p02-pc-next-20261109/REVIEW-CLOSEOUT-INDEPENDENT.md).

## 최신 상태 — K6 사전 준비와 독립 심사

이 절은 기존 독립 마감과 전달 ZIP 생성 이후의 작업을 기록한다.

- [x] **기존 한정 수용 범위의 로컬 커밋.** 확인한 HEAD는 `0be09755`다. 격리 프로젝트 실행 결과와 커밋 사후 확인을 보존했다. [실행 기록](../../../tmp/p02-space-cleanup-20261108/commit-plan/final-processes.json) · [커밋 거래 기록](../../../tmp/p02-space-cleanup-20261108/commit-plan/commit-transaction.json) · [사후 확인](../../../tmp/p02-space-cleanup-20261108/commit-plan/commit-postcheck.json)
- [x] **임시 Godot 캐시 정리.** 격리 실행용 `.godot` 14개를 정리해 C: 여유 공간이 약 9.78 GiB 늘었다. [정리 및 보존 확인](../../../tmp/p02-space-cleanup-20261108/cleanup-result.json)
- [x] **K6 재개 선행계획과 A/B 초안 독립 검토.** 7개 suite의 원문 출처와 V5 명령 연결을 정리했다. worker·replay의 정상 분기 예상치는 정적 대조까지 확인했다. [선행계획](../../../tmp/p02-ninth-20261108/NEXT-PLAN.md) · [독립 계획 심사](../../../tmp/p02-ninth-20261108/REVIEW-NEXT-PLAN-INDEPENDENT.md) · [A/B 초안](../../../tmp/p02-ninth-20261108/prep-ab-sol/PREP-AB.md) · [독립 A/B 심사](../../../tmp/p02-ninth-20261108/REVIEW-PREP-AB-INDEPENDENT.md)
- [x] **7개 suite와 행 19~21의 정적 분모·legacy 대조.** 동적 반복, 조기 종료 때 빠지는 단언, WorldLink clean의 기존 허용 편차를 정리했다. 실제 반복 수·대상 ID·버튼 목록과 typed native 값은 검증 전이며 분모는 미동결이다. [분모와 legacy 계약](../../../tmp/p02-ninth-20261108/prep-ab-sol/DENOMINATORS-AND-LEGACY.md) · [독립 분모 심사](../../../tmp/p02-ninth-20261108/REVIEW-DENOMINATORS-INDEPENDENT.md)
- [x] **Q/C/B 준비 중 C side 1 v9 합성 판정기 한정 수용.** 검토 범위는 context·contact·fleet position의 합성 비교다. [v9 결과](../../../tmp/p02-ninth-20261108/prep-ab-sol/C-SIDE1-PIPELINE-V9-REVIEW.md) · [독립 v9 심사](../../../tmp/p02-ninth-20261108/REVIEW-C-SIDE1-V9-INDEPENDENT.md)
- [ ] **실제 C producer와 독립 오라클.** 설계는 조건부 수용 상태다. 원문 fixture segment당 복원 호출 5회, packet·return·전후 상태·객체 identity·alias 분리·geometry를 같은 실행의 원시 증거로 잇는 producer와 최종 오라클은 미구현이다. [통합 계획](../../../tmp/p02-ninth-20261108/prep-ab-sol/C-PRODUCER-AND-K6-INTEGRATION-PLAN.md) · [독립 통합 계획 심사](../../../tmp/p02-ninth-20261108/REVIEW-C-PRODUCER-INDEPENDENT.md)
- [ ] **비제품 사전 적합성.** Variant ABI v2의 엄격 비교기와 합성 cap 조각만 한정 수용됐다. 실제 엔진 ABI 및 OS 격리 시험은 실행 미승인이다. 실제 Godot Job 자손·종료 정리와 요청별 GUI 입력 주체·대상 프로세스 귀속은 미검증이다. [독립 ABI v2 심사](../../../tmp/p02-ninth-20261108/REVIEW-NONPRODUCT-VARIANT-ABI-V2-INDEPENDENT.md) · [OS 격리 probe 계획](../../../tmp/p02-ninth-20261108/prep-ab-sol/MANAGED-CHILD-SANDBOX-PROBE-PLAN.md)
- [x] **P03 공동 소유 경계 기록.** FleetBattle3D·공유 초기화, P03 private state, UI Sound 수명 경계를 기록했다. 이 기록은 작성 시점의 상태이며 HEAD lane은 병행 P03 변경과의 결합을 검증하지 않는다. [P02·P03 조율 기록](../../../tmp/p02-ninth-20261108/P02-P03-OWNERSHIP-20261109.md)
- [ ] **마지막 K6 한 회와 독립 5-b.** 실행 0회, 제품 21행 미충족, native 초기화 후보는 원본 제품에 미적용이다. 사전 적합성, 실제 7개 suite의 동적 분모 판정 계약, 21행 manifest와 고정 입력을 독립 검토한다. 병행 P03 9행과 worker 작업 트리 2행을 보호하고, P03을 포함하는 경우 양쪽 격리 실행에 동일 snapshot을 고정한다. [독립 계획 심사](../../../tmp/p02-ninth-20261108/REVIEW-NEXT-PLAN-INDEPENDENT.md)

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

## 미완료 — 두 제품 소비자의 공통 native 초기화 후보

- [ ] 격리 후보만 준비했다. 원본 제품 코드는 미적용이며 제품 operation·실제 UI 인수는 남아 있다. K1·K2는 비정본이다. K3는 일부 native 대조를 통과했고 K4는 WorldMap 정상 완료·취소를 viewport 입력으로 확인했다. 별도 오류 뒤 재시도는 175초 제한 뒤 join 단언이 실패했다. K4 GUI exit 81, K5 마우스 이벤트 주체 미확인으로 실제 OS 입력 근거는 미충족이다. PID·HWND·전경 확인 전 추가 OS 입력을 보류했다. K6은 미실행이고 계획 21행과 독립 5-b 수용은 미완료다. [중단 인계](../../../tmp/p02-eighth-20261108/SESSION-HANDOFF-INCOMPLETE.md) · [실행 근거](../../../tmp/p02-eighth-20261108/IMPLEMENTATION-EVIDENCE.md) · [격리 후보 패치](../../../tmp/p02-eighth-20261108/candidate-product.patch) · [재개 인계](../../../tmp/p02-eighth-resume-8d838216ccfc/SESSION-HANDOFF-INCOMPLETE.md) · [준비 V5 독립 심사](../../../tmp/p02-eighth-resume-8d838216ccfc/REVIEW-PREPARED-V5-INDEPENDENT.md)
- [ ] 재개 준비 V5의 계획 분모는 21행이며 58개 프로세스와 합산 상한 20,270초는 실행 전 산정이다. timeout 안전 경로는 정적·합성 자료로 확인했다. 7종 suite 기준선 분모, GUI 연속 전경·입력 귀속, 실제 Godot console 자손·중첩 Job 검증이 남아 K6 실행은 독립 심사에서 반려됐다. 남은 한 회의 전체 계획이 독립 재심을 통과해야 실행할 수 있다.

## 미완료 — 첫 PC 직접 출전 기준선

- [ ] PC0는 2/2회 소진했다. run01은 임포트의 추가 Job 멤버 가드에서 중단했다. run02는 격리 확인·임포트가 통과했으나 제품 창이 전경 대상과 달랐고 첫 CUA 캡처 호출이 막혔다. 브리핑 상한에서 소유 Job이 정리됐다(root exit 125, active 0). 기록된 입력·전투·자연 종료·결산 근거가 없다. 두 회를 다시 실행하지 않는다. 첫 PC 플레이와 제품 operation은 NOT_READY이며 여덟째 후보 K6은 미실행이다. [인계](SESSION-HANDOFF-P02-PC0-20261109.md) · [run02 독립 심사](../../../tmp/p02-first-pc-20261109/REVIEW-PC0-RUN-02-INDEPENDENT.md)

## 남은 인수

- [ ] **FleetBattle3D 제품 operation 호스트.** 공통 operation 입력으로 새 후보를 준비하고 검증 성공 후에만 화면에 게시한다. 시계와 초기 controls, 배치/명령, 투영/사건, UI 선택·카메라·trace의 소유권과 실패 시 기존 세션 보존을 함께 검증한다.
- [ ] **WorldMap 제품 경로.** 제품 operation 입력, 실제 작업 시작·취소·join 책임, 진행 표시와 `BattleOutcome` 결산을 연결하고 기존 `BattleBrief` 경로와 대조한다. 현재 CLI worker 요약·사건 DTO는 제품 결산의 인수 근거로 쓰지 않는다.
- [ ] **제품 replay 소비 경로.** 현재 `BattleSim.replay`의 확인된 호출자는 테스트다. 제품 진입점과 초기화·명령/사건 적용 책임을 정하고 검증한다. 기존 진단 trace의 재생, checkpoint·cursor, 외부 저장/재개는 별도 계약이다.
- [ ] **I01/K01~08 소비자 공동 인수.** 지원 프로필과 source→effective 변환·ID, 실제 초기화/시계/controls, 명령·사건 순서와 경계, 지원 밖 입력의 명시 실패와 실패 원자성, legacy 호환을 실제 소비자들에서 함께 확인한다. 제한 CLI의 identity 경로와 부분 회귀는 이 전체 인수와 분리한다.
- [ ] **미검증 항목.** 공급 완료 사건 E2E는 앞선 제한 CLI와 이번 replay 검사에서 미관측이다. OS 수준 `Thread.start` 실패, 엔진 예외, 디스크 쓰기 장애 및 동시 writer는 주입 검증을 하지 않았다. 제품 화면, Android, 성능도 미검증이다.
- [ ] **기존 진단과 편차.** `--no-chain`, `--no-m9`, `--wind` 혼용은 기대한 `conflicting_option` 대신 `unknown_option`으로 exit 1 거부된다. WorldLink는 통과했고 기존 ObjectDB/리소스 종료 진단이 남는다. 전체 `git diff --check`는 기존 `CHECKLIST-OPEN.md` 33행의 후행 공백으로 exit 2다. [worker 정본 결과](P02-WORKER-RESULT-20261107.md) · [현재 조각 계획 기준선](../../../tmp/p02-third-20261108/baseline-context.json)

## 갱신 기준

구현 중에는 미완료 상태와 다음 판정만 기록한다. 실제 실행과 독립 5-b의 정본이 생기면 날짜, 적용 범위, 실행·심사 링크와 관측된 편차를 갱신한다. 이전 문서의 당시 판정은 보존하고, 후속 독립 마감은 이 파일에서 별도로 연결한다. 제품 소비자 공동 인수와 외부 schema 판정은 각각의 정본 근거로만 변경한다.
