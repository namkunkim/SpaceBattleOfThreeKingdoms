# P1 리뷰 (진형 표시·적 접촉 패널)

2026-10-10, 5-b 외부 리뷰(Opus, 구현은 Sonnet). 대상: 브랜치 `p1-formation-display` 커밋 `2bd0160` (`git diff main...p1-formation-display`). 코드는 수정하지 않았다.

**판정: 병합 가능.** 차단 항목 없음. 원래 버그(뷰 모델 `form_id` 고정 → 렌더러 `_reform` 영원히 안 돎)는 고쳐졌고 헤드리스로 확인했다. 전환 5초 동안 3D 모양이 안 바뀌는 문제는 남아 있으며 후속 조각(F-1)으로 제안한다.

## 1. 발견

| # | 심각도 | 위치 | 내용 |
|---|---|---|---|
| F-1 | 중간(후속) | `view/battle_view_model.gd:166`, `core/battle/salvo.gd:152-162` | 투영 `formation`(=`f.shape`)은 전환 **완료 틱**에만 바뀐다(`_transition_step` → `_apply_shape`). 헤드리스 측정(§3): 방원진→어린진 명령 뒤 4.9초 동안 `sq.formation=4`, 렌더러 `v.formation=4`, 5.0초에 7로 바뀐다. 사용자는 5초(통솔 미달도 5초, 승계 혼선이면 더 길다) 동안 3D 변화를 못 본다. 패널에는 "→ 어린진 n초" 카운트다운이 이미 있으므로(`command_deck.gd:734`, `formation_tab.gd:45`) 이번 PR을 막을 이유는 아니다. **제안(P1-b, 화면만):** `form_to != ""`이면 렌더러에 목표 배치도를 넘겨 전환 시간 동안 함선이 새 슬롯으로 미끄러지게 한다. 투영에 키를 더하지 말고 뷰 모델에서 `form_to`를 배치도 번호로 바꾼다. 단 `BattleRules.FORM_SHAPE`는 화면 계층에서 쓰면 `boundary` 위반이므로, 매핑을 투영에 이미 있는 값으로 얻을 방법(예: 투영이 `form_to_shape`를 내는 것)은 코어 키 추가라 별도 결정이 필요하다. 전환 중 이동·사격 규칙(§4.7: 전환이 끝날 때까지 이전 진형)과 화면이 어긋나는 점도 함께 판단할 것. |
| F-2 | 낮음 | `view/battle_view_model.gd:137`, `view/fx_layer.gd:45` | `FleetView.form`(오프셋 배열)도 생성 시 한 번만 복사된다. `FxLayer.ship_pos`가 이것으로 피격·폭발 위치를 잡으므로 전환 뒤 효과 위치가 옛 진형 기준이다. 렌더러와 무관해 이번 버그의 원인은 아니다. `shape`가 바뀔 때 `f.form.assign(s.form)`을 같이 하면 된다. |
| F-3 | 낮음 | `hud/ui_kit/command_deck.gd:647-652` | 적 확인 접촉은 `form_name`이 ""라 메타가 `"적 · "`로 끝난다(빈 구분자). `meta == ""`면 `"적"`만 쓰는 편이 깔끔하다. |
| F-4 | 낮음 | `view/battle_view_model.gd:273-274` | `band`·`max_band`는 확인 접촉일 때만 갱신되고 추정·상실로 떨어져도 값이 남는다. 그래서 확인됐던 접촉이 추정으로 바뀌면 패널이 마지막 "전력 b/B"를 계속 보인다(이름·`ships`도 기존부터 같은 방식으로 남는다). 한 번도 확인되지 않은 접촉은 "전력 ?". 새 정보 누출은 아니고 "마지막으로 안 값" 정책이지만, 추정 접촉이면 "전력 b/B(마지막)" 같은 표시가 필요한지는 UI 결정 사항. |
| F-5 | 정보 | `view/fleet_render/battle_source.gd:44-47` | POC 규칙(`combat.formations` 없음)에서는 아군 진형 이름이 ""가 된다(이전엔 POC `FORM_NAMES`). 적벽 실전은 salvo 규칙이라 영향 없음. 의도대로라면 그대로 둔다. |

## 2. 확인 항목별 결론

1. **정확성:** `FleetView.shape`가 매 틱 투영 `formation`으로 갱신되고(`battle_view_model.gd:166`), `battle_source._sq`가 이를 렌더러에 넘긴다. `fleet_renderer.gd:628` 비교가 참이 되어 `_reform`이 돈다(측정으로 확인). 전환 중에는 **이전 모양**을 넘긴다(F-1).
2. **공개 경계:** 적 접촉(`contact != ""`)은 진형 이름 "", 척 수 숫자·"/ N척" 미표시(전력 구간만), 세부(속도·사거리·진형)는 `src.detail`이 `contact != ""`면 빈 사전이라 안 그려진다. 접촉의 `shape`는 갱신되지 않아 0(횡진) 고정이고, 접촉 `form`은 4열 격자 고정이라 3D 모양으로 진형이 새지 않는다. 투영 새 키 추가 없음(기존 `formation`·`strength_band`·`max_strength_band`만 읽는다). `fog_ui` 통과.
3. **7종 이름:** `data/scenarios/base/formations.json`과 본편 `Seonghanji/data/formations.json`이 같다: FRM-01 어린진, 02 학익진, 03 방원진, 04 안행진, 05 봉시진, 06 장사진, 07 팔진. 패널(`form_name`)과 M10 진형 탭(`FormationTab._name`)이 같은 `combat.formations[fid].name`을 읽어 어긋날 수 없다. `FORM_SHAPE [7,5,4,8,1,9,2]`도 Q10 매핑(어린·학익·안행·장사 동명, 방원=원진, 봉시=쐐기진, 팔진=방진)과 일치.
4. **경계:** 새 코어 클래스 참조 없음(`boundary` 위반 목록이 main과 같은 1건뿐, §4).

