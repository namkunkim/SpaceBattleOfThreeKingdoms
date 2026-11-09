# 프로필 의존 상태의 정적 보충 원장

동결한 적벽 시나리오와 M3 프로필에서 읽은 값이다. 적용 시점과 프로필 변환 책임을 구분한다. 실제 적벽 초기화와 복원은 실행하지 않았다. 원문 SHA는 DYNAMIC-PROFILE-SOURCES.sha256에 남겼다.

| 상태 | 키·갱신·소비 | 제한 복원 경계 |
|---|---|---|
| MoraleCore.rally_uses | 적벽 realtime_rules.morale_events.rally의 `liu_bei_rally` (RC-LIU-SQ-01, 1회, charm 99), `zhou_yu_rally` (RC-SUN-SQ-01, 1회, charm 94). init이 이 순서로 삽입. rally에서 같은 id를 검색, 남은 횟수와 squadron/side/out 및 지휘 가능성을 확인 후 차감. 함대 사기 및 두 loss_mul 필드와 함께 갱신 | 활성 MoraleCore는 UNSUPPORTED. 데이터에 두 ID가 있다는 사실을 실제 버튼·호스트 호출 가능성으로 확대하지 않는다. 근거 시나리오 JSON:3467–3490, morale.gd:22–31,110–136 |
| FleetState.ranges | combat.categories는 artillery, line_fire, intercept, torpedo, fighter 순이다. refresh_range가 빈 사전을 만들고 현재 범위가 양수인 범주만 그 순서대로 기록한다. 수리·피해·특기에 따른 사거리 변경과 연결되며 투영에서 아군에 복사한다 | 제한 owner는 FLEET 값 복사. 현재 roster의 max range 재계산 및 범주별 exact key 검사 대상으로 분류되지 않는다. 근거 combat_m3.json:8–14, salvo.gd:279–295, battle_projection.gd:31 |
| FleetState.fired | 같은 범주 이름을 첫 일제 지연 소비에서 조건부 true로 저장. 이미 존재하면 _stagger가 0을 반환하므로 키 존재 자체가 다음 일정에 영향 | 값 복사. 고정 8개 key 배열 검사의 대상 밖. salvo.gd:653–658 |
| FleetState.vice | scenario_profile에서 null을 빈 Dictionary로 변환하고 나머지는 정의를 전달. 관측된 인물 record는 id/name/command/might/intellect/politics/charm/traits. salvo가 보관. CommandCore가 비어 있지 않은 vice를 첫 staff보다 우선하며 id를 cmdr_sub로 옮긴다 | 제한 owner가 임의 프로필 입력의 vice_commander 키를 허용하지 않는다. packet FLEET의 값 복사와 CommandCore의 제품 재결합은 별개다. 시나리오 JSON:2259–2270, scenario_profile.gd:90, salvo.gd:34, command.gd:87–100 |
| FleetState.staff | scenario_profile → salvo의 순서 있는 인물 사전 배열. 승계는 첫 행, 강습은 참여 인물 능력치를 읽는다. 관측 record의 키는 vice와 동일 | 제한 owner의 프로필 정의에서 staff 키는 지원되지 않는다. 배열을 복사하는 현재 경로와 활성 승계는 별개다. 시나리오 JSON:2271–2284, scenario_profile.gd:91, salvo.gd:35, command.gd:88, assault.gd:21–33 |
| FleetState.fx | 실제 기간 레코드 생성 키 `id,src,until,e,r`. src는 수치 fleet ID, until은 논리 tick, r은 radius 실수, e는 profile effect 사전. duration>0이고 side 효과가 아니면 fleet 배열에 append. side 효과는 side_fx로 분리. 만료를 now>=until로 제거하고 영향을 다시 계산한다 | FLEET 복사와 활성 SkillCore 거부를 분리한다. 기존 Skill 원장 분모 재합산 없음. skills.gd:330–355,389–397 |

전수 분모를 고정한 항목은 이 적벽 profile의 rally 2키와 M3 category 5키다. 전대마다 실제 ranges/fired 부분집합, 승계 record의 전수 키와 값, effect.e의 기술별 키와 외부 호출자는 미분류다. 현재 packet의 동적 키 정책이나 보안 계약을 판정하지 않았다.
