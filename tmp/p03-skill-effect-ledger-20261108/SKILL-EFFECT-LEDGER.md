# P03 SkillCore 효과 상태 책임 원장

2026-11-08 KST. 읽기 조사. 아래 경로는 core/battle 기준이다. 제한 owner는 활성 skills를 거부한다(operation_private_state.gd:8,170–174). 현재 capture/재결합 구현을 뜻하는 분류는 없다. [계획](PLAN.md) · [동결 입력](input-manifest.json)

| 선언 | 현재 타입·갱신·소비 | 복원 책임 후보 |
|---|---|---|
| M01 sim | BattleSim 객체, skills.gd:21,34–35. fleet/clock/규칙/투영/사건 및 alias_command 접근(:29–32,112–139,313–375,388–423) | 새 owner에 참조 재결합. 기존 sim 객체를 capture하지 않음 |
| M02 K | Dictionary 설정, :22,34–36. battle_sim.gd:89–90의 special_skills 설정. stacking(:55–89), 사용 한도(:267–281), defs 빌드 | 동일 실효 설정에서 재구성 및 reference/value 검증 |
| M03 defs | Dictionary skill ID→정의, :23,37–38. K.skills 순서로 대입한 설정 record 참조. :270–353,365–387,405–425에서 검증·발동·표시 | 동일 정의와 순서·alias를 재구성. 서로 다른 정의를 같은 ID로 승인하지 않음 |
| M04 side_fx | Array [side0 Array, side1 Array], :24,41–42,347–351,402–403. side 효과 append 및 만료 filter | ordered effects capture 및 시전자/정의 참조 검증. 개별 함대 효과와 같은 표로 평준화하지 않음 |
| M05 used_n | int 전체 발동 누계, :25,327,447–457의 갱신/지문 | capture 후보. 0이면 특기 지문이 빈 값인 경계 |
| M06 stats | Dictionary skill ID→int 누계, :26,328. 처음 발동 때 key를 추가 | 현재 값·순서 capture 후보. 지문에 해당 Dictionary 전체를 넣지 않음 |
| M07 _views | side별 Dictionary Array, :27,29–32,365–375. ai_eval이 해당 진영의 공개 projection을 넣고 비어 있으면 지연 생성, 선택 후 {}로 비운 뒤 apply | quiescent owner 경계에서 실제 빈 상태를 검증하면 투영 재계산 후보. AI 평가 중 snapshot 계약은 미정 |

| FleetState 필드 | 실제 출처·갱신·소비 | 복원 책임 후보 |
|---|---|---|
| F01 skill_slots | Array, fleet_state.gd:139 및 salvo.gd:36. 편성의 String ID/빈 슬롯 순서. battle_sim.gd:647–656과 skills.gd:270–281,369–387,405–414 | capture하거나 동일 편성에서 재구성 후 순서·빈 슬롯·ID를 exact 비교 |
| F02 skill_used | Dictionary skill ID→int 사용 횟수. fleet_state.gd:140, skills.gd:267–275,326,405–414,451–452 | 현재 사용 횟수 capture. 출격 초기값·발동 지문으로 추정하지 않음 |
| F03 fx | Array of Dictionary, fleet_state.gd:141. skills.gd:347–353에서 추가, :388–401에서 만료. :41–42 및 guard/reveal(:112–139) 소비 | 현재 값·정확 순서·timer·시전자/효과 참조 capture. side_fx와 서로 다른 소유 |

## 발동과 남은 효과를 분리

`use:313–355`는 조건/대상 확인 뒤 alias_command가 있으면 기존 ChainOp 서신을 호출한다. 실패면 사용 누계를 늘리지 않는다. 성공은 skill_used/used_n/stats 증가 후 대상별 즉시 사기, wch 충전, assault_cd를 갱신한다. 음수 사기는 MoraleCore가 있을 때 위임한다. duration이 양수면 그때만 효과 record를 만들고, effect 변경에 따라 range/formation을 다시 맞춘 뒤 skill 사건을 발행한다. 이 즉시 지급과 사용 횟수·사건의 재적용 여부를 만료 record에서 추론할 수 없다. `skills.gd:313–362`, `stratagem.gd:111–126`.

