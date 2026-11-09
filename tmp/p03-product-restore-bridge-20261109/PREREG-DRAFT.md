# 제품 호스트 메모리 복원 첫 조각 — 사전등록 초안

현재 HEAD `0be09755b70378286105972f35ac5b7031715664`. 제품 호출과 공유 쓰기 창이 확인되기 전의 검토용 초안이다. [Bridge 계획](PLAN.md) · [독립 정적 마감](REVIEW-STATIC-CLOSEOUT-6SOL.md) · [P02 조율](../p02-ninth-20261108/P02-P03-OWNERSHIP-20261109.md)

## 제안 범위와 선결 대안

첫 긍정 fixture는 I01b와 C1의 제한 profile 형태를 후보로 삼는다. 현재 제품의 적벽 기본 입력을 지원된 것으로 간주하지 않는다. 실제 제품에서 도달 가능한 지원 profile과 호출자를 지정하기 전에는 긍정 결과를 제품 결과로 집계할 수 없다. 공개 호출은 메모리 packet을 인수하는 별도 진입 또는 기존 공개 API에 명시적인 별도 분기를 두는 방식 중 P02/P03이 합의한다. 두 경우 모두 신규 시작 adapter의 checkpoint 거부와 legacy 사용자를 비교하는 사례가 필요하다.

- **공개 계약**은 packet 후보를 준비하고 제품 게시 전에 검증하는 책임, 완료된 입력 형태, 정상·거부 반환 및 실패 후보 해제 시점을 고정한다. 제품 시작/복원 분기에서 packet이 실제로 들어오는 경로를 호출 스택과 함께 기록한다.
- **시계 계약**은 두 TickClock phase와 speed/pause를 보존하는 방식과, 같은 논리 tick에서 새 프레임 주기를 시작하는 방식을 따로 비교한다. 10Hz에서 `acc=0.75`, `delta=0.05`, 1배속의 기대 진행은 보존 1틱, 초기화 0틱이다. 두 누산기는 각 사용 경로에서 별도 대조하며 채택된 기대만 성공 조건으로 고정한다.
- **사건 계약**은 packet의 미소비 큐를 첫 게시 직전까지 보존하고 첫 실제 소비에서 원래 순서를 대조하는 방식, 또는 동등한 상태·순서를 가진 명시적 전달 경로를 두는 방식을 검토한다. 기존 새 전투 초기 raw drain이 복원 경로의 묵시적 소비가 되지 않게 한다. UI 알림이나 외부 효과의 ACK/중복 처리는 이번 메모리 조각에 포함하지 않는다.
- **실패 계약**은 동일한 공개 진입에서 비지원 및 구조 오류를 어떤 우선순위로 반환할지 사전등록한다. `busy`, 활성 DecisionBoard 및 다른 owner 가드가 적용되는 경계와 제품 host 반환의 차이를 분리한다.

## 변경·소유 경계 후보

| 쓰기 담당 | 대상 함수와 기준 hunk | 최소 범위 |
|---|---|---|
| P02/P03 합의 | `FleetBattle3D.gd:176–183` 공개 시작, `:270–311` 후보 준비 | 기존 legacy 초기화를 보존한 상태에서 채택된 공개 복원 분기와 후보 취득만 연결. P02 K6 후보의 raw 생성 교체 위치와 겹치므로 별도 쓰기 창 필요 |
| P02/P03 합의 | `operation_runtime_adapter.gd:20–29,72` | 기존 normalize를 계속 신규 시작에 사용. 별도 준비 façade가 필요할 때 72행 인접 신규 함수로 분리하고 `OperationPrivateState.prepare` 계약을 재사용 |
| P02 host | `FleetBattle3D.gd:316–345,478–535,546–565,600`, 기존 436행 결산 | 명시된 복원 후보의 단일 게시, owner 공개 API를 통한 전진·명령·투영·사건 전달. 기존 raw 결산·배치·trace의 전환이 이 조각에 들어가는지 결정 |
| P03 owner | `operation_private_state.gd:316,361,481` 준비·교체·종료 | 기존 메모리 packet 검증의 재사용을 우선하고 확장이 필요할 때만 owner hunk 별도 승인 |

줄 번호는 현재 읽기 기준이며 실제 패치는 최신 SHA와 정확한 before/after hunk를 독립 수용한 뒤 작성한다. 공유 코드·제품 초기화·adapter 수정은 P02 K6 실행 및 독립 판정을 확인하고 서로의 실행 창이 겹치지 않을 때만 시작한다.

## 실행 사례 초안

| ID | 입력 및 대조 | 독립 판정 분모 후보 |
|---|---|---|
| `product_memory_restore_publishes_one_candidate` | 실제 공개 호출에서 제한 packet 성공. 성공 전 기존 객체와 성공 후 후보 객체, 동일 logical tick/clock과 표시, 새 명령의 대상·이전 owner 미변경 확인 | 후보/이전 identity, tick/clock, 투영, 명령 대상, 이전 상태 7 |
| `product_memory_restore_rejection_preserves_host` | 동일 공개 호출에 구조 오류 또는 비지원 입력. 동기 반환 직후 기존 owner/sim, 두 누산기, speed/pause, 선택/투영, pending/미소비 사건을 비교하고 다음 정상 프레임을 무처리 대조군과 대조 | 반환, owner/sim, 두 phase, speed/pause, 선택/투영, pending/사건, 다음 프레임 12 |
| `product_restored_first_frame_phase_and_event_order` | 합의한 phase에서 두 시간 진입점을 별도로 실행. 동일 delta의 기대 진행과 논리 clock, 첫 소비 사건의 식별자·순서, 두 번째 소비 상태 확인 | 시간 경로별 tick/clock 및 ordered 첫 소비·두 번째 소비 6 |
| `legacy_product_init_preserved` | 동일 제품 공개 신규 초기화와 알려진 기존 거부를 기준선/후보로 대조. raw 기존 게시와 adapter 신규 시작 checkpoint 거부를 확인 | 정상, 실패 보존, adapter 거부 3 |

각 분모는 구조를 보여주는 후보이며, 실제 실행 전 하나씩 분해해 이름·정확 기대값·예상 오류·exit를 확정하고 GPT-6 Sol에게 독립 심사를 받는다. 자연 제품 입력을 마련하지 못하면 같은 사례를 격리 호스트로만 실행하고 분모 및 결과 이름에서 제품을 제거한다. 강제 raw sim 대입, private 필드로 공개 경로 우회, 정상 제품 근거 없는 session 저장 호출은 금지한다.

실행 전 최신 HEAD·index·대상 Git 상태, P02 최신 소유 및 동결 입력, 실제 console·엔진 본체·class map, 코드·packet·프로필·runner·oracle을 해시로 동결한다. before/after를 같은 입력으로 비교하고 fixture, 종료 코드, stdout/stderr, 시간 제한·Job 회수, 엔진 진단, SHA 및 신규/수정 경로를 보존한다. 상한 K3. P02 host 기존 정상 초기화·후보 실패 보존·adapter 회귀의 최신 독립 근거를 대조하고 변경 hunk가 닿는 회귀만 실행 목록으로 고정한다. 공유 진단과 P09 BGM은 기존 증거와 분리한다.

현재 디스크 제약과 P02 실행 창으로 복제나 실행을 시작하지 않았다. 외부 저장·운영 커서·ACK·전체 P03은 이 초안의 인수 대상에서 제외한다.
