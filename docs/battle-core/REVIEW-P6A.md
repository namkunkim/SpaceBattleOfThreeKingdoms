# P6a 리뷰 (지형 3구역 표시)

2026-10-10, 5-b 외부 리뷰(Opus, 구현은 Sonnet). 대상: 브랜치 `p6a-terrain-display` 커밋 `ef7a246` (`git diff main...p6a-terrain-display`, 4파일 +99/−1). 코드는 수정하지 않았다.

**판정: 수정 후 병합.** 표시 값은 정확하다(코어 사각형·정본 배율 일치). 막는 것은 `boundary.gd` 위반이 1건 → 3건으로 늘어난 것(G-1) 하나다. 두 줄 고치면 된다. 나머지는 후속으로 넘겨도 된다.

## 1. 발견

| # | 심각도 | 위치 | 내용 |
|---|---|---|---|
| G-1 | 높음(차단) | `hud/ui_kit/tactical_overlay.gd:101`, `:103` | 화면 계층에서 `BattleRules.BP`를 쓴다. `tests/boundary.gd`의 `CORE_CLASSES` 위반이 main 1건(`battle_source.gd:172`)에서 3건으로 늘었다(§3). 고치는 법: 기준값을 `10000` 지역 상수로 두거나, 투영·뷰 모델 쪽에서 배율(float)로 바꿔 넘긴다. 앞쪽이 한 줄 수정이다. |
| G-2 | 중간(결정 필요) | `tactical_overlay.gd:95-104`, `core/battle/stratagem.gd:243` | `battle.sim.terrain.zones`를 직접 읽으므로 **화공 임시 지형**(`TRN-ZFIRE-nnn`, type `chain_hazard`, 이동 15000bp, 160×160)도 그려진다. 스타일이 없어 기본 회색, 이름표 "반응로 연쇄 유폭 지대 이동 ×1.50". 이 사각형은 불붙은 **조조군 전대의 점화 순간 위치**(`t.pos`) 중심이라, 그 전대가 미탐지여도 위치가 드러날 수 있다. 플레이어 쪽 투영에 `burning`(불타는 전대 ID)은 이미 탐지와 무관하게 나가므로 큰 누출은 아니지만, 이번 PR 범위(정본 3구역)를 벗어난 표시다. `terrain_display`는 시작 시점에만 3개를 세서 이를 못 잡는다. 선택지: (a) 정본 3구역만 그리도록 type 필터, (b) 임시 지형도 정식으로 그리되 스타일·정책을 정한다(BATTLE_DECISIONS에 Q 추가). |
| G-3 | 중간(구조) | `tactical_overlay.gd:97` | 코어 상태(`battle.sim.terrain`)를 직접 읽는다. "같은 파일의 `battle.sim.detect` 선례"는 커밋 `158cd46`(터치 시험 때 탐지 원)에서 들어온 것으로, 허용된 패턴이 아니라 `boundary.gd`가 클래스 이름만 검사해서 안 잡힌 **기존 위반**이다(`BATTLE-CORE-HANDOFF.md:283` "화면은 공개 투영만 읽는다"). 지형은 비밀이 아니라 실해는 없다. 이번 PR을 막을 이유는 아니며, 후속으로 지형 구역(정적 3구역)을 투영이나 화면 모델 초기화 값으로 내보내고 `_detect_rings`도 함께 옮기는 조각을 대기열에 둘 것을 권한다. |
| G-4 | 낮음 | `tactical_overlay.gd:136` | 이름표가 구역 중심에 붙는다. 성운(정본 600,50,120×120)과 잔해대(680,100,140×120)가 x 680-720, y 100-170에서 겹치고 중심 간 거리가 작아, 축소(0.5배) 화면에서 두 이름표가 위아래로 붙고 성운 이름표가 잔해대 윤곽을 가로지른다(§4 스크린샷). 기본 카메라에서는 서로 겹치지 않는다. 겹친 구역은 이름표를 바깥 모서리(성운 = 좌상, 잔해 = 우하)로 옮기면 된다. |
| G-5 | 낮음 | `tactical_overlay.gd:136` | 기본 카메라(0.9배)에서 성운·잔해대는 화면 맨 위라 이름표가 상단 전력 패널 **아래로** 들어가 반투명 판 너머로 비친다(1920×1080, 1280×800 둘 다). 1280×800에서는 성운 이름이 패널에 거의 가려진다. 기존 고리 이름표도 같은 성질이라 이번 PR만의 문제는 아니다. 이름표 위치를 화면 안전 영역 안으로 끌어오는 처리(clamp)는 후속. |
| G-6 | 낮음 | `tactical_overlay.gd:99-103` | 필터가 `move_cost_bp > BP`라 이동 비용 1.0인 지형(센서·은폐·사거리만 바꾸는 구역)은 그리지 않는다. 지금 정본 3구역은 모두 1보다 커서 누락은 없다. 이름표도 이동 배율만 보여 주는데 실제로 더 큰 효과는 은폐(+8/+3/+12)·사거리(×0.85/×0.90/×0.80)다. 사용자가 "왜 저기서 안 맞지"를 알 단서가 없다. 정보 패널(P9a) 쪽에서 구역 효과 요약을 보여 주는 후속을 권한다. |
| G-7 | 정보 | 화면 | 배경 그림(왼쪽 소행성 무리, 오른쪽 붉은 성운)과 규칙 구역 위치가 맞지 않는다. 배경의 소행성 무리는 규칙상 아무 효과가 없고, 규칙상 잔해대는 빈 하늘에 사각형으로만 있다. 사용자가 "소행성대·행성이 전장에 있다"고 느끼려면 P6b에서 구역 위치에 시각 대상(소행성 메시·행성 원반)을 두거나 배경을 구역에 맞춰야 한다. |
| G-8 | 정보 | `tests/terrain_display.gd` | 오버레이 사각형 = 코어 사각형 비교는 같은 배열을 읽어 동어반복이다. 의미 있는 검증은 정본 `shape × (FIELD_SIZE / 1600×900)` 비교와 배율 비교 두 가지이고, 이 둘은 맞게 들어 있다. 이름(`name`) 비교와 그리기 호출(구역 3개가 실제로 그려지는가)은 없다. 낮은 우선순위. |

