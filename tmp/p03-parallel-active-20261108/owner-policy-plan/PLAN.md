# 제한 owner 활성 DecisionBoard 복원 정책 비교 계획

2026-11-08. 실제 작업 모델 gpt-6.1-sol은 로컬 rollout 10:16:37Z turn_context에서 확인했다. 이 문서는 독립 Terra 검토와 사용자 결정에 제출할 제안이다. 현재 HEAD는 `fb660cea69207fd332e26128643007694910a253`이다.

## 결정의 근거와 범위

강제 fixture에서는 기존 제한 sim에 붙인 정본 DecisionBoard 때문에 capture가 `unsupported_active_decisions`로 거부됐다. 유효한 같은 C0 패킷으로 공개 restore를 호출하자 성공했고, 새 sim에는 모듈이 없었다. 별개의 cycle-02는 정상 제한 owner에 비지원 scenario가 든 **후보** 패킷을 넣었을 때 원자 거부와 후속 진행을 확인했다. 제품 직접 생성 검사는 적벽 자동 편성의 DecisionBoard 생성과 제한 adapter의 scenario 입력 거부를 각각 확인했다. 정적 조사에서 실제 3D 호스트는 raw sim을 소유하고 제한 replay/worker는 fresh owner를 만든다. 조사 범위의 제품 호출에는 공개 restore가 없었다. 따라서 강제 fixture 결과는 현재 운영 장애나 제품 복원 정책 위반으로 판정할 수 없다. [강제 fixture 결과](../../p03-active-unsupported-20261108/RESULT.md), [공개 거부 독립 마감](../owner-contract/cycle-02/REVIEW-CLOSEOUT.md), [정적 독립 마감](../owner-operational-boundary/REVIEW-CLOSEOUT.md)

| 선택 | 사용자에게 생기는 변화 | 비용과 선행 결정 |
|---|---|---|
| **A. 기존 활성 비지원 모듈이면 원자 거부** | 모듈을 가진 기존 sim과 상태가 유지되고 성공으로 잘못 표시되지 않는다. 그 모듈을 가진 전투를 재개할 기능은 생기지 않는다. | 공유 owner에 작은 변경. 어떤 비지원 모듈까지 거부할지와 오류 우선순위를 명시해야 한다. 현재 제한 계약의 방어 목적에 적합하다. |
| **B. DecisionBoard를 실제로 복원** | 정상 캡처에서 진행 중 카드의 상태를 보존해 재개할 수 있다. 어떤 카드 유형과 활성 의존성이 지원되는지가 사용자에게 보이는 기능 범위가 된다. | P02의 실제 소유자와 게시·restore 진입점을 먼저 지정하고, D04/O07에서 상태 및 효과 커밋 계약을 승인해야 한다. 현재 제한 입력의 scenario/AI 금지를 완화하는 것만으로는 성립하지 않는다. |

현재 증거로는 **A를 별도 제한 불변식으로 승인할지**를 먼저 결정하는 것이 적절하다. 사용자 결정이 필요한 이유는 A도 기존 공개 호출의 실패 결과를 바꾸며, B는 카드 효과와 재개 기능을 새로 보장하기 때문이다. A에서 정확한 오류 우선순위 및 DecisionBoard 단독과 전체 UNSUPPORTED 중 범위를 승인받는다. B는 정상 제품 복원 기능이 필요한 경우에 한해 지원 카드·의존성·운영 소유자를 별도로 승인받는다. 한 선택의 승인을 다른 선택이나 외부 포맷에 적용하지 않는다.

## A 후보 구현 경계

공유 소유권이 필요한 첫 hunk는 `core/battle/operation_private_state.gd:361–365`의 `restore_completed`에서 `_guard()` 성공 직후, `_busy = true` 및 `prepare(packet)` 전이다. DecisionBoard 단독이면 `_sim.decisions`의 존재만 검사하는 후보가 가장 좁다. 전체 비지원 모듈이 명시 승인될 때만 170–174행의 기존 UNSUPPORTED 순회를 작은 공통 검사로 분리하고 capture의 순서·반환을 보존한다. 클래스 맵, 필드 커버리지 등까지 검사하는 전체 `_bindings()`를 restore에 그대로 부르면 오류 집합과 우선순위가 확대되므로 별도 승인이 필요하다. 생산 테스트 hunk나 호스트/adapter 변경은 A에 포함하지 않는다. 기존 강제 fixture를 기준선으로 쓰고 새 증거는 승인된 전용 경로에 만든다.

오류 우선순위 제안은 기존 `busy` → `unprepared_owner` → 승인된 활성 모듈 오류 → 기존 packet/prepare/context 오류다. 따라서 활성 DecisionBoard와 잘못된 패킷이 동시에 존재하면 새 후보는 `unsupported_active_decisions`를 반환한다. 대안은 기존 packet 오류 우선 후 교체 직전에 활성 모듈을 막는 방식이다. 대안에서는 후보 생성과 정리가 선행하므로 기존 패킷 오류 호환은 좋지만 조기 거부 근거가 약해진다. 복수 활성 모듈의 첫 오류와 테스트 범위도 승인 전 미결이다.