기간 record의 생성 순서는 id:String, src:int fleet ID, until:int tick, e:Dictionary 정의 효과 참조, r:float 반경이다. 효과는 배열에 append되며 :41–42는 함대 fx 뒤 해당 진영 side_fx를 붙인다. :45–89의 키별 category/holding/지형 조건과 min/max 또는 정수 곱셈 합성은 실제 소비 순서의 영향을 받을 수 있다. 동률 선택에서 보이는 fleet 순회/ID 조건, 데이터 key 순서, 실제 생성 가능한 정의 집합을 별도 비교한다. `skills.gd:284–309,347–353`.

`guard_of:112–121`는 기함·같은 진영·범위에서 st.fleets와 개별 o.fx를 읽어 첫 수비 함대를 찾는다. `redirect_bp:123–127`는 그 함대에서 해당 key가 있는 첫 효과를 읽는다. `reveals:130–139`도 개별 fx와 현재 위치를 본다. 시전자 src는 공개 projection/만료 사건에 쓰이는 별도 ID다. guard는 시전자 ID를 곧바로 수혜 함대로 간주하지 않는다. `salvo.gd:700–705`, `detection.gd:94,171–172`, `skills.gd:388–423`.

만료는 skills.gd:388–403에서 now≥until인 함대 효과를 제거하고 _changed와 skill_end를 호출한다. side_fx는 각 진영 배열을 filter하며 같은 루프에서 개별 _changed/skill_end를 호출하지 않는다. 실제 side 효과에 영향을 주는 정의와 범위를 별도로 검증한다. `battle_sim.gd:963–970`의 첫 하위걸음에서 skills 만료가 detect와 salvo보다 먼저다. 공격·탐지·사기·기동의 값은 각 실제 소비자가 읽는다. `salvo.gd:146,280,355,392,403,700–705`, `morale.gd:92`, `assault.gd:68,79–80`.

공개 `battle_projection.gd:32–33,140–141`는 아군 특기와 공개 조건에 맞는 정보를 제공한다. `skills.gd:405–425`에서 src는 같은 진영 시전자일 때만 표시하고 다른 경우 foe=true다. `ai/commander_ai.gd:85`의 입력 view는 해당 생각의 공개 상태다. 지문(:447–457)은 효과 id@until과 슬롯 사용 key, 전체 used_n의 요약이며 effect payload·src·개별 횟수 전체의 exact 비교가 아니다.

1. **즉시 지급 중복.** 발동 이후의 wch/사기/쿨다운·usage·사건과 기간 효과를 함께 비교하고 같은 suffix에서 지급 재실행 여부를 검사한다. 현재 제한 owner는 이 활성 모듈을 복원하지 않는다.
2. **순서와 만료.** fleet/side 효과와 만료 직전·직후의 stacking/가시·사거리 결과를 대조한다. side filter와 개별 _changed/skill_end 차이를 누락하지 않는다. 별도 runtime fixture는 아직 없다.
3. **참조와 공개 cache.** guard 후보/시전자·상태가 다른 대상에서 피해 분담과 원래 공개 가능 정보를 비교한다. _views를 무조건 저장하거나 리셋하기 전에 quiescent 경계와 stale projection 반례를 인수한다.

D04 ST07의 실제 모듈 소유를 좁혀 읽었다. 기존 P8a 동작 증거를 운영 snapshot 복원으로 재집계하지 않는다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. 제품 코드 변경 및 Godot 실행 없음. [D04](../../docs/battle-core/pc-campaign-design/D04-STATE.md) · [P8a 검토](../../docs/battle-core/REVIEW-P8A.md)
