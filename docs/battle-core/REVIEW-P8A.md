# REVIEW-P8A — 장수 특기 코어 (5-b 리뷰)

대상: claude/eloquent-gould-b2d0f6 — dea251b + aaf45a0(병합) + 6866507(편성 화면 슬롯 재채움). 정적 검토만 했다(godot가 PATH에 없어 테스트는 돌리지 않았다).

## 판정: 조건부 수용

Q92·Q93·Q95와 슬롯 구조, 결정론, "슬롯을 비우면 기존 지문" 경로(모든 배율이 1.0/BP로 정확히 항등)는 결정과 맞다. 높음 0건. 중간 5건(F-1~F-5)은 P8c(UI) 전에 고치거나 사용자가 결정하면 된다.

기존 실패 확인: boundary 실패(battle_source.gd의 BattleRules, org_screen.gd의 ProfileLoader·ScenarioProfile)는 origin/main에도 같은 줄(`battle_source.gd:177`, `org_screen.gd:131-132`)이 있어 기존 실패다. 6866507은 Organization 호출만 더했다.

## 발견

**F-1 중간 — `skill_end` 사건이 적에게 새고 시전자에게는 안 간다.** `skills.gd:381` `emit("skill_end", f.id, ...)`의 sq는 효과를 *가진* 함대다. 적 대상 기술(교란)은 holder가 적 함대라서 `battle_sim.gd drain_events_for`(side != 필터)가 적 진영에게 기술 ID(`x.id`)를 넘기고, 시전 진영은 해제를 못 받는다. 해석 10번("적에게 알리지 않는다")이 skill_end에서는 깨진다. 권고: 사건에 시전 함대 ID(src)를 sq로 두고 holder를 value에 넣거나, `skill*` 필터를 src 기준으로 한다. tests/special_skills 5번에 skill_end·적 대상 기술 케이스를 추가한다.

**F-2 중간 — 투영 `fx`가 적에게 시전 함대 ID를 노출한다.** `view()`(skills.gd:387-397)는 아군 함대의 `_fx_of(f)` 전부를 `{id, src, left_s}`로 낸다. 교란이 걸린 아군 함대의 투영에 적 함대 ID(src)가 들어간다(확인 접촉이 아닌 적일 수 있음). 걸린 디버프 아이콘은 알려도 되지만 src와 시전한 기술 ID는 적 정보다. 권고: 적이 건 효과는 id만(또는 일반 "교란됨") 주고 src는 뺀다. 사용자 결정 U-2 참고.

**F-3 중간 — 해석 8(AI 술어가 실제 상태를 읽음)은 안개 원칙 위반이다.** `_pred`의 `enemy_flagship_within`/`enemy_carrier_within`(skills.gd:225-229)은 `o.is_flag`·`o.stages`를 직접 읽는다. 그런데 `BattleProjection.contact()`의 확인 접촉에는 기함 여부·함종이 없고(`squadron()`에만 있음), commander_ai 머리말은 "공개 투영에서 적 접촉만"을 입력으로 못 박았다. 적 AI(관우·허저 조건)와 위임 아군이 사람이 모르는 정보로 발동한다. 위임 함대가 "기함 근처에서만 관우 발동"으로 사람에게 기함 위치를 누설하는 부수 효과도 있다. 권고: (a) 확인 접촉 투영에 두 키를 공개하고 술어가 투영을 읽게 하거나, (b) 술어를 투영에 있는 정보(strength_band 등)로 바꾼다. 사용자 결정 U-1.

**F-4 중간 — 재생 재현 테스트가 없다.** 명령 로그(`issue`→`command_log`)로 사람의 `skill` 명령을 재생해 같은 지문이 나오는지 시험이 없다. 시험 3번은 `_cmd`가 `sim.apply`를 직접 부른다. `replay(seed, hz, log, until, profile)`에 slot·skill_id·target_id가 실려 같은 결과가 나오는지, 프로필 헤더(슬롯 포함) 왕복 후 지문 동일을 한 번 확인해야 "재생 헤더·명령 로그로 재현"이 단언된다. 또 `"skill"`이 `DIRECT_KINDS`에 없어 위임 함대에 사람이 발동해도 control이 delegate로 남고 같은 틱에 AI가 다른 슬롯을 또 쓸 수 있다(함대당 한 틱 하나는 ai_eval 안에서만 보장). 의도라면 주석으로 남기고, 아니면 DIRECT_KINDS에 추가한다.

**F-5 중간 — 효과 시험 범위가 좁다.** 단언이 있는 것은 맹공·견수·철벽·신속·질주·일신시담(합성값)·신기묘산·강궁(사거리)·격려(AI)뿐이다. 악래(분담 합계 보존), 호치(`assault_blocked`), 만인지적(성공률·clamp·forced_div 순서), 귀모·간파(확인 승격·move_to 공개), 미주랑(화공 위력 ×1.3), 진창(in_terrain), 교란(상대 명중/사기), 조달(charges_add), 고육계(slot 경로·letter_uses 공유), 지휘 승계 중 발동은 시험이 없다. 합성 시험은 `fx`를 손으로 넣어 `mul()`만 본다. 같은 시험 3번의 `zr == [...] or [...]`는 느슨하다(하나로 고정).

**F-6 낮음 — 받는 피해 0/감소가 분담 몫에는 적용되지 않는다.** `salvo.gd _resolve`: 악래 몫을 먼저 떼어 보호자(g)의 배율만 곱하고, 기함의 `damage_taken_mul`(예: 일신시담 0)은 남은 몫에만 곱한다. 일신시담 대상 기함이 "받는 피해 0"인데 악래 함대는 50%를 받는다. Q95 취지(겹침 하나)와도 어긋날 수 있다. 권고: 기함 배율을 먼저 곱한 뒤 분담하거나 의도를 SPECIAL-SKILLS에 적는다.

