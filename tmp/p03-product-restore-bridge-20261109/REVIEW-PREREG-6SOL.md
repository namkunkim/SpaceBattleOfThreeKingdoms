# 제품 메모리 복원 사전등록 초안 독립 심사 — GPT-6 Sol

판정: **준비 초안으로 수용, 실행 사전등록으로는 보류**. `PREREG-DRAFT.md` SHA-256 `feaf0e1ad3ec8f227bbbea1a0e972e55093864a97bfaf9489de06277b878955e` 기준이다. 구현·Godot 실행·공유 파일 편집에는 참여하지 않았다.

## 현재 경계 대조

`FleetBattle3D.init_game`은 아직 새 전투의 raw `BattleSim.new` 후보를 게시한다. 게시에서 두 TickClock을 새로 만들고 `sim.drain_events()`를 호출한다. `_process`와 `update_sim`, projection/filtered drain, raw issue·결산도 raw sim을 참조한다. `OperationRuntimeAdapter.normalize`의 `checkpoint` 입력은 `unsupported_checkpoint`로 거부된다. `OperationPrivateState.prepare`는 제한 packet에서 별도 owner를 만드는 경계이며, packet의 `view.sim`에는 `_queue`와 `_events`가 포함된다. owner는 공개 `advance`, `issue`, `read_projection`, `drain_events_for`, `summary`를 제공하지만 이 API가 현재 제품 표시·명령·결산 전체를 처리한다는 근거는 없다. 현재 정적 검색의 직접 제품 restore 호출 미발견은 지정 범위에만 적용한다.

P02 공동 조율과 최신 쓰기 조율 문서는 여덟째 초기화 후보 K6을 **5/6 사용, 마지막 K6 미실행**, 독립 5b 및 원본 제품 반영 전이라고 기록한다. 공유 `FleetBattle3D.gd`와 adapter의 쓰기 창은 없다. 현재 `FleetBattle3D.gd`는 기존 안내·복구 hunk로 Git 수정 상태이며 SHA-256 `029a11be7c08038f2ed4a482f0b2668bd924c842c33a2a671409cd486f0191c9`다. 이전 bridge 계획의 `604b...` 기준과 바이트가 달라 실제 patch/시험 전 최신 HEAD·index·각 hunk·보호 입력을 새로 동결해야 한다. 현재 owner의 기존 수정은 보존한다.

## 실행 전 확정할 계약

- **API와 제품 도달성:** 별도 공개 복원 진입인지 기존 `init_game`의 명시 분기인지 하나로 결정하고, 메모리 packet을 실제 제품 흐름에서 전달하는 호출자·스택·지원 profile을 지정한다. 테스트가 직접 공개 메서드를 호출한 결과는 격리 host/API 시험으로 귀속한다. 자연 제품 입력이 없으면 사례의 `product_` 이름과 제품 결과 집계를 쓰지 않는 초안 조건이 맞다. 신규 시작 adapter의 checkpoint 거부와 legacy 사용자를 별도 회귀로 유지한다.
- **시계:** owner packet은 sim 논리 tick/clock을 담지만 host의 두 TickClock phase와 speed/pause 저장 계약은 이 초안에서 정해지지 않았다. phase 보존을 채택하면 그 값을 어디서 가져와 검증하는지, 초기화를 채택하면 첫 프레임 기대값을 무엇으로 고정하는지 명시한다. 10Hz·acc .75·delta .05·1배속의 1틱/0틱 계산은 보존/초기화 비교로 타당하나 **둘 중 하나만** 성공 oracle로 사전등록해야 한다. `_process`와 `update_sim`은 서로 다른 누산기를 사용하므로 각 경로의 입력과 기대를 따로 기록한다.
- **사건과 게시:** packet `_queue`·`_events`의 원시 ID·순서와 첫 소비/두 번째 소비를 독립 oracle로 동결한다. 기존 `_publish_game`의 초기 `sim.drain_events()`가 복원 경로에 적용되지 않는 방법, 실패 후보 정리의 단일 소유자, 성공 전·후 단일 후보 identity와 이전 owner 명령 차단을 확정한다. UI 알림/외부 ACK를 이번 메모리 계약에 넣지 않는 범위는 적절하다.
- **실패 및 지원:** 구조 오류와 비지원 profile의 우선순위·정확 error/path를 정하고 host가 live인 경우와 private owner의 `busy`·활성 DecisionBoard guard를 구분한다. 기존 sim/owner identity, 두 clock, speed/pause, 선택·투영, pending·미소비 사건 및 다음 정상 프레임을 같은 공개 경계에서 대조한다.
- **분모와 실행:** 표의 7/12/6/3은 후보 묶음이며 단언별 입력·기대·오류·조기 종료 분기와 실제 exit를 결정하지 않았다. 제품 공개 호출의 지원 profile/fixture와 legacy 기준선, 네 사례별 독립 oracle, timeout·Job 자손/회수·원본/격리 입력 SHA·class map·stdout/stderr 및 예기치 않은 진단 0을 고정한 별도 실행 계획이 필요하다. K3은 이 후속 실행의 총 시도 상한으로 유지한다.

디스크 여유는 검토 시 약 **2.56 GB**다. P02 난이도 격리 실행의 기존 2.9 GB 시작 기준보다 낮지만 그 기준을 모든 P03 실행에 일반화할 수 없다. 이 조각은 격리 복제·import·로그의 예상 사용량과 최소 여유를 산정하고 실행 직전에 재확인해야 한다. P02 K6과 공유 소유·실행 창이 정해지기 전에는 제품 복원 구현/실행을 승인할 수 없다. 정적 준비 검토는 여기서 마감 가능하며 제품 성공·저장 lifecycle·운영 커서·외부 ACK·전체 P03 인수는 열려 있다. 검토 모델은 사용자 요청에 따른 GPT-6 Sol 배정이며 파일 내 별도 실행 모델 메타데이터는 없다.
