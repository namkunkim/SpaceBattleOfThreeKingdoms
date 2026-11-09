# P03 명령·커서·운영 경계 읽기 감사

2026-11-05 KST. 읽기 조사 담당 `/root/command_audit`. 소유 파일은 이 문서 하나다. 코드·공유 체크리스트·P02 경로는 변경하지 않았다. 워크플로우-플레이북.md, CLAUDE.md, SESSION-HANDOFF.md의 시작/역할 절을 확인했다. 부모 경로 C:/AGENTS.md, C:/WorkSpace/AGENTS.md, 저장소 루트 및 core/tests/docs 아래 AGENTS.md 검색에서 적용 파일을 찾지 못했다. 실행 검증이나 독립 판정 문서가 아니다.

## 정본 계약과 실제 구현의 차이

| 계약 | 원문 근거 | 현재 해석 |
|---|---|---|
| 저장 방향 | docs/battle-core/pc-campaign-design/H2-DECISION.md:13,27 | 현재 상태+후속 명령·동일 규칙 버전 방향만 채택. 필드·커서·원자 커밋·호환 판정 전체 승인은 아님 |
| 상태 책임 | docs/battle-core/pc-campaign-design/D04-STATE.md:49~66,76~80,96~102 | ST01~18은 소유/수명/보존 요구. commit/원장/저장 표현은 O07 미해소. 실제 클래스 구현으로 취급 금지 |
| 순서 | docs/battle-core/pc-campaign-design/I01-READINESS-DECISION-20261026.md:19 | K05 신규 seq1부터·적용커서0 권고. legacy 로그에 해당 seq가 구현됐다는 뜻 아님 |
| C0 | 같은 파일:20,32~46 | K06 첫 issue/queue/step 전, 모듈 초기화·직접/위임 배정·첫 투영 준비 완료. S01~15 필드 계약이며 전체 모듈 사전 아님 |
| Cn | 같은 파일:21,48~50 | K07 step 반환 후 양자화/효과 완료 또는 step 밖 issue의 적용·로그·이벤트 완료. commit_seq는 권고이며 운영 snapshot 전체 인수 전 NOT_READY |
| 운영 반례 | docs/battle-core/pc-campaign-design/I01-ACCEPTANCE-PREREG-20261026.md:67,83 | seq1/2 반영·seq3 대기/후속의 한 번 적용, 참조/필수/ID/호환 거부와 활성 불변. 실제 신규 커서 계약 구현 완료로 승격 금지 |
| B0 | docs/battle-core/pc-campaign-design/I01B-P2A-RESULT-20261028.md:11 | 생성자 반환 직후, 첫 issue/queue/step/projection 및 호스트 control 배정 전. C0와 다름 |

K01~04/K08은 같은 readiness 원문:15~24에서 입력 opt-in/변환/정규형/해시/지원 거부를 규정한다. 특히 문서 K03 object 키 정규화 권고를 현재 private replacement의 exact context에 소급해 완화하면 안 된다. `operation_private_state.gd:308~321`은 Variant 타입, Dictionary 키 타입·삽입순서, Array 순서·typed builtin/class/script identity까지 비교한다.

## 명령 lifecycle

