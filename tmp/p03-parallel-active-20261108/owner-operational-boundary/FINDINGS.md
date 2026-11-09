# 활성 DecisionBoard와 제한 복원의 운영 경계

2026-11-08. 정적 조사 및 기존 증거 대조. 작업자 실제 모델은 로컬 rollout의 09:11:37Z turn_context에서 확인한 gpt-6.1-sol이다. 독립 Terra 판정 전의 잠정 결과다.

## 현재 경로에서 확인한 것

| 경로 | 관측과 근거 |
|---|---|
| 적벽 3D 호스트 | `scripts/FleetBattle3D.gd:270–281`에서 편성을 로드하고, 306행에서 원본 `BattleSim`을 생성하여 324행에서 호스트의 `sim`으로 게시한다. 호스트가 직접 491·534행에서 step을 수행한다. `core/battle/organization.gd:461–465`, `core/battle/scenario_profile.gd:16–33`의 시나리오·AI 입력과 `data/profiles/red_cliffs_rt.json:5`, `data/scenarios/red_cliffs_208_realtime.json:3703`의 카드가 생성 쪽 근거다. `core/battle/battle_sim.gd:91–92,104–108`에서 AI 입력과 시나리오 카드·morale 조건으로 DecisionBoard를 켠다. 기존 독립 closeout은 이 생성자 관측까지만 수용했다. |
| 실제 제품 자동 해결 | `view/world/world_map_screen.gd:601–602`는 resolver의 기존 `start()`를 호출한다. `scripts/world/auto_resolver.gd:35–43,72–88`은 legacy raw sim 경로다. 별도 제한 operation 진입점은 155행이며, 199–215행에서 worker가 adapter로 만든 owner를 자체 소비하고 닫는다. 검색한 현재 제품 호출자는 이 제한 worker 진입점을 사용하지 않는다. |
| 제한 adapter와 replay | `core/battle/operation_runtime_adapter.gd:20–23,72–76`은 checkpoint를 거부하고 제한 owner를 생성한다. `core/battle/operation_replay.gd:72–98`은 adapter로 fresh owner를 만들어 명령 재생 후 닫는다. 현재 검색한 `core, scripts, hud, view, scenes, tests`에서 `restore_completed`의 호출은 테스트에만 있었다. `scripts/FleetBattle3D.gd:650–654`의 `restore_orders`는 명령 undo에 쓰는 `restore` 명령이다. 호출 연결은 `view/fleet_render/battle_source.gd:302–303`와 `hud/ui_kit/order_undo.gd:84`에서 확인된다. |
| 제한 owner 불변식 | `core/battle/operation_private_state.gd:79–89`는 비어 있지 않은 scenario와 AI 입력을 거부한다. 140–160행에서 자체 sim을 만들고 초기 bindings를 검증한다. 170–174행에서 활성 비지원 모듈을 거부하며 capture는 285–288행에서 이를 검사한다. 공개 명령과 step은 206–229행이다. 현재 트리에서 `enable_commander_ai`의 제품 호출은 생성자 하나였다. 정상 공개 경로의 제한 owner에 DecisionBoard가 붙는 정적 연결을 찾지 못했다. |
| 복원에서 드러난 경계 | 같은 파일 361–382행의 `restore_completed`는 기존 owner에 일반 guard를 적용하고, 316–333행의 fresh 후보 준비와 동일 입력 비교 후 sim을 교체한다. 기존 sim의 활성 모듈에 대한 capture의 검사와 달리 restore 직전 활성 모듈 검사 분기가 없다. 기존 sim의 해제는 Salvo/Detection/Supply에 한정된다. 새 후보의 bindings 성공으로 이전 sim의 활성 모듈 보존을 추론할 수 없다. |

위 결론은 현재 조사한 체크아웃의 경로 및 호출자에 한정한 정적 결과다. 제품 호스트가 활성 DecisionBoard를 가진 raw sim을 게시할 코드 근거는 있으나 그 sim을 제한 owner에 넘기거나 공개 복원으로 연결하는 경로는 확인되지 않았다. 외부 호출자나 향후 P02 연결에서 같은 경계가 유지될지는 별도 확인 대상이다.

## 이미 검증된 서로 다른 세 사례