5-a의 명명 기준은 `active_decision_valid_packet_refused_preserving_identity`, `guard_and_packet_error_precedence`, `ordinary_replacement_and_suffix_unchanged`, `scenario_packet_atomic_refusal_unchanged`, `capture_active_refusal_unchanged`다. 활성 사례에서는 기존 sim과 모듈·역참조·marker, tick/clock, pending과 미소비 events, busy/ready 및 후보 바이트를 비교한다. capture가 막힌 fixture에서는 읽기 전용 내부 오라클로 직접 확인한다. 강제 모듈 정리는 fixture가 소유하며 정리 후 제한 공개 후속 진행을 대조한다. 기존 I01b active replacement와 P02의 fresh owner·adapter 회귀를 돌리기 전 코드 SHA 영향을 점검하고 P02 실행과 시간을 분리한다.

## B 후보 설계 경계

먼저 지원 범위 문서에서 `core/battle/decisions.gd:10–22`의 `cards`, `done`, `_seq`, `_crisis_armed`, `_seen_retreat`, 설정 `cfg`·`A`와 `sim` 역참조의 권위를 지정한다. `decisions.gd:118–158`의 resolve는 카드 소비·이력·이벤트와 함대 바이어스 또는 ChainOp 효과를 바꾼다. `battle_sim.gd:91–108,465,976`의 활성화·명령·틱과 `battle_projection.gd:74–75`의 카드 표시를 함께 대조한다. 후보는 fresh 준비 단계에서 typed 상태·ID와 참조, 논리 open/deadline tick, 사용 완료 카드를 검증하고 현재 sim과 분리된 후보에서 다시 묶는 방식이다. restore 자체에서 resolve를 재실행하지 않는 설계를 우선 검토한다. DecisionBoard만 지원할지, morale/AI/ChainOp 등 의존성의 일부를 지원하거나 거부할지, 오류 이름·우선순위, 데이터 표현 및 이전 패킷 호환은 미결이다.

별도 명시 소유권이 필요한 공유 hunk 후보는 `operation_private_state.gd:8–16`의 허용 모듈·코드 지문, 79–89행의 입력 필터, 170–184행의 bindings, 268–333행의 캡처·패킷 검증·fresh 준비, 361–382행과 479행 이후의 이전·해제다. DecisionBoard 상태 읽기/복원 API를 택할 때만 `decisions.gd:10–22,118–158`에 해당 API hunk의 소유권을 요청한다. 카드 응답을 제한 공개 명령에 포함한다면 owner의 `KINDS` 및 189–204행의 명령 검증도 별도 인수다. `operation_runtime_adapter.gd:20–29,72–76`의 입력 규약과 `FleetBattle3D.gd:270–324`의 소유/게시 변경이 필요하면 P02에 양도하거나 작업 창과 hunk를 공동 승인한다. 범위에 따라 승인된 변경 목록을 다시 좁히며, 여기에 적힌 위치가 일괄 편집 권한을 뜻하지 않는다.

5-a의 명명 기준은 `natural_active_owner_and_checkpoint`, `decision_roundtrip_open_pending_done`, `decision_suffix_deadline_player_and_delegate`, `decision_effect_and_event_once`, `candidate_rejection_preserves_live_state`, `unsupported_dependency_and_legacy_packet_regression`이다. 정상 진입을 먼저 입증한다. 선행 강제 fixture에서 시뮬레이터 필드를 대입한 것만으로 첫 기준을 충족할 수 없다. 완전한 상태·카드 투영·결과 및 사건 순서를 무개입 대조군과 비교한다. 운영 게시나 외부 호출이 계약에 들어갈 때는 실제 호스트에서 그 횟수와 게시 전후를 별도 검증한다.

## 조율, 독립 검증과 비대상

두 선택 모두 공유 owner는 P02와 공통 의존성이다. `operation_private_state.gd:16,63–66,298`의 코드 지문과 패킷 검증으로 A의 작은 변경도 기존 내부 패킷의 code_mismatch 및 P02 실행 기준선 갱신을 일으킬 수 있다. 진행 중인 P02의 동결·공통 owner drift 관측을 먼저 확인하고, 소유권·실행 창을 합의한 뒤 HEAD와 대상 hunk 및 P02 공유 입력 SHA를 동결한다. fixture와 패킷 기대값을 조용히 바꾸지 않는다. 일치하지 않으면 구현 전에 중단하고 보고한다.

실행 승인 후 5-a는 시도마다 새 기록을 남기고 실제 exit 0, 진단 및 남은 프로세스 0, 정확한 명명 기준, 승인된 diff와 입력 SHA 대조를 요구한다. 총 시도 상한은 3회다. 5-b는 구현에 참여하지 않은 실제 비-Astra Terra가 사전 승인 계획, diff, 원문 출력, 전후/무개입 대조, 공통 입력 SHA와 P02 간섭 여부를 검토한다. A에서는 복수 실패 조건의 오류 우선순위를, B에서는 정상 호출 경로와 카드 효과가 한 번만 적용되는지를 독립 판정한다. 반려되면 스펙으로 되돌린다.

이 계획에는 제품 변경이나 실행을 포함하지 않는다. 전체 적벽 저장/재개, 외부 저장 스키마와 호환 정책, UI 게시와 글로벌 커서·외부 효과의 전체 원자성은 별도 인수다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
