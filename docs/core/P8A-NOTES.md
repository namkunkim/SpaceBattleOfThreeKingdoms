# P8a 장수 특기 코어 — 구현 노트

근거: `BATTLE_DECISIONS.md` §U(Q88~Q95, U-1 P8a 행)·§S-1 D4·Q68, `docs/battle-core/SPECIAL-SKILLS.md`, `REVIEW-P8-0.md`.
데이터: 시나리오 `realtime_rules.special_skills`(제안값). 코어에 수치 리터럴 없음(`data_rules` 통과).

## 바뀐 파일

| 파일 | 내용 |
|---|---|
| `core/battle/skills.gd` (새 `SkillCore`) | 발동(`use`)·거부 사유·대상(`targets`, target_pick)·효과 합성(`mul`/`add`/`flag`, Q95)·만료(`step`)·AI 발동(`ai_eval`)·투영(`view`)·지문 |
| `core/battle/organization.gd` | 편성 함대 `skill_slots`, `default_slots`(직책 순, 같은 ID는 다음 후보, 모자라면 ""), `fleet_skills`, validate 사유 `skill_duplicate`·`skill_foreign`·`skill_unknown`(슬롯 수 불일치 포함), 형식 오류는 `bad_fleet`. `default_org`·`auto_fill`이 채우고 `apply`가 프로필 정의로 넘긴다(키가 없으면 기본값 = 이전 재생 헤더 호환). 재생 헤더 = `profile.organization`(슬롯 포함) |
| `fleet_state.gd` | `skill_slots`, `skill_used`(ID → 횟수), `fx`(기간 효과) |
| `battle_sim.gd` | `skills` 생성(시나리오에 special_skills가 있을 때), 명령 `skill`(args.slot 또는 skill_id, target_id), 이동 속도 배율, 틱 첫머리 만료, 지문, 적 진영 사건에서 `skill*` 제거 |
| `salvo.gd` | 출력 피해(`damage_mul_bp`), 명중(`hit_bp` 가산), 사거리(`range_mul_bp`, `range_mul()` — platforms·사전 차단·상한 모두), 진형 전환 시간(0이면 즉시), 상성 무시, 받는 피해·악래 분담(`_resolve`) |
| `morale.gd` / `detection.gd` | 사기 감소 배율 / 센서 배율, reveal 반경 안 적 = 확인 |
| `assault.gd` | `assault_bp`(escort 뒤·forced_div 앞, clamp), `assault_block` 사유 `assault_blocked` |
| `stratagem.gd` | 미주랑 위력 ×(진영 효과), 화공 AI 서신이 고육계 슬롯이 남아 있으면 `skill` 경로로 |
| `victory.gd` | 일신시담 대상은 구조 함대로 인정 |
| `ai/commander_ai.gd` | 생각 틱마다 함대 ID 순으로 `ai_eval` → `_think_fleet` |
| `battle_projection.gd` | 아군 함대 `skills = {slots: [{id, name, target, uses_left, block}], fx: [{id, src, left_s}]}`, 귀모 대상 확인 접촉에 `move_to` |

## 해석으로 정한 것 (리뷰 확인 바람)

