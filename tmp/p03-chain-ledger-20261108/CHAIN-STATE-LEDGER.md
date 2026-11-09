# P03 ChainOp 상태 책임 원장

2026-11-08 KST. 읽기 조사. 제한 owner는 활성 chain을 거부한다(operation_private_state.gd:8,170–174). 아래 capture·재구성·재결합은 후속 후보이며 현재 지원이 아니다. 소스 경로는 core/battle 기준이다. [동결 입력](input-manifest.json) · [계획](PLAN.md)

| 선언 | 타입·초기·갱신·소비 | 향후 복원 후보 |
|---|---|---|
| F01 sim | BattleSim 참조, stratagem.gd:15,37–38. 168–206,229–250,280–307에서 상태·피해·이벤트·시간 접근 | 새 sim에 재결합 |
| F02 O | Dictionary, :16,40의 RuleSet chain_operation. :42–43,72–97,111–165,385–415에서 자산·의심·번짐 정책 소비 | 동일 실효 규칙 재구성, 값/참조 별도 확인 |
| F03 X | Dictionary, :17,39의 combat.stratagem. :65–66,100–101,148–155,201–205,229–250에서 진형·풍향·센서·지형·반격 소비 | 새 SalvoCombat 설정에 재결합. battle_sim.gd:82–86 및 commander_ai.gd:74,330 |
| F04 host_sq | String 편성 ID, :18,41,50–54에서 side0 roster 조회. :111–155의 명령과 battle_sim.gd:1132 소비 | 프로필에서 재구성 및 편성→runtime ID 검증 |
| F05 charges | int, :19,42,186,288,364 초기·차감·종료. :113–155,488–499 조건/투영 | 현재 값 capture. 초기화하면 자산 복제 |
| F06 letters | int, :20,43,114–118의 조건·차감, :488–499 side0 투영 | 현재 값 capture |
| F07 mode | String idle/feign/open/done. :21,118,132,187,288–292,365 전이. :86–94,137–155,423–480 휴전/명령/AI | 현재 값 capture. 모드 일치만으로 타이머 일치를 추론할 수 없음 |
| F08 susp_m | int 의심×1000, 음수 가능. :22,119–122,326–336 초기·틱·피격 가산. :56–57,86–97,344–359 소비 | 부호 있는 값 capture. 공개 0 하한값에서 역산 금지 |
| F09 warned | Dictionary, :23,123,344–359의 실제 임계 key→true, 중복 경고/카드 발생 방지 | key 타입·삽입순서와 값 capture |
| F10 win_off | int tick, :24,44–47의 profile RNG·hz·풍향창 범위. :282–284가 first_hit_tick 뒤 사용 | 같은 규칙/난수로 재계산 후보, 실제 값 검증 |
| F11 win_start | int tick/-1, :25,282–285 first_hit_tick+win_off. :59–60,488–499 판정/공개 | 현재 값 capture 또는 원 입력과 재계산 비교 |
| F12 win_end | int tick/-1, :26,284 duration 추가. :59–63,286–289,488–499 소비 | 현재 값 capture. 창 시작 포함·끝 제외 |
| F13 _win_state | String 직전 공개 전이. :27,286–289에서 open/closed 반복 발행 억제 | 현재 값 capture. 현재 tick 상태로 재구성하면 이전 발행 여부가 사라질 수 있음 |
| F14 fires | typed Array[Dictionary], :28,176–200,293–295,385–420 추가/전파/종료. :103–109,499–502 읽기 | 순서·종료 항목과 내부 record capture, fleet ID 재결합 |
| F15 _revert | Array, :29,201–205 긴급 분산 복귀 예약, :296–301 만료 삭제·복귀 | tick/대상/진형 ID와 순서 capture, 참조 재검증 |
| F16 _hazards | Array, :30,239–249,302–305의 terrain 만료 목록 | zone ID/시간·순서와 terrain.zones를 함께 capture |
| F17 _zone_seq | int, :31,240–243에서 증가 후 TRN-ZFIRE 구역 이름 생성 | 현재 값 capture. 현재 zone 수로 역산 금지 |
| F18 sensor_until | int tick/-1, :32,100–101,238에서 화공 시 갱신. detection.gd:85–96의 side1 센서 | 만료 tick capture, 효과 소비 phase를 별도 검증 |
| F19 card_id | int 카드 ID/-1, :33,269–278,350–358,380–383에서 생성·응답·간파 폐기 | DecisionBoard cards/_seq와 함께 capture, 카드 ID/ref 참조 검증 |
| F20 stats | Dictionary, :34–35,124,181–185,210,366,413 갱신, tests/stratagem_rules.gd:172–195,272–304 소비 | 관측 통계 범위 별도 인수, 필요 시 값/타입/순서 capture |

