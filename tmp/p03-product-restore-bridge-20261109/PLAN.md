# P03 제품 복원 연결의 첫 검증 범위

## 현재 제품 경계

HEAD `0be09755b70378286105972f35ac5b7031715664`, index 비어 있음. owner와 P02 진행표는 기존 수정 상태다. 2026-11-09 재조회에서 `FleetBattle3D.gd`, runtime adapter, private owner의 SHA는 각각 `604b79308d9b3dbab84dced32456a4f41b28686c8eec748073d3816892cffc5c`, `0c0cad3e6e4e15887dcd75f9d5b57dbbe2690bfdcafd1caac163909b5421173a`, `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`이다. [정적 준비 독립 마감](../p03-product-restore-readiness-20261109/REVIEW-CLOSEOUT-6SOL.md)

현재 제품 공개 호출 `FleetBattle3D.init_game`은 176~183행에서 기존 새 전투 후보를 준비·게시한다. `_prepare_game` 306행은 raw `BattleSim.new`이며 `_publish_game` 316~345행은 표시·선택·두 프레임 시계를 새 전투 값으로 초기화하고 raw 사건을 drain한다. 이 함수를 운영 복원에 그대로 사용하면 packet 내 미소비 사건, UI 및 시계의 처리 의도가 섞인다. 478~535행은 raw step, 546~565행은 raw projection/filtered drain, 600행은 raw issue를 사용한다. 436행 결산은 raw sim을 읽는다.

현재 `OperationRuntimeAdapter.normalize` 23행은 checkpoint 키를 `unsupported_checkpoint`로 거부한다. 승인 대기 중인 P02 native 후보도 초기화 공통화에 한정한다. `OperationPrivateState.prepare` 316행은 제한 packet으로 별도 owner 후보를 만들 수 있으나 제품 호스트에서 받아 쓰는 공개 restore 연결을 찾지 못했다. 기존 owner의 `restore_completed` 성공만으로 raw 호스트의 표시·명령 경로가 새 후보에 묶이지 않는다. 운영에서 owner의 private sim을 꺼내 기존 raw sim 슬롯에 직접 꽂는 방식은 owner의 상태 책임과 가드를 우회한다.

같은 생산 범위에서 `capture_completed|restore_completed|suspend_requested|resume_requested|create_product_native`를 검색했다. owner 정의와 SessionGuard의 주석·signal·emit만 확인됐다. 다른 이름의 래퍼 및 동적·범위 밖 호출은 미조사다. P02 상태 조회 revision 17은 준비 합성 근거와 제품·Godot 실행을 구분해 기록하는 단계였다. P02 진행표와 조율 문서에서 원본 제품 후보 적용 및 공유 쓰기 창은 확인되지 않았다. [P02 진행표](../../docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [공유 조율](../p02-ninth-20261108/P02-P03-OWNERSHIP-20261109.md)

## 독립 검토 대상

| 단계 | 제안된 범위 | 파일·소유 경계 |
|---|---|---|
| 지금 가능한 현재 상태 확인 | 이전 P02 제품 경로 기록을 새 입력으로 오인하지 않고 보존한다. 현재 정본의 공개 `init_game`에서 정상 legacy 초기화와 기존 지정 오류 후 이전 상태 보존을 확인하는 독립 실행계획을 준비한다. 운영 restore라는 이름으로 집계하지 않는다. | 현재 제품 코드를 읽고 전용 runner에서 공개 init만 호출한다. 기존 P02 제품 실행 근거가 같은 입력·경계를 이미 충분히 덮으면 새 실행을 생략하고 정적 대조만 수용한다. |
| 1차 연결 후보 | 신규 시작 API 및 adapter normalize의 checkpoint 거부를 유지하고, 지원된 **메모리 packet**만 받는 별도 공개 준비 진입을 설계한다. P03의 prepare로 만든 후보 owner와 표시를 게시 전 검증하고, 한 소유자가 실패 후보를 정리한다. | P02와 `FleetBattle3D.gd:176` 인접 공개 진입·270행 인접 준비, runtime adapter 72행 인접 신규 준비 함수의 쓰기 창을 먼저 합의한다. 기존 P02 후보와 겹치는 준비 hunk를 동시에 고치지 않는다. 신규 API 이름·형식은 미정이다. |
| 제품 게시와 작동 | 복원 후보를 실제 사용하려면 owner 공개 API로 전진·명령·관측·사건을 묶고, 호스트 게시 이전 상태와 이후 상태를 각각 검사한다. raw 제품 결산·배치 및 trace 의존을 명시해 지원 범위 밖에는 공개 진입을 제공하지 않는다. | P02가 `FleetBattle3D.gd:316–345,478–535,546–565,600`과 결산·배치·trace의 소유를 명시한다. P03은 owner의 상태·참조·실패 오라클과 준비 계약을 제공한다. owner API 확장이 필요하면 별도 승인 hunk로 분리한다. |

제품 성공 후보의 준비부터 실제 첫 게시까지는 같은 시뮬레이션·tick·논리 clock·투영을 기준으로 검증한다. 기존 owner에 새 명령이 가지 않으며 미소비 사건을 초기화 drain에서 버리지 않는다는 독립 오라클이 필요하다. 실패는 기존 sim/owner identity, 두 누산기와 speed/pause, 선택·투영, pending과 사건 및 다음 정상 프레임을 대조한다. 첫 프레임 기대값은 phase 보존 또는 초기화 중 공동 인수한 한 계약으로 사전등록한다. 메모리 진입 시험에도 지원 프로필·구조 오류·공개 진입점, 정확한 이름·단언·예상 exit, 타임아웃, 엔진/클래스맵/입력 SHA 및 실제 로그와 프로세스 정리가 필요하다.

현재 P02와 공유 파일·hunk·쓰기 창의 합의 및 GPT-6 Sol 독립 계획 수용이 선행된다. 이 기록 작성 중 제품 실행과 공유 파일 변경은 없었다. BGM은 P09 범위다. 제품 저장 lifecycle·운영 커서·외부 ACK·저장 형식은 별도 인수다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