1. **받는 피해 배율·악래 분담은 일제사격 피해에만** 적용한다(**Q98 확정**, 문구는 "사격 피해"). 화공 폭발·강습 나포·강행 실패는 배율 밖. 기함의 받는 피해 배율을 먼저 곱한 뒤 악래가 나눠 받는다(F-6).
2. `commander_down` = 지휘 불능이고 이은 사람도 없을 때(결집 `rally_no_source`와 같은 기준). 부제독이 이었으면 발동 가능.
3. `ally_within`은 자기 함대를 세지 않는다. 일신시담 대상은 자기 포함(target_pick.include_self).
4. `holding`에서 "후퇴"는 `morale.fleeing`(강제 퇴각 + 후퇴 명령). AI는 강제 퇴각 중인 함대로 발동하지 않는다(명령이 거부되기 때문).
5. 지형 구역(진창 `in_terrain`)은 시나리오 지형 구역이고, 화공 위험 지대(`chain_hazard`)는 뺀다.
6. 대상 효과는 대상 함대에 붙는다(교란 명중 −8%p는 맞은 적의 명중, 일신시담·호치는 받은 함대). 호치 반경 안 함대는 발동 순간에 정한다(이후 들어온 함대는 효과 없음).
7. 진형 전환 시간이 0이 되면(신기묘산) 새 전환은 즉시, 걸린 순간 진행 중인 전환도 즉시 끝낸다.
8. ~~AI 적 조건이 적 기함·강습모함을 실제 상태에서 읽음~~ → **폐기(Q96)**. 확인 접촉 투영에 `flagship`·`carrier`를 공개하고, 술어는 지휘관 AI가 읽은 공개 투영만 본다(`ai_eval(f, view)`). 안개 없는 프로필(POC)에는 `carrier` 키가 없어 거짓.
9. 사용 기록은 명령 로그(사람)와 상태 재계산(AI)이다. 재생 헤더에는 슬롯만. 사람이 `skill`을 내면 그 함대는 직접 지휘가 된다(`DIRECT_KINDS`, F-4: 다른 명령과 같고 같은 틱 AI 발동이 겹치지 않는다).
10. 발동 사건 `skill`(sq = 시전 함대, value {id, targets})·`skill_end`(sq = 시전 함대, other = 효과를 가졌던 함대, value = 기술 ID). 적 진영 `drain_events_for`에서는 빠진다(F-1). 적이 건 효과는 받은 함대 투영 `skills.fx`에 `{id, name, left_s, foe: true}`만, 시전 함대 `src`는 없다(Q97).
11. `requires`는 데이터 순서로 본다. 악래를 기함이 쓰면 `ally_flagship_within`(자기 제외)에서 먼저 거부되고 `self_not_flagship`은 겹치는 안전장치다.
12. 대상 고르기 동률은 함대 ID 오름차순으로 명시 비교한다(F-9).

## 테스트

- 새 `tests/special_skills.gd`: 슬롯 기본값(유비 본대 격려·교란·신기묘산, 손권 2함대 견수 중복 → 질주), validate 사유 3종 + 형식 오류 + 슬롯 없는 헤더, JSON 왕복, 1회 제한·다른 함대 같은 ID 허용, 거부 사유(skill_used·skill_no_slot·skill_requires_has_ship_type(관우)·대상 없음·commander_down), 만료, Q95 겹침(감소 최소 × 증가 최대, 철벽 holding, 일신시담 0), 신기묘산 즉시 전환, 강궁 사거리 ×1.3, 투영 아군만·적 사건 숨김, AI 발동·결정론(같은 시드 두 번), **슬롯을 비우면 special_skills가 없는 코어와 같은 지문**.
- `data_rules`: special_skills 스키마(필수 키, 대상·효과·requires·ai_when 술어 허용 목록, 거리대 이름, slot_default 직책명, stacking 규칙, by_officer 참조, 특성 보유 장수 = 기술 보유).
- `organization_rules`: "기본 편성은 결과 불변"을 슬롯 비운 기본 편성으로 바꿈, 승계 시험은 부제독을 뺀 뒤 슬롯을 다시 채움(안 하면 `skill_foreign`).
- `autoresolve`: `--no-skills 1`(특기 끔), `--skill-off SK-..,..`(기술별 on/off), 행 m9.skills(기술별 발동 수). `summarize.py`가 판당 발동 수를 낸다.

## 리뷰 처리 P8a-b (REVIEW-P8A 조건부 수용, 2026-10-12)

F-1 skill_end 시전 진영만 · F-2/Q97 적 효과 시전자 숨김 · F-3/Q96 투영 공개 + 술어 투영만 · F-4 재생 시험 + DIRECT_KINDS · F-5 효과 시험(악래 분담·기함 배율 먼저, 호치 assault_blocked, 만인지적 +3000·clamp·forced_div 순서·대기 초기화, 미주랑 진영, 진창 지형, 교란 사기·명중·사건·투영, 조달 +1·가득 거부, 고육계 슬롯 = 서신·운용 함대만, 승계 중 발동, 일신시담 동률 ID) · F-6 기함 배율 먼저 · F-7/Q98 문구(생성기 → JSON 재생성) · F-8 탐지 확인 레벨은 `level_of(D.confirmed)`, `skill_used` 주석, 지문에 효과 만료 틱 · F-9 동률 명시.

