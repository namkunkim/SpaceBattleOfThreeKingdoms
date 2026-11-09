# P03 DecisionBoard 상태 책임 원장

2026-11-08 KST. 읽기 조사. 활성 decisions는 제한 private owner가 거부한다(operation_private_state.gd:8,170–174). 아래 복원 분류는 후보이며 구현 인수 범위가 아니다. 소스 경로는 core/battle 기준이다. [계획](PLAN.md) · [동결 입력](input-manifest.json)

| 선언 | 실제 타입·초기·갱신·소비 | 복원 책임 후보 |
|---|---|---|
| F01 sim | BattleSim 참조, decisions.gd:10,19–20. :24,29–63,68–84,87–151에서 tick/모듈·명령/이벤트 소비 | 새 owner sim에 재결합. 기존 객체를 capture하지 않음 |
| F02 cfg | Dictionary realtime_rules.decision_cards, :11,19–21. :64–66의 open 기본 시간과 stratagem.gd:352의 의심 카드 한도 | 같은 실효 규칙에서 재구성 및 참조 검증 |
| F03 A | Dictionary ai.decisions, :12,19–22 및 battle_sim.gd:104–110 생성. :95–108,142–151의 재무장/권고/효과 | 동일 AI 설정과 참조 재구성. 현재 효과/clock은 별도 |
| F04 cards | typed Array[Dictionary], :13,29–50,53–62,68–85,111–134. 생성 순서의 예고·활성·폐기·응답 대기 | 정확 record/순서·타이머/announcement/참조 capture |
| F05 done | typed Array[Dictionary], :14,131. 성공 resolve의 처리 이력. drop 경로에는 append 없음(:81–85) | 관측/통계 계약에 맞춰 별도 capture. 전역 효과 완료/외부 ack로 쓰지 않음 |
| F06 _seq | int 초기 1, :15,71–74에서 카드 ID 발급·증가 | 실제 카운터 capture. active cards/done 수나 command seq에서 역산 금지 |
| F07 _crisis_armed | bool 초기 true, :16,87–97에서 군 사기 임계 하락 후 비활성·gap 이상 회복 후 재무장 | hysteresis 현재 값 capture. 같은 현재 사기만으로 재구성 불가 |
| F08 _seen_retreat | Dictionary, :17,99–108의 int fleet ID→true. 이미 보인 퇴각 재발행을 억제 | key 타입·삽입순서·값 capture 및 fleet ID 참조 검증 |

| 동적 묶음 | 현재 record 및 의미 |
|---|---|
| D01 cards | decisions.gd:68–79 생성 순서 id:int, kind:String, ref:int, open_tick:int, deadline_tick:int, options:Array, rec:String, time_total:float. announced:bool은 즉시 공개 또는 step 공개 때 마지막에 추가(:53–62). options는 id record 목록이며 대기 표시에서 deep-copy(:29–36). morale_crisis ref=-1, pursuit는 적 fleet ID, suspicion_80은 ChainOp host fleet ID(:93–108, stratagem.gd:356). ref는 카드 ID와 다르다 |
| D02 done | decisions.gd:131, id/kind/open_tick/tick/option/by 순서. by는 현재 player/delegate 호출 경로로 들어간다. drop은 by=expired/option 빈값 사건을 내도 done은 쓰지 않는다(:81–85). payload 값이 실제 타격 또는 외부 지급의 성공을 뜻하지 않는다 |
| D03 _seen_retreat | decisions.gd:99–108, 확인된 적의 퇴각에 대해 fleet 순서로 ID를 기록한다. 미확인/사망/이탈 또는 이미 본 대상은 건너뛴다. 배열 위치나 display 목록의 개수로 대체하지 않음 |

## 접수·완료 및 tick 책임

open_tick은 현재 tick+precursor, deadline_tick은 open+유지 시간의 tick 값이다. :24–25,68–79. pending/upcoming은 논리 tick을 읽어 초 단위로 투영하며 side0 공개 호출이 이를 소비한다(battle_projection.gd:73–75). 지문은 active id/kind/open/deadline 요약으로 옵션/announced/done/counter 상태를 비교하지 않는다(decisions.gd:46–50).

실제 응답 경로는 legacy BattleSim의 decide 명령이다(battle_sim.gd:142–146,460–469). open 이전, 존재하지 않는 카드, 잘못된 option은 resolve에서 거부하고, 정상 응답은 erase→효과 적용→done append→decision_resolved 발행 순서다(decisions.gd:118–134). :118–134에는 deadline 이후를 직접 거부하는 조건이 없고, 만료 위임은 step이 tick≥deadline인 활성 card에 권고안을 resolve해 수행한다(:53–62). 그렇다고 정상 host가 기한 뒤에도 응답할 수 있다는 실험 결과는 아니다. 같은 tick의 도달 가능성과 호출 순서를 별도 반례로 검증해야 한다. BattleSim은 step 시작의 queue를 현재 tick에 먼저 적용한 후 바깥 tick을 증가시키고 첫 하위걸음의 decisions를 평가한다(battle_sim.gd:172–180,923–977). chain.step은 decisions.step보다 앞이다.

resolve의 효과는 crisis/pursuit에서 위임 함대의 bias_mod/bias_until, 조건부 pursue_id/pursue_until에 기록된다(decisions.gd:136–151). suspicion_80은 ChainOp에 옵션을 넘긴다. ChainOp의 card_resolve는 card_id를 지우고 조건에 따라 실제 ignite/withdraw를 시도한다(stratagem.gd:269–278). DecisionBoard 완료 기록만으로 이 후속 동작의 모든 효과가 성공했다고 볼 수 없다. 간파의 drop은 카드만 닫고 사건을 내며 이전 효과를 되돌리지 않는다(stratagem.gd:380–383, decisions.gd:81–85). 외부 ack/게시/transaction ID는 별도다.

1. **기한 경계의 실제 순서.** 동일 nominal tick의 즉시 issue, 이전 바깥 tick에 대기한 decide, 첫 하위걸음 자동 delegate의 effect/done/event를 각각 비교한다. 정상 호출로 기한 시점 상태에 도달하는지부터 확인한다. 스펙 우선순위를 여기서 정하지 않는다.
2. **폐기와 처리의 차이.** suspicion_80 카드가 active일 때 ChainOp 간파의 drop과 정상 resolve를 비교한다. ref/카드 ID, 사라진 카드, done, effect, ordered 사건이 다를 수 있다. 전역 cursor를 하나의 resolved 이벤트로 대체하지 않는다.
3. **이력 초기화의 재발행.** 동일 사기와 퇴각 접촉의 후보에서 _crisis_armed 또는 _seen_retreat만 초기화한 다음 step은 같은 대상/상황의 카드를 새 ID로 다시 열 수 있다. 이 반례와 운영 snapshot 왕복은 미실행이다.

ST07/ST18의 효과/예약·커밋·외부 소비 책임을 좁혀 조사했다. [D04](../../docs/battle-core/pc-campaign-design/D04-STATE.md) · [D08](../../docs/battle-core/pc-campaign-design/D08-EVENTS.md). 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. 제품 코드 수정 및 Godot 실행 없음.