| 구간 | 실제 경로:줄 | 의미와 한계 |
|---|---|---|
| 구조 수용/거부 | core/battle/operation_private_state.gd:189~204,212~221 | 정확한 키/타입/중복 ids/subset/args 검사. 실패는 core 호출 전 반환. 성공 `{ok:true}`는 wrapper 호출 완료이고 게임 논리 성공 통지가 아님 |
| enqueue | core/battle/battle_sim.gd:95~96 | `_queue.append(cmd)`만 실행. core 직접 호출은 alias를 보유한다. private owner는 216에서 deep copy해 이 입력 alias를 차단한다. 아직 로그/게임 적용 없음 |
| 즉시 적용 | core/battle/battle_sim.gd:142~146 | deep copy→`tick=st.tick` 덮기→로그 append→`_apply_human`. 입력 tick은 예약시각이 아님 |
| 대기 적용 | core/battle/battle_sim.gd:172~180 | 현재 queue 배열을 떼고 새 빈 queue를 게시한 뒤 원래 배열순서로 복제·현재 tick 기록·로그 append·적용. 이후 `_tick()` |
| 논리 거부 | core/battle/battle_sim.gd:149~169,460~479,509~527 | `rejected` 사건이 가능하고 로그에는 이미 기록됨. 일반 명령은 검증 전 direct 전환 가능. formation은 일부 함대 성공도 가능. 따라서 rejected를 전체 무변이 또는 로그 미기록으로 해석 금지 |
| 실행 완료 | core/battle/battle_sim.gd:509~527,1174,1196 | 명령 적용은 진형 전환·이동·투사체 효과 완료와 다름. 완료는 후속 틱/module/timer 소비의 책임 |
| 사건 생성 | core/battle/battle_sim.gd:214~215 | `{tick,kind,sq,other,pos,value}` append. 공통 seq/고유 event ID가 붙지 않음 |
| 외부 drain | core/battle/battle_sim.gd:98~101,424~448; operation_private_state.gd:231~237 | 전체 사건 배열을 분리하고 빈 배열로 교체. `drain_events_for`도 먼저 전체 소비 후 투영 필터. owner는 반환을 deep copy. 외부 효과 처리 성공/커밋 ack/dedup 기록이 아님 |

`BattleState.next_id`는 함대 생성 ID(`battle_sim.gd:220~221`), `next_event_id`는 투사체 ID 공간(`operation_private_state.gd:405~406`)이다. 이를 명령 적용커서나 모든 사건의 순번으로 쓰면 안 된다. `command_log`의 순서는 append 순서이고 tick은 적용 시 현재 외부 틱이다. core/private owner에 command_seq/last_applied_seq/commit_seq가 실제 필드로 없다. `operation_profile.gd:73`의 cursor 메타데이터는 설정 값이며 실행 원장이 아니다.

## 시계와 capture 경계

`battle_sim.gd:923~947`에서 tick 먼저 증가, dt를 하위걸음으로 나눠 `sub_ms` 설정, 종료면 나머지 하위걸음 중단, dt 복구 후 좌표/방향 양자화한다. `949~989`에서 clock_ms 증가→증원→AI→함대→활성 module→간격→미사일→함재기→승패 순이다. 따라서 tick×100으로 clock을 복구할 수 없고 종료한 하위걸음의 실제 clock을 보존해야 한다. raw core에는 step 중 capture 안전성/락이 없다.

private owner `create:142~163`은 복제 입력으로 초기화·controls 배정·binding 확인·projection 후 ready 게시한다. `_guard:165~168`은 busy 또는 미준비를 거부하며 issue/queue/advance/drain은 동기 호출 동안 busy를 둔다. `capture_completed:256~264`는 guard/binding/observe 후 packet을 복제한다. 이것은 해당 owner의 완료 호출 사이 경계이며 다른 스레드/await/callback 원자성 증명이 아니다.

`TickClock`의 hz/speed/acc/dropped(`core/battle/tick_clock.gd:11~29`)는 별도 소유다. speed0이면 accumulator 소비 없이 반환, 최대8tick 초과분은 dropped로 간다. private packet에는 이 host 시계가 없다. raw sim 교체만으로 pause/speed/acc/ready/UI 완료를 주장할 수 없다.

`restore_completed:325~346`은 guard→busy→별도 prepare→exact context 비교→sim 포인터 교체→retired module.sim 해제→busy 해제다. prepare/맥락 실패는 현재 sim을 교체하지 않는다. 이는 기존 owner 내부 교체의 수용 범위이며 host 표시·외부 사건 효과의 원자성까지 확장하지 않는다.

## suffix 반례와 필요한 oracle

아래는 조사로 도출한 후속 인수 후보이며 모두 실행됐다는 뜻은 아니다.

