# P03 다음 후보 — 종료 하위걸음 체크포인트

2026-11-08 KST. **독립 계획 심사 대기. 코드·Godot 미착수, 새 K6=0.** 선행 [전체 작업표](../p03-command-suffix-20261107/P03-CHECKLIST-20261108.md)의 B0/C0/Cn·시계/종료 경계 항목을 좁힌다. Sol 실행 / Terra 독립 심사의 명시 배정, Astra 제외.

## 이유와 범위

기존 `tests/i01b_logical_clock.gd`는 BattleSim subclass의 주입 종료로 tick2/clock150과 pause/배속을 검증한다. 기존 P2c/활성교체는 제한 상태/사건/공격의 실제 복원이다. 선행 suffix는 진행 중 같은 틱의 명령·대기 절단점을 검증했다. 이번 후보는 제한 private owner에서 **실제 코어 종료 분기가 첫 하위걸음에서 끝낸 terminal 상태**를 복원하고, 그 직전 packet에서 같은 단일 step을 다시 실행한다. 코어의 종료 조건을 호출하는 코드를 복제하거나 서브클래스로 갈아끼우지 않는다. 제품 플레이 또는 일반 운영 Cn을 인수하는 조각이 아니다.

쓰기는 `tmp/p03-terminal-boundary-20261108/`의 신규 전용 증거와 테스트만 허용한다. P02 공유 core/adapter/host/worker/replay/체크리스트와 선행 P03 기록은 읽기 전용이다. P02 최신 읽기 관측은 제품 자동결산의 결과 변환 분리 후보이며 이 실험은 `BattleOutcome` 또는 공개 replay·viewer drain을 호출하지 않는다. 공유 `OperationPrivateState`는 P02 viewer-events의 새 바이트 `c5550999…9a6e`를 현 시점에 관측했다. 선행 suffix의 `dd47ceeb…a427`는 역사 실행이다. 구현 전 현 branch/HEAD/index와 새 dirty 전수 분모를 기록하고 임의로 소스를 되돌리지 않는다.

## 제한 fixture와 독립 오라클

동일 제한 POC 입력 seed7/hz10/명시 direct 2개, ally 기함 하나/foe 기함 하나, reinf=[]와 멀리 배치, 활성 지원 밖 모듈 없음. 별도 raw BattleSim은 처음부터 동일 입력과 controls를 직접 넣되 packet/prepare/restore를 호출하지 않는다. 양쪽 한 step으로 tick1/clock100, over=false를 수기 확인한다. 이 경계에서 테스트 전용 기존 `debug_damage`에 foe의 현재 정수 밀리척 수보다 충분히 큰 유한 피해를 양쪽에 한 번만 넣어 마지막 적을 격침한다. 사용자는 정상 플레이로 이 피해를 가한 것이 아니다. 피해 수치는 첫 양쪽 관측에서 대칭으로 확인하고, 이 조작 뒤의 over=false, foe alive 0, ally flag 생존, tick1/clock100을 필수 검사한다. 별도 tick이나 종료 flag를 쓰거나 `debug_end`를 호출하지 않는다. 손상 사건은 양쪽 drain으로 먼저 소비한다.

이 상태에서 owner의 pre-terminal packet을 capture하고 실제 `advance()`를 한 번 호출한다. `battle_sim.gd:923–989,1215`의 첫 하위걸음에서 적 생존 조건으로 종료하면 tick2/clock150/end_tick2/end_ms150, sub_ms50, dt=0.1, over/win=true, reason=annihilation이 된다. 수기 기대값과 raw twin의 script-property 상태, 실제 사건 순서·타입을 대조한다. terminal packet은 battle_end를 drain하기 전에 capture한다. 단일 battle_end의 tick/reason/pos/value를 수기 대조한다.

실제 진행한 owner를 pre-terminal packet으로 되돌리고 같은 **advance 한 번만** 실행한다. damage를 다시 호출하지 않는다. 첫 전진의 terminal 상태·사건·실제 time/sub_ms를 exact 비교한다. 그 다음 미소비 terminal packet을 동일 handle로 복원해 즉시 관측/drain, 순서가 같은 단일 battle_end와 직후 빈 drain을 비교한다. 미소비 packet의 사건 재생을 외부 dedup/ack로 해석하지 않는다. terminal 이후의 owner advance를 제품 정상 호출로 규정하지 않는다. `_tick`의 기존 post-terminal tick 증가 가능성은 읽기 관측이며 새 정책은 별도다.

## 사전등록 5-a

| 이름 | 성공 조건 |
|---|---|
| terminal_01_pre_boundary_actual | 틱1/100 및 실제 controlled damage·격침/over=false, raw와 exact, pre-terminal capture |
| terminal_02_natural_core_partial_end | 실제 owner/raw step에서 2/150, end2/150, sub50/dt0.1·annihilation, end 사건 정확히 한 개. clock을 tick×100으로 환산하면 실제 기대와 다름 |
| terminal_03_restore_pre_and_repeat | 실제 종료된 active를 pre-terminal로 되돌리고 같은 advance만, checkpoint exact 및 terminal 상태·사건 exact. damage 재주입 없음 |
| terminal_04_restore_terminal_and_drain | terminal packet의 동일 handle/new sim, exact 시계/상태, drain 한 번 및 즉시 빈 재호출, packet 불변 |

각 단계의 raw comparator는 production allowlist와 독립된 실제 script property를 사용하고 Variant type/value, Dictionary 키 타입·삽입순서, Array 순서와 typed metadata/script identity, sim/state/fleet bindings를 검사한다. id cache를 값 비교에서 제외하면 실제 ID 참조 검사를 별도 둔다. 4개 명명, 1개 seed/fixture와 실제 assertion 수를 분리한다. 지원 밖 모듈과 비어 있지 않은 typed class/script 컨테이너, UI/host clock/worker, 외부 저장/글로벌 cursor와 terminal 이후 정책은 미검증이다.

선행 suffix에서 검증된 엔진 gate를 근거로 전용 새 경로에서 console과 실제 본체 SHA·runtime PID/경로, 정본 global class cache/실제 Script canonical 경로·identity, project·runner·전체 battle 전이 소스/입력 SHA와 입력 전후 일치, explicit timeout/Job 회수를 동결한다. 선행 실패를 덮거나 이전 runner를 수정하지 않는다. 새 명명 실행 actual exit0, 오류/경고/누수0, 제한 4개 명명 완결, 입력 불변을 요구한다. 실패는 각 로그와 실제 exit를 보존, K6 안에서만 보완, 계획/오라클 변경 시 독립 재심, 사용량 제한 즉시 보고·반복 금지. 독립 계획 수용 뒤에만 구현한다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
