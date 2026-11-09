# P03 제품·worker owner와 스레드 경로 읽기 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 목표는 현재 제품 호스트, legacy 자동 해결 및 제한 worker/replay가 동일 OperationPrivateState 인스턴스에 접근할 수 있는지를 고정 원문에서 추적하는 것이다. 강제 busy 검증과 실제 자연 경합 도달을 분리한다. 기존 UI 호출 원장은 표시 경계 중심이므로, 이번에는 생성된 객체가 어느 스레드·콜백·DTO로 이동하거나 남는지를 본다. 전용 owner-thread-paths/ 밖에는 쓰지 않는다. P02 및 생산 파일 변경, 신규 실행·인위 스레드 경쟁 실험은 없다. 독립 수용 전 조사 산출물·검증 도구 구현 금지.

## 고정 조사 범위

| 경로 ID | 시작 → 끝 | 추적할 권위 및 스레드 |
|---|---|---|
| RAW_HOST | FleetBattle3D 후보 준비 → sim 게시 → frame step 및 종료 | raw sim의 별칭과 view/callback, OperationPrivateState와 동일 객체인지 |
| LEGACY_WORKER | WorldMap 실제 AutoResolver 시작 → legacy worker → poll/join → BattleOutcome 게시 | worker sim 참조 및 main으로 돌아오는 값, join 전 UI 접근 및 취소 |
| LIMITED_WORKER | start_operation → Thread/동결 입력 → adapter owner 생성 → advance/drain/close → poll/join | closure가 캡처하는 객체, worker-local owner 유출 여부와 메인 반환 DTO |
| LIMITED_REPLAY | fresh replay 진입 → adapter owner → queue/advance/drain → close/결과 | caller thread에서의 local owner, 반환 DTO와 raw/제한 replay 분리 |
| OWNER_PUBLIC | create/prepare → 공개 restore/capture/advance → _guard/close | busy가 적용되는 인스턴스, mutex 보호 범위와 guard 반환 우선순위, 참조 이전 |
| PRODUCT_JOIN | WorldLink/WorldMap 소비와 FleetBattle3D 결산 → UI/외부 결과 | 제품이 실제 호출하는 worker 진입과 제한 operation 소비자, 기존 UI/owner 보존 근거 |

원문 후보는 core/battle, scripts, scenes, hud, input, view의 현재 생산 .gd/.tscn에서 검색한다. 핵심 anchor는 operation_private_state.gd, operation_runtime_adapter.gd, operation_replay.gd, auto_resolver.gd, FleetBattle3D.gd, world_link.gd와 실제 WorldMap 소비자다. 검색 결과·생산 파일 집합·HEAD 및 SHA를 동결한다. 동적/반사 호출, 범위 밖 앱과 테스트는 생산 호출자 분모에서 제외한다. 테스트·기존 실행은 각 경로의 실제 관측에 한해서 별도 근거층으로 사용한다.

별도 비교 4개는 (raw host, 제한 worker), (legacy worker, 제한 worker), (제한 replay, 제한 worker), (같은 제한 owner의 동시 공개 호출)이다. 각 비교에서 객체 동일성을 입증할 생산 전달 경로, 호출자와 thread, shared mutable field, lock 범위, close 및 join 책임, 가능한 선행 조건, 근거를 기록한다. 검색에 나오지 않은 생산 연결은 미발견으로 분류한다. busy boolean을 스레드 동기화나 경쟁 안전성 근거로 사용하지 않는다. 두 작업이 병행 가능하다는 사실도 같은 객체의 경합 근거와 구분한다.

[busy Cn](../busy-cn/RESULT.md), [기존 lifecycle](../../p03-parallel-cursor-20261108/remaining-cursor-drain/lifecycle-readonly/LIFECYCLE-LEDGER.md), [제품/owner 경계](../../p03-parallel-active-20261108/owner-operational-boundary/REVIEW-CLOSEOUT.md), [UI 경로](../ui-callpaths/RESULT.md), [P02 진행표](../../../docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md) 및 최신 독립 실행/미완 인계를 읽는다. 각 행은 CURRENT_SOURCE, LIMITED_RUNTIME, NOT_FOUND_IN_SCOPE, UNVERIFIED를 주장별로 표시한다. 제품 owner 배선이나 동시 계약의 사용자 선택은 HOST_AUTHORITY 및 기존 소유권으로 귀속하고 새 정책을 채택하지 않는다.

## 5a·5b

분모는 경로 6개, 객체 겹침 비교 4개. 독립 수기 oracle은 위 ID/쌍과 원문 생성·join·close·DTO anchor, busy 직접 설정 판정을 별도로 확인한다. 5a는 6/4 exact 분모·고유 ID, 필수 소유/스레드/근거 및 정규 경로 SHA를 확인한다. 실제 자식 종료는 정상 0, LIMITED_WORKER 한 행 누락 1, 같은 제한 owner의 자연 제품 경합을 확인했다고 표시한 단일 승격 1, 존재하지 않는 근거 2로 고정한다. 모두 전용 사본이며 실제 child exit·stdout/stderr·차집합과 전후 manifest SHA/HEAD/Git을 보존한다. P02 동시 변화는 분리하고 변화 시 동결을 실패 처리한다. 승인 뒤 전용 run_gate.py에서 PowerShell ErrorActionPreference Stop과 LASTEXITCODE 전달로 실행한다. K=3. 한도 즉시 보고 및 중단. 독립 비-Astra 사후 검토가 객체 전달과 mutex/스레드·scope 한계, 실제 종료·보존을 대조한다.