## 3. 헤드리스 진형 전환 측정

스크래치 스크립트로 `FleetBattle3D` 실행, 아군 첫 전대에 FRM-03→FRM-01 명령, 0.1초 틱.

```
t=0.1s form_to=FRM-01 left=4.9 sq.formation=4 renderer.v.formation=4 name=방원진
t=4.1s form_to=FRM-01 left=0.9 sq.formation=4 renderer.v.formation=4 name=방원진
t=5.0s form_to=       left=0.0 sq.formation=7 renderer.v.formation=7 name=어린진
```

## 4. 테스트 결과 (개별 실행)

Godot 4.7.2 콘솔판, `--import` 뒤 `tests/*.gd`를 하나씩 `Start-Process`로 돌리고 제한 시간(150초) 넘으면 `taskkill /T` + 남은 Godot 자식(비콘솔판) `Stop-Process`. 별도 worktree(`p1`·`main` 분리)에서 실행해 다른 세션과 겹치지 않게 했다.

| 결과 | 테스트 |
|---|---|
| 통과(종료 0) | audit_3d_models, audit_user_ver3_models, battle_flow, bench_density, commander_ai, core_rules, data_rules, decision_flow, detection_rules, fleet_follow, fog_ui, **formation_display(신규)**, formation_rules, formation_ui, mouse_input, order_undo, pacing, roster, rule_text, rule_text_salvo, safe_area, salvo_rules, selection_groups, smoke, squadron_strip, stratagem_rules, succession_rules, supply_rules, touch_hold, touch_input, touch_targets, ui_flow, ui_sound, victory_rules, world_link (35종) |
| 실패(기존, main도 같음) | boundary(아래), capture_3d_poc(`TEST_FAIL selected` @ `capture_3d_poc.gd:19`, main 워크트리에서도 같은 실패) |
| 미실행(시간 초과) | autoresolve, salvo_compare: 판정 테스트가 아니라 통계 실행기(기본 수백 판). 150초 안에 안 끝난다. 구현자가 본 "정체"도 이것으로 보인다. capture_formation, capture_ui, capture_world: 화면 캡처 도구라 헤드리스에서 끝나지 않음 |

**boundary 기존 실패 확인:** main(`cf8d124`)을 별도 worktree로 체크아웃해 직접 돌렸다. main에서도 실패한다: `view/fleet_render/battle_source.gd:163 BattleRules.BP` (P1 브랜치에선 줄이 밀려 172). 위반 목록 전체가 이 1건뿐이라 P1이 새 위반을 더하지 않았다. 이 기존 위반은 별도 조각으로 고칠 일이다.

## 5. 병합 충돌 예측 (`p2-range-rings`, `b2f9ca5`)

- `view/battle_view_model.gd`: P1은 `FleetView` 필드(16행 뒤)·`apply`(166행), P2는 `range_r` 뒤 필드(42행)·참조 연결 루프(184행). 서로 다른 덩어리.
- `view/fleet_render/battle_source.gd`: P1은 `_sq`의 34-35행(`formation`·`formation_name`)과 새 함수, P2는 39행(`"ranges"` 추가). 사이에 바뀌지 않은 줄 3개.
- `git merge-tree --write-tree p1-formation-display p2-range-rings` → **충돌 없음**(종료 0). 의미상 충돌도 없다(P2는 `ranges` 투영 키를 아군 전용으로 추가, P1은 투영 키 추가 없음).

## 6. 사용자 로컬 확인 체크리스트 (PC, 태블릿 APK)

- [ ] 아군 전대 선택 → 진형 탭에서 다른 진형(예: 방원진→어린진) 명령 → 패널에 "→ 어린진 n초" 카운트다운이 뜨는가
- [ ] 카운트다운이 끝나는 순간 3D 함선들이 새 배치로 이동하는가(전환 중 5초는 모양이 그대로다: F-1)
- [ ] 정보 패널 진형 이름이 진형 탭 이름과 같은가(7종: 어린·학익·방원·안행·봉시·장사·팔진)
- [ ] 적 확인 접촉 선택 시 "적 · "와 "전력 b/B"만 보이고 척 수·진형 이름·세부(속도·사거리)가 없는가
- [ ] 적이 추정 접촉으로 떨어진 뒤 패널 표시가 납득할 만한가(F-4)
- [ ] 진형 전환 뒤 피격 섬광·폭발이 함선 위치에 맞는가(F-2: 어긋나면 후속)