- **강제 주입 후 정상 패킷.** `tmp/p03-active-unsupported-20261108/active_unsupported.gd:91–135`가 기존 제한 sim에 정본 DecisionBoard를 직접 붙이고 marker 47로 식별했다. capture는 `unsupported_active_decisions`였으나 유효한 같은 C0 패킷의 restore는 성공했다. 새 sim의 모듈이 없었고 이전 객체에는 남았다. fixture가 이전 순환 참조를 정리했다. 기존 RESULT 및 REVIEW-CLOSEOUT의 분류는 ACCEPTED_DROPS_ACTIVE_MODULE이며 자연 도달과 운영 계약은 열린 상태다.
- **정본 생성과 제한 생성 거부.** `../WORKER-HANDOFF.md` 및 `../REVIEW-CLOSEOUT.md`는 표준 자동 편성으로 활성 카드 모듈을 직접 생성한 관측과 scenario를 변이한 제한 adapter 입력의 생성 거부를 각각 수용했다. 적벽 전체 프로필을 adapter에 넣었을 때의 최초 오류로 확대할 근거는 없다.
- **정상 제한 owner와 비지원 패킷.** `../owner-contract/cycle-02/REVIEW-CLOSEOUT.md`는 공개 복원에 넘긴 scenario 패킷의 거부와 기존 identity/tick/queue/events/busy 보존 및 후속 정상 진행을 수용했다. 기존 owner에 DecisionBoard를 붙인 사례와 입력·오류 계층이 다르다.

## 소유권과 후속 권고

P02의 UI host·worker·replay 소비자 연결과 게시·준비 실패 계약은 P02 인계의 소유다. `docs/battle-core/pc-campaign-design/SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md:40`는 UI에서 sim뿐 아니라 clock/G/vm/선택/trace의 candidate commit을 요구한다. `tmp/p02-seventh-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md`의 제한 수용은 입력·준비 실패·보존 증거이며 전체 operation은 NOT_READY다. P03 제품 경계의 `tmp/p03-product-resume-20261108/CLOSEOUT.md`도 표준 호스트 capture 호출과 저장 생산 경로의 연결을 미확인으로 남겼다. `tmp/p03-parallel-state-20261108/clock-rng/HANDOFF.md`, `reinf-ms/HANDOFF.md`, `HANDOFF-READONLY.md`는 논리 시계/RNG·증원·읽기 전용 선언의 별도 경계이며 활성 카드 복원 또는 호스트 게시를 검증하지 않는다.

다음 조각으로 **P02 호스트 연결 설계의 진입 조건과 P03 지원 범위 교차 검토**를 권고한다. P02가 실제 소유자, 공개 복원 진입점, 기존 raw sim을 처리하는 방법과 첫 게시 시점을 지정하고, D04/O07이 비지원 활성 모듈의 실패 정책 소유 여부를 확인하는 작은 문서 인수다. 기존 강제 fixture와 scenario 패킷 검사는 재실행할 필요가 없다. 현재 제한 계약의 보수적 후보는 기존 owner에 활성 비지원 모듈이 있다면 후보 준비·교체 전에 거부하는 것이다. capture의 `unsupported_active_decisions`는 오류 의미의 선례이며, 이미 만들어진 제한 owner에 임의로 모듈을 붙일 권한이나 운영 restore 오류 우선순위를 결정하지 않는다. 기존 제한 I01b 인계는 underscore reflection과 raw sim 입양을 보장 범위 밖으로 둔다. 따라서 방어 검사 자체를 제품 장애 수정이나 호환 정책으로 분류하려면 별도 승인과 계약이 필요하다. [I01b 인계](../../../docs/battle-core/pc-campaign-design/SESSION-HANDOFF-I01B-ACTIVE-REPLACE-20261104.md), [D04 상태 계약](../../../docs/battle-core/pc-campaign-design/D04-STATE.md)

실제 호스트 연결이 지정된 뒤의 차별화된 재현은 정상 진입으로 활성 DecisionBoard를 확보하고 같은 운영 복원 요청에서 기존 owner/sim, 모듈 identity·marker, tick/queue/events 및 게시·외부 호출을 전후 대조하는 것이다. 미지원으로 정책이 승인되면 거부 후 정상 호스트 후속 진행을 무개입 대조군과 비교한다. 지원으로 정책이 승인되면 모듈의 카드 진행, 제출·소비 경계, 중복 외부 효과의 별도 오라클이 필요하다. 정상 호출 연결을 확보하기 전에는 강제 주입 결과를 제품 도달 증거로 사용하지 않는다.

이번 조각은 정적 조사와 증거 정리에 한정한다. 운영 restore 정책, 오류 우선순위와 외부 저장 스키마는 미확정이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