**F-7 낮음 — 해석 1(받는 피해 배율이 일제사격에만 적용)은 데이터 문구와 불일치.** 일신시담 text는 "받는 선체 피해 0"인데 화공 폭발·강습 나포는 통과한다. 의도라면 해석을 문구에 반영(예: "포화·교전 피해"). 사용자 결정 U-3.

**F-8 낮음 — 리터럴·주석.** detection.gd의 `best = 2`는 확인 레벨 매직 넘버(`level_of`의 반환 2). `D.confirmed` 기준으로 레벨을 구하거나 상수로 둘 것. `fleet_state.gd`의 `skill_used` 주석("ID → 발동 틱")은 실제 횟수다. `fingerprint()`는 fx의 `until`·남은 시간을 포함하지 않고 개수만 넣는다(상태 도출은 틱 결정론이라 안전하지만 불일치 검출력이 약하다).

**F-9 낮음 — 동률 규칙이 `st.fleets` 순서에 의존.** `targets()`의 nearest/lowest_hull_ratio는 첫 후보가 이기고(`<` 엄격), 명시 ID 정렬이 없다. `st.fleets`가 spawn 순서(ID 오름차순)면 data의 `tie:"id"`와 같지만, 가정을 코드나 시험으로 고정한다. 일신시담 대상 시험을 동률 hull로 하나 추가.

**F-10 낮음 — 성능.** 효과가 없을 때 `mul`/`range_mul`은 조기 반환해 1,500척에서도 틱당 추가 비용이 사실상 없다. 효과 중에는 샷마다 `_fx_of` 배열 연결이 생기고(`side_fx` 비지 않을 때만), `ai_eval`은 생각 틱마다 슬롯×술어에서 `_confirmed()` 배열을 새로 만든다. 함대 약 19개 규모라 문제 없음. 측정은 P8a 200시드 on/off 대조(Q93)에 포함하면 된다.

## 해석 10항목 판정

| # | 판정 | 비고 |
|---|---|---|
| 1 | 조건부 타당 | 일제사격만 적용. F-6·F-7 |
| 2 | 타당 | 결집 `rally_no_source`와 같은 기준 |
| 3 | 타당 | 문구와 일치(ally_within은 타 함대, 일신시담은 자기 포함) |
| 4 | 타당 | 강제 퇴각은 명령이 거부되니 AI도 건너뜀 |
| 5 | 타당 | chain_hazard 제외는 합리적 |
| 6 | 타당 | 호치 발동 순간 고정(후에 들어온 함대 제외)은 단순하고 결정적 |
| 7 | 타당 | 신기묘산 즉시 전환, 시험 있음 |
| 8 | 반려 대상 | F-3 |
| 9 | 타당 | AI는 상태에서 재계산, 사람은 명령 로그. F-4로 시험 보강 |
| 10 | 부분 | skill_end 누설(F-1) |

## 결정·일치 확인 (이상 없음)

- Q92: `skill_used[id]`와 `uses_left`가 (함대, ID) 쌍. 중복은 validate가 `skill_duplicate`, `default_slots`는 다음 후보. 다른 함대 같은 ID 허용 시험 있음.
- Q93: `chain_power_mul_bp` 13000이 `ignite`에서 host의 side_fx로 곱해짐. 유비 명의 화공에도 적용(시전 진영 기준).
- Q95: `lo`(감소) 최소 하나 × `hi`(증가) 최대 하나. 합성 시험·철벽 holding·일신시담 0 시험 있음. 진창(80%)과 견수(80%)는 하나만.
- Q68: 관우 `has_ship_type SHP-01` 0척 거부 시험 있음.
- 기존 상시 효과(master_trait·escort_trait·elite_ids)는 건드리지 않음. 만인지적은 escort 뒤·forced_div 앞이며 `assault.chance_bp`의 들여쓰기 변경은 기존 동작(forced_div는 flagship 종류에만)과 같다.
- 6866507: 장수 이동·삭제 시 `default_slots` 재채움. toggle off, `_set_slot` 모두 처리. 사용자가 슬롯을 직접 고르는 UI(P8b)가 생기면 지금처럼 매번 덮어쓰면 안 된다(P8b에서 변경 필요).
- Organization 회귀: 슬롯 키가 없는 헤더는 `apply`가 기본값으로 채우고 `validate`는 건너뜀(P8a 이전 헤더 호환). `organization_rules`의 "기본 편성은 결과 불변" 시험을 슬롯 비운 편성으로 바꾼 것은 타당하지만, "슬롯이 차 있으면 결과가 바뀐다"는 사실이 이 시험의 본래 보증(불변)을 약화시키므로 special_skills 7번이 그 몫을 대신하는지 확인 필요(7번은 `special_skills` 제거본과 비교해 통과).

## 사용자 결정 필요

- U-1 (F-3): AI/위임의 `enemy_flagship_within`·`enemy_carrier_within`을 (a) 투영에 기함·강습모함 여부를 공개하고 투영으로 읽는다 (b) 투영에 있는 정보로 술어를 바꾼다 (c) 지금처럼 실제 상태를 읽는다(안개 원칙 예외로 명문화).
- U-2 (F-2): 적이 건 디버프를 받은 함대의 투영에 시전 함대 ID·기술 ID를 보이는가.
- U-3 (F-7): "받는 선체 피해" 효과를 화공 폭발·강습 나포에도 적용할 것인가. 현재는 일제사격만.