1. 같은 tick에 issue A→capture→issue B. tick 기준 `>` suffix는 B를 잃고 `>=`는 A를 재적용한다. tick만으로 절단점을 정할 수 없다.
2. queue A→issue B→capture. 로그에는 B, pending에는 A. 입력 접수순서와 실제 적용순서가 다르므로 log 길이를 전체 수용 cursor로 쓰면 틀린다.
3. 같은 명령을 두 번 queue. ids 중복 검사는 명령 내부만 검사한다. 두 호출은 두 로그/적용이므로 내용 hash dedup을 발명하면 합법적 반복 입력을 지운다.
4. queue A→capture→실제 advance/drain→restore→동일 suffix advance. pending A는 packet에서 한 번 소비돼야 하고 외부 suffix에 A를 다시 넣으면 중복이다. 현재 packet log/queue 보존과 외부 envelope의 대응 책임은 별도 미정이다.
5. 구조적으로 유효한 no_selection/지원 명령의 논리 거부. wrapper ok/log 기록/rejected 사건을 각각 비교한다. rejected만 보고 접수 실패·전체 상태 불변으로 단정하지 않는다.
6. 빈 queue step 전후, 같은 tick 다중 issue, 종료 하위걸음 전후를 각 관측한다. 종료 뒤 advance도 raw `_tick`이 tick을 먼저 증가하므로 상위 실행 종료 조건을 별도 확인해야 한다.
7. packet 미소비 사건→capture 후 drain→restore→drain은 같은 사건을 다시 준다. 이미 소비한 packet에서는 비어 있어야 한다. 외부 효과 전역 exactly-once 검사가 아니다.
8. malformed/context/busy 거부 전후 active state·pending·events·packet bytes/type metadata·busy를 비교하고 다음 정상 호출이 가능한지 확인한다.

기존 `tests/i01b_active_replace.gd:146~196`은 pending+이벤트 capture→실제 전진→복원, 반복복원, 미소비/기소비 사건, pending 한 번 소비, 후속 exact state/ordered events, 보급·탐지·투사체 후속을 이미 다룬다. 새 검사는 이 수용 증거를 지우거나 전체 global cursor 지원으로 바꾸지 말고, 새로운 계약 구분/누락 감지에 초점을 맞춰야 한다.

## P02 인수 요구와 소유 구분

| P03 요구 | P02 또는 후속 의존 책임 |
|---|---|
| capture는 완료된 owner 호출 사이에서만. step중/미준비/busy는 무변이 거부 | 실제 host/headless/replay 소비자의 호출 순서/opt-in 연결 및 표시 상태 |
| command 수용·pending·논리적용·효과완료를 구분 | 사용자 입력 성공 표시를 wrapper ok와 혼동하지 않는 adapter 통지. 신규 통지 API는 공동 소유권 합의 후 |
| log/pending/event 순서를 보존하고 외부 suffix의 절단점 미정 유지 | 실제 replay/host 저장 입력 경계. legacy tick 로그를 신규 seq 원장으로 승격 금지 |
| ready/busy 완료 후 게시. 실패는 기존 active runtime 유지 | host clock/selection/progress/worker 결과/표시 보존. sim 포인터 교체만으로 host 완료라고 하지 않음 |
| packet 시점 사건은 보존, 외부 소비 효과는 보장 밖 | drain 책임과 알림/게임효과/결과 게시의 소비 ack 정책은 후속 계약 |
| controls=[]와 explicit delegate 및 typed context 차이 유지 | P02 입력 선택/정책 whitelist가 private 전체 관측을 공개정보로 노출하지 않아야 함 |

현재 global command cursor/commit 번호/효과 idempotency key/외부 저장 스키마는 **미정**이다. 본 조사는 새 정책을 확정하지 않는다. 전체 I01/I01b/A04~A06는 NOT_READY, 외부 save schema는 UNCLASSIFIED를 유지한다.