## 대기(P8b·P8c·후속)

- ~~**P8b 주의**: 6866507은 장수가 바뀔 때마다 슬롯을 덮어쓴다~~ → **P8b에서 대체됨**: `Organization.refill_slots`가 직접 고른 칸을 그 장수가 남아 있는 한 유지하고 빠진 장수의 칸만 기본값 후보 순으로 채운다(의도한 동작). 칸 비우기 기능은 없다(특기 없는 장수만 빈칸, YAGNI).

- 편성 화면에서 장수를 바꾸면 슬롯 재채움(P8b). 지금은 `repair`가 `skill_foreign` 함대를 자동 편성으로 다시 채운다(함대 전체).
- 발동 UI·토스트 문구(P8c): 사유 코드 `skill_used`·`skill_no_slot`·`commander_down`·`skill_requires_*`·`skill_no_target`·`assault_blocked`.
- 사거리 원(P2)은 `ranges`가 효과 중 늘어난 값이라 그대로 따라간다(화면 확인은 P8c).

## 표준 200시드 전후 대조 (탐색, 2026-10-12)

`tools/m7/baseline.sh 표준 200 4 0`, 정책 none(AI 대 AI, 세 세력 자동 편성), 코드 6866507(main P5 회피 기동 병합 뒤). 끔 = `--no-skills 1`(P8a 이전과 같은 판, 빈 슬롯 지문 시험이 보증).

| | 끔 `_p8a0_1012_6866507` | 켬 `_p8a_1012_6866507` |
|---|---|---|
| 연합 승률(Wilson 95%) | **42.5%** (35.9~49.4%) | **38.0%** (31.6~44.9%) |
| 길이 중앙 / p10 / p90 | 16.8 / 15.8 / 18.0분 | 16.7 / 15.9 / 17.9분 |
| 종료: 연합 사기 붕괴 / 조조 사기 붕괴 / 유비 기함 상실 / 시간 | 45.0 / 42.5 / 9.5 / 2.0% | 53.5 / 38.0 / 8.0 / 0.5% |
| 비용 손실 연합 / 조조 | 24.3 / 22.3% | 24.1 / 20.7% |
| 화공 발동 / 위력 평균 | 12% / 0.150 | 10% / 0.195(미주랑) |
| 특기 발동 | — | 판당 24.8회 |

기술별 판당 발동: 맹공 4.26 · 교란 4.0 · 질주 3.63 · 간파 3.0 · 격려 2.94 · 조달 2.12 · 강궁·신속·신기묘산 1.0 · 고육계 0.99 · 견수 0.41 · 철벽 0.15 · 진창 0.12 · 미주랑 0.12. 일신시담·악래·호치·귀모·만인지적은 0(조건·편성상 안 맞음).

해석: 차이 −4.5%p는 200시드 구간이 겹쳐 유의하지 않다(탐색). 길이는 같다. 특기 켬에서 연합 사기 붕괴가 늘었다(조조군 함대 수가 많아 유형 기술 발동 합이 크다). **이 기준선 자체가 예전 표준 78~85%보다 크게 낮다(끔 42.5%)** — P8a가 아니라 main에 들어온 P5 회피 기동(또는 그 사이 변경) 쪽 변화로 보인다. 1000시드 최종과 밸런스 판단은 O3b.

리뷰 처리(27b3715) 뒤 표준 시드 0~7을 다시 돌려 승패·길이·종료 경로·기술별 발동 수가 수정 전과 모두 같아(Q96 투영 술어 포함) 위 값을 그대로 쓴다(`_p8ab8_1012_27b3715`). 지문 문자열은 F-8로 형식이 바뀌어 행으로 비교했다.
