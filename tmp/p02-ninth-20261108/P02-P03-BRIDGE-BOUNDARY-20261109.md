# P02 · P03 제품 복원 연결의 공유 경계

## 2026-11-09 00:50 KST 관측

HEAD `0be09755b70378286105972f35ac5b7031715664`, staged 경로 없음. FleetBattle3D, runtime adapter, auto resolver는 경로별 Git 상태에서 깨끗했다. private owner, worker 테스트, P02 진행표에는 기존 unstaged 변경이 있었다. P02 공유 제품 쓰기 창은 현재 없다. P02 제품 후보는 미적용이며 K1~K5 기록과 남은 K6 한 회를 유지한다. 21행 독립 계획 수용은 격리 K6의 선행 조건이다. 실제 제품 적용 검토는 K6 결과의 별도 독립 5-b 수용 이후다. [P02 진행표](../../docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [재개 인계](../p02-eighth-resume-8d838216ccfc/SESSION-HANDOFF-INCOMPLETE.md)

## 실제 후보 hunk와 복원 접점

| 위치 | P02 후보의 변경과 소유 | P03 복원 접점과 미정 사항 |
|---|---|---|
| `operation_runtime_adapter.gd` patch 문맥 10행 | P02는 `fail` 뒤 `create_product_native(profile, seed, mode)`를 추가한다. 호출자가 이미 준비한 effective Dictionary를 참조로 받아 새 raw `BattleSim`을 만들고 direct/auto 제어만 설정한다. | 현재 `normalize` 23행의 `unsupported_checkpoint` 거부와 `create` 72행은 후보 변경 범위 밖이다. P03 계획의 72행 인접 별도 packet 준비 진입은 제안이다. P03은 지원 guard와 준비 계약을, P02는 기존 adapter 호출 계약을 맡는다. 함수명·형식·삽입 위치는 미정이다. |
| `FleetBattle3D.gd` patch 문맥 303행 | P02는 `_prepare_game`의 legacy 생성 및 유비군 direct 설정을 교체하고 기존 seed, ally/foe 표시, errors/message/fallback/scenario를 전달한다. 신규 시작의 profile 준비·표시·실패 원자성은 P02 책임이다. | 현재 공개 `init_game` 176~183행과 `_prepare_game` 270행 인접 구간은 연결 후보 접점이다. P03은 메모리 packet에서 별도 owner를 준비·검증한다. 호스트가 그 후보를 받는 공개 진입과 단일 실패 후보 정리 책임자는 미정이다. |
| `FleetBattle3D.gd` 게시·프레임·명령 | 현 후보 hunk가 없다. 현재 `_publish_game` 316~345행은 새 전투 UI·선택·두 시계를 초기화하고 344행에서 raw 사건을 drain한다. 478~535행 raw step, 546~565행 raw projection/side 0 drain, 600행 raw issue에 더해 결산 436행과 배치·trace도 raw sim을 읽는다. P02는 호스트 초기화·프레임·명령 라우팅·표시의 인수 근거를 맡는다. | P03은 복원 owner의 identity·지원 범위·논리 tick/clock·사건 순서의 독립 기대값을 맡는다. raw 게시·drain을 그대로 호출하면 미소비 사건이 사라질 수 있다. owner 공개 API로 최초 게시 이후 전진·투영·사건·명령이 같은 후보에 연결되는 계약을 공동 인수한다. 첫 프레임 phase, 두 누산기 갱신 책임, UI 초기화 범위, 소비 시점은 미정이다. |
| `scripts/world/auto_resolver.gd` patch 문맥 40행 | P02는 기존 brief seed와 profile로 만드는 raw sim 및 auto 설정을 adapter 호출로 교체한다. 기존 worker 시작과 결산은 호출자 책임이다. | P03의 첫 제품 복원 계획은 FleetBattle3D 메모리 진입 범위다. auto/worker 복원 접점은 별도 범위다. |

P02 입력은 legacy profile과 변환·배치·제어 초기화이며, P03 입력은 지원 프로필의 제한 packet과 저장된 owner 상태다. `OperationPrivateState.prepare`로 만든 후보나 기존 owner의 `restore_completed` 성공은 raw 호스트 게시 경로를 연결하지 않는다. owner private sim을 raw 슬롯에 직접 꽂으면 상태 책임과 guard를 우회한다. P03의 제품 공개 복원 경로 미발견은 계획의 정적 검색 범위에 한정된다. [실제 후보 패치](../p02-eighth-20261108/candidate-product.patch) · [기존 조율](P02-P03-OWNERSHIP-20261109.md) · [P03 연결 계획](../p03-product-restore-bridge-20261109/PLAN.md)

## 증거 귀속과 제품 적용 선행

- 격리 사본에서는 P02의 before/after legacy 동등성과 신규 시작 오류 원자성, P03의 packet 지원·거부와 준비 후보의 상태, 시험용 연결의 게시·첫 프레임 동작을 각 입력과 진입점에 귀속해 검증할 수 있다. 직접 주입, owner 단독 복원, 변경 전 공개 init의 결과는 각각 해당 검증의 증거다. 실제 제품 적용과 복원 제품 공개 경로 인수는 별도다.
- 공유 파일을 쓰기 전 양쪽이 정확한 함수와 hunk, 실행 입력 closure, 쓰기·실행 순서 및 기존 증거 영향 범위를 맞춘다. P02 legacy 후보의 검토 게이트와 P03 계획의 Sol 독립 수용을 별도로 기록한다. 실제 연결의 지원 범위에 raw 결산·배치·trace 의존을 반영한다.
- 실제 제품 공개 복원 실행에서 P03은 지원·거부와 owner 상태, P02는 준비·게시·명령 대상·이벤트 소비·UI 연결을 각각 인수한다. 공통 성공 오라클은 게시 후보 identity, 첫 프레임 tick/clock 및 사건 순서, 새 명령의 전달 대상이다. 실패 오라클은 기존 sim/owner identity, 두 누산기, speed/pause, 선택·카메라·투영, pending·미소비 사건 및 다음 정상 프레임의 보존이다. phase 정책을 실행 전 고정한다. 제품 저장 lifecycle·운영 커서·외부 ACK·저장 형식과 O07은 별도 인수다.
- BGM 및 UI Sound 수명 조사는 P09로 유보한다. 비교 실행에서 오디오 입력과 종료 진단 조건을 기록한다.

## 동시 변경과 기준 SHA

P03 관련 private owner의 관측 diff는 HEAD Git blob `f7fa465b0527f54c42600b6a99a62046d9d59b27` 대비 typed Dictionary의 키·값 메타데이터 비교와 `restore_completed`의 `unsupported_active_decisions` guard를 추가한 9줄이다. 이 스냅샷은 현재 작업 트리 상태다. P02 K6의 동결 입력 채택 여부는 별도로 판정한다. 채택하면 동일 owner 바이트를 before/after 양쪽에 포함하고 차이는 P02 세 hunk로 제한한다. 실행이나 공동 적용 전 HEAD/index/status와 입력 SHA를 다시 확인하고 drift가 있으면 차이를 기록해 재동결한다.

| 00:50 KST 읽기 기준 | SHA-256 |
|---|---|
| P02 진행표 | `184573b37333f8d7eb5320b5e688e6eb8ef784612f10609ed11005a28228142c` |
| 기존 P02/P03 조율 | `6dc9d0e844881de10b321a42a5a60fd98a7deb2e7454fb8cee13b51cd569dea8` |
| 여덟째 재개 인계 | `381bea426fb8a3ab3cdf243089b29c657d5ff88d1d81cd57838b42b3e69ba9ae` |
| P02 candidate-product.patch | `46cf453f10d40619aea336c2ed5e18b8e0bb786d3d1ab5c2c59632a38726f438` |
| P03 bridge PLAN.md | `5034ddaedd4b0ee1413961c273d953d456fafdb3be4bc9254e95f6fb13181` |
| FleetBattle3D | `604b79308d9b3dbab84dced32456a4f41b28686c8eec748073d3816892cffc5c` |
| runtime adapter | `0c0cad3e6e4e15887dcd75f9d5b57dbbe2690bfdcafd1caac163909b5421173a` |
| auto resolver | `85ec124df59c0c50cee616565e88bcdd978588f28baf36180f8ec2c92eebd9eb` |
| private owner 작업 트리 | `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3` |