## 2. 확인 항목별 결론

1. **정확성:** 맞다. `tools/scenario/make_combat_m3.py:277-285`가 정본 `red-cliffs-terrain-rules.json` 3구역을 `combat.terrain.zones`(`rect`, `move_cost_bp` 13333/15385/11111)로 옮기고, `ScenarioProfile.enlarge_field`(`scenario_profile.gd:138-146`)가 `rect`를 전장 비율로 늘린다. 오버레이는 그 늘린 `rect`를 그대로 읽으므로 코어가 이동 계산(`battle_sim.gd:877-878`)에 쓰는 값과 같다. 이름(적운 성운·파쇄 잔해대·행성 그림자)도 정본과 같다. 시나리오 JSON(`red_cliffs_208_realtime.json`)에는 지형 정의가 없고 전장 크기(1600×900)만 있다. 지형은 위 생성기 경로로만 들어온다. 필터는 G-6 참고.
2. **경계:** G-1(위반 증가, 차단), G-3(기존 위반 패턴 확장). 비밀 정보: 정본 3구역은 정적·공개 정보라 안개와 섞이지 않는다. `fog_ui`·`detection_rules` 통과(§3). 단 동적 화공 지형은 G-2.
3. **성능/그리기:** 빗금은 잔해대 약 8줄, 그림자 약 8줄, 구역당 `w2s` 4+빗금 끝점+1 → 프레임당 `unproject_position` 약 45회, 선 16개. 무시할 수준. `w2s`는 카메라 피치 68°·세로 FOV 48°에서 지면 점이 카메라 뒤로 가려면 목표점 남쪽으로 약 2.66×거리 이상 떨어져야 하는데, 최대 확대(2.8배)에서도 그림자 구역 아래 끝(y≈613)이 그 범위에 들지 않아 튐은 없다(계산 확인, 다른 고리 그리기와 같은 경로). 이름표 문제는 G-4·G-5.
4. **사용자 요구 충족도:** "전투 화면이 모두 항행 가능하지 않게, 우주 대상이 전장에 존재"의 1단계로는 적절하다. 규칙이 이미 있는 것을 먼저 보이게 하는 것이 맞는 순서다. 그러나 표시만으로는 "통과 불가" 체감이 생기지 않는다: 이름표가 "이동 ×1.33"이라 오히려 "통과 가능, 느릴 뿐"으로 읽힌다(정확한 표현이다). 구역이 전장 1700×1150 중 120~180 단위의 작은 사각형 셋이고 주 교전 지역(중앙 서쪽)과 떨어져 있어 체감 영향도 작다. 너무 눈에 띄거나 유닛을 가리지는 않는다: 채움 0.10은 배경 위에서 거의 안 보이고 윤곽·빗금이 구역을 알려 주며, 유닛 이름표·고리 아래에 그려진다(스크린샷 확인). 색은 성운 보라/잔해 주황/그림자 파랑으로, 잔해 주황이 조조군 빨강·미사일 고리 계열과 가까운 점은 주의(윤곽 모양이 달라 구분은 된다). 체감은 P6b(통과 불가 장애물 + 시각 대상, G-7)에서 해결해야 한다.
5. **테스트:** §3.
6. **`.uid`:** `tests/terrain_display.gd.uid` 커밋됨. 새 `.gd`는 이 하나뿐이라 누락 없음.
7. **병합 충돌:** §5.