## 동적 record와 참조

| 묶음 | 실제 형태와 실행 순서 | 다음 검증 |
|---|---|---|
| D01 warned | 경고 threshold 원소를 Variant key로 사용, 값 bool true. letter:123 초기화, _warn:344–359에서 설정 Array 순으로 추가. 이벤트 level은 int로 변환 | key를 임의 숫자 정규화하면 has 검사와 정확 비교가 달라질 수 있음 |
| D02 fires | 생성 순서 host,next,last,power,n,burned,counter. host/last는 int fleet ID, next tick/-1, power float, n int, burned int ID→true, counter String. :168–211,252–260,385–420 | append 순서대로 step. burned는 재선택 방지, counter는 다음 반격 조건. 완료 항목도 남음 |
| D03 _revert | [만료 int tick, int fleet ID, String 기존 진형 ID]. :201–205에서 보존 후 분산, :296–301에서 제거 후 남은 대상 복귀 | 같은 tick 원순서, 대상 탈락과 진형 참조를 별도 대조 |
| D04 _hazards | [만료 int tick, String zone ID]. :239–249에서 zones의 id/type/name/rect/move_cost_bp/sensor_bp/conceal/range_bp/arc_deg 추가 및 ID 정렬, 예약은 append. :302–305는 만료 ID 제거 | zone record와 예약, _zone_seq를 함께 비교 |
| D05 stats | 9 key. float letter_t/ignite_t/ignite_power/susp_at_ignite, bool feigned, int detected/spreads/fires, 순서 있는 String ID Array counters. 생성과 갱신은 F20 참조 | 센티널 및 clock_s의 의미, stats.fires 누계와 fires 목록 분리 |

host_sq는 편성 ID다. fires와 _revert는 runtime fleet ID를 사용하고 zone은 _zone_seq에서 이름을 발급한다. card_id는 DecisionBoard._seq에서 발급하며 card.ref는 fleet ID다(decisions.gd:13–15,68–85,136–140). 피해 호출의 st.new_event_id()는 BattleState.next_event_id에서 나오며 사건 DTO 자체에 공통 ID로 들어가지 않는다(stratagem.gd:229–250, battle_state.gd:101–103, battle_sim.gd:214–215).

첫 하위걸음은 detect→salvo→morale→chain→supply→decisions 순서다(battle_sim.gd:963–977). chain 내부는 풍향창/상태→의심→fires 전파→진형 만료→지형 만료다(stratagem.gd:280–305). 직접 명령과 salvo.gd:696 피격 콜백은 chain.step 전에도 효과를 만들 수 있다. battle_projection.gd:86–87,135–136은 모드/의심/창과 조건부 정보를 제공한다. stratagem.gd:501–502의 지문은 mode/charges/letters/susp_m/win_start/sensor_until/fires.size만 포함한다. burned/counter, 예약 및 통계의 동등성은 별도로 비교해야 한다.

1. **다음 번짐.** burned/counter 또는 fires 순서를 잃었을 때 동일 step의 표적·손상·이벤트가 달라지는지 검증한다. tests/stratagem_rules.gd:172–195는 counter 효과를 검사하며 packet/suffix 반례는 미실행이다.
2. **지형 만료.** zone/예약 ID 불일치 및 _zone_seq 손실이 다른 구역 삭제나 다음 이름 충돌로 이어지는지 따로 검증한다. 현재 센서/사거리의 이후 결과까지 비교해야 한다.
3. **결정·복귀·센서.** 카드 resolve/drop, _revert, sensor_until의 직전/직후에서 상태 및 pending/output 중복과 유실을 검사한다. timer 기본값이나 event drain은 외부 처리 완료 근거가 아니다.

ChainOp 활성 복원과 정책 수치·동틱 전역 순서는 미결이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. 코드·Godot 변경 없음. [D04 상태](../../docs/battle-core/pc-campaign-design/D04-STATE.md) · [D08 사건](../../docs/battle-core/pc-campaign-design/D08-EVENTS.md)