## 3. 테스트 결과

별도 worktree(`ef7a246`, detached)에서 `--import` 후 `tests/*.gd` 개별 헤드리스 실행, 제한 150초. `autoresolve`·`salvo_compare`(통계 실행기), `capture_*`(화면 필요) 제외. 기준은 같은 방식으로 돌린 main(`171c098`).

| 테스트 | main | p6a | 비고 |
|---|---|---|---|
| boundary | 실패(1건) | 실패(3건) | 기존 실패, 위반 +2(G-1) |
| terrain_display (신규) | - | 통과 | `TERRAIN_DISPLAY_PASS` |
| fog_ui · detection_rules | 통과 | 통과 | 미탐지 정보 누출 없음 |
| range_rings · formation_display | (p2·p1 병합분) | 통과 | |
| 나머지 29개(battle_flow, commander_ai, core_rules, data_rules, decision_flow, fleet_follow, formation_rules, formation_ui, mouse_input, order_undo, pacing, roster, rule_text, rule_text_salvo, safe_area, salvo_rules, selection_groups, smoke, squadron_strip, stratagem_rules, succession_rules, supply_rules, touch_hold, touch_input, touch_targets, ui_flow, ui_sound, victory_rules, world_link) | 통과 | 통과 | |

새 실패 없음. `capture_3d_poc`는 화면이 필요해 제외(기존 실패 항목).

**boundary.gd 위반:** main 1건 → p6a 3건(+2).

```
res://view/fleet_render/battle_source.gd:172  \bBattleRules\b  <- var bp := float(BattleRules.BP)      (기존)
res://hud/ui_kit/tactical_overlay.gd:101  \bBattleRules\b  <- if z.has("rect") and int(z.get("move_cost_bp", BattleRules.BP)) > BattleRules.BP:   (신규)
res://hud/ui_kit/tactical_overlay.gd:103  \bBattleRules\b  <- "mul": float(z.move_cost_bp) / float(BattleRules.BP)})   (신규)
```

## 4. 화면 확인(캡처)

`tests/capture_ui.gd`를 화면 있는 실행으로 떴다(`--resolution`).

- `terrain`(0.5배) 1920×1080·1280×800: 3구역 모두 전장 위 올바른 자리(성운·잔해 북쪽 중앙, 그림자 동쪽)에 보인다. 성운·잔해 이름표가 붙는다(G-4).
- `battle`(기본 0.9배) 1920×1080·1280×800: 그림자 구역은 오른쪽에 깔끔히 보이고 유닛을 가리지 않는다. 성운·잔해는 화면 위쪽 끝에 걸려 이름표가 상단 패널 밑으로 비친다(G-5).

## 5. 병합 충돌 예측

`git merge-tree --write-tree` 결과 모두 충돌 없음(종료 코드 0).

| 조합 | 결과 | 비고 |
|---|---|---|
| p6a + `p12-followups`(`4ae3bd4`) | 깨끗 | 둘 다 `tactical_overlay.gd`를 고치지만 구간이 다르다(p6a는 `_draw` 첫 줄과 `_detect_rings` 앞 새 함수, p12는 `_detect_rings`·`RANGE_STYLE`·`_weapon_arcs`). p12의 `_ring_label` 어두운 판이 성운 위 가독성에 도움이 된다. |
| p6a + `p9a-info-panel`(`461b7c5`) | 깨끗 | 겹치는 파일 없음. |
| p12 + p9a | 깨끗 | 참고. |

## 6. 사용자 로컬 확인 체크리스트

- [ ] PC에서 전투 시작 후 위쪽으로 화면 이동: 성운(보라 긴 점선)·잔해대(주황 짧은 점선+빗금) 이름표가 읽히는가, 붙지 않는가.
- [ ] 동쪽 행성 그림자(파랑 실선+반대 방향 빗금)가 함대를 가리지 않는가.
- [ ] 흑백(또는 색약 시뮬레이션)으로 봐도 세 구역이 선 모양·빗금 방향으로 구분되는가.
- [ ] 화공 발동 뒤 회색 "반응로 연쇄 유폭 지대" 사각형이 나타나는가, 나타나도 되는가(G-2 결정).
- [ ] 태블릿 APK(1280×800급)에서 기본 카메라일 때 성운 이름표가 상단 패널에 가려지는 정도(G-5).
- [ ] "이동 ×1.33" 표기가 "느려진다"로 바로 읽히는가, "통과 불가"를 기대한 사용자 의도와 차이를 P6b로 넘기는 데 동의하는가.
