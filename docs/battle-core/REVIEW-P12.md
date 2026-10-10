# REVIEW-P12 — P1·P2 후속 정리 (5-b 외부 리뷰)

- 대상: `p12-followups` 커밋 `4ae3bd4` (`git diff main...p12-followups`, 4파일 +54/−9)
- 리뷰어: Opus (구현 Sonnet과 다른 모델). 코드 수정·병합 없음.
- 검증 환경: 별도 worktree(main `171c098`, p12 `4ae3bd4`, p12+p9a 병합 트리) 헤드리스 + 창 캡처 1600×900

**판정: 수정 후 병합.** 차단 결함은 없다. 다만 (1) 새 `.uid`가 커밋에서 빠졌고, (2) "탐지 N" 이름표가 실제 화면에서 거의 나오지 않는다(F-1). (1)은 커밋 하나로 끝난다. (2)는 이번 PR에서 고치거나 대기열로 넘기는 것을 사용자가 정한다.

## 1. 발견

| # | 심각도 | 위치 | 내용 |
|---|---|---|---|
| F-1 | 중간 | `hud/ui_kit/tactical_overlay.gd:105-107` | "탐지 N" 이름표는 **확인 고리(r_conf>0)**에만 붙는다. 확인 반경은 (센서 − 30) × 25라 센서 30 미만 전대는 확인 고리가 없다. capture `battle` 장면 측정: 아군 6전대 중 5전대가 r_conf=0(관우 sc=21, 유비 22, 정보 23, 유기 6, 황개 10). 선택된 관우도 r_conf=0이라 **이름표가 그려지지 않는다**. 구현자가 스크린샷에서 못 본 원인이다. 확인 고리가 있는 주유(sc=55, r_conf=625)는 이름표 위치 `ring[54]`가 270°(화면 위쪽)라 cam_z=1에서 화면 좌표 y=−119로 **화면 밖**이다(중심 y=301). 즉 이름표는 "작은 확인 고리"에서만 보인다. 제안: 확인 고리가 없으면 추정 고리에 "탐지(추정) N"을 붙이고, 각도는 무기 이름표(45°·135°·225°·315°)와 겹치지 않는 아래쪽(예: 90°)으로 하거나 화면 안으로 clamp. |
| F-2 | 중간(누락) | `tests/fx_follow_formation.gd.uid` | 커밋에 없다. 구현 worktree(`agent-a20723b73c0934c3c`)에 untracked로만 있다. P2 때 `range_rings.gd.uid`도 같은 이유로 따로 커밋했다. 병합 전에 추가 커밋 필요. 같은 worktree의 `M *.import` 수십 개(재임포트 부산물)는 커밋하면 안 된다. |
| F-3 | 낮음(효과 없음) | `view/battle_view_model.gd:168`, `scripts/FleetBattle3D.gd:127-133`, `hud/ui_kit/presentation.gd:45-47` | 수정 자체는 맞고 테스트로 확인했다(main에서 `fx_follow_formation.gd:30` "효과 위치가 현재 배치" 실패 → p12 통과). 하지만 `FxLayer`는 `battle.ui`(FleetLabels)와 **같은 CanvasLayer**에 붙고, 상품화 HUD가 있으면 `_hide_legacy_hud`가 그 레이어를 통째로 숨긴다. 따라서 실제 게임 화면에선 `FxLayer.boom`이 보이지 않는다. POC 모드(presentation 없음)에서는 3D 함선이 `battle_view_3d.build_fleet:116`에서 **생성 시 배치로 고정**되어 진형 전환 후에도 안 움직이므로, 이번 수정 뒤엔 효과가 오히려 메시와 어긋난다. 다만 POC 모드에서 salvo 진형 전환이 일어나는 경로는 사실상 없다. REVIEW-P1 F-2의 전제("화면 효과가 옛 진형 기준")가 상품 화면에선 성립하지 않았다는 점을 기록한다. 되돌릴 필요는 없다. |
| F-4 | 낮음 | `tactical_overlay.gd:84` | 함수 머리 주석이 "안쪽 실선 = 확인, 바깥 점선 = 추정"으로 남아 있다. 지금은 둘 다 점선이다(촘촘/성긴). |
| F-5 | 낮음(성능) | `tactical_overlay.gd:103` | 확인 고리가 폴리라인(73점)에서 파선 2/4로 바뀌어, 반경 625 고리 하나가 화면에서 약 440조각이다(GDScript 루프, 매 프레임 `queue_redraw`). 아군 전대 전부에 그리므로 줌인 시 수천 조각이다. `DASH_MAX_SEG` 보호는 있다. PC 캡처는 60FPS다. 태블릿 FPS 로그(`adb logcat -s godot`의 "FPS")로 확인할 것. |
| F-6 | 정보 | `view/battle_view_model.gd:168` | 매 틱 `f.form.assign(s.form)`: 아군 전대 7개 × 오프셋 수십 개 Vector2 복사. 투영 주기에서만 돌아 부담은 무시할 만하다. 투영의 `form`은 코어 배열 참조지만, `assign`이 복사하므로 뷰가 코어를 별칭으로 잡지 않는다(좋음). 줄이려면 `shape`가 바뀔 때만 복사하면 된다. 필수는 아니다. |
| F-7 | 정보 | 정보 패널(P9a 병합 후) | 패널에서 함종 개수 줄은 "포격 6 · 전열 9 · 요격 6"(`scenario_roster` short)이고 탄약·사거리 줄은 "미사일(포격) … · 광선(전열) …"이다. 함종과 무기 범주라 용어가 다른 것은 맞다. 다만 사용자가 같은 말로 읽을 수 있으니 화면 확인 항목에 넣는다. |

## 2. 확인 항목별 결론

1. **정확성**
   - 항목 1(효과가 진형을 따름): 해결. main worktree에 새 테스트만 넣어 돌리면 `fx_follow_formation.gd:30`에서 실패하고(진형 전환 확인 단계 :28은 통과), p12에서는 `FX_FOLLOW_FORMATION_PASS`. 실제 화면 영향은 F-3 참고.
   - 항목 2(탐지·광선 고리 분리): 색(INK_2 회백색 vs ALLY)과 선(점선 vs 실선)은 분리됐다. 이름표는 F-1.
   - 항목 3(AMMO_LABEL 통일): 해결. `RANGE_STYLE`이 `BattleSource.AMMO_LABEL`을 읽는다. 화면 계층(hud)이 view 계층을 참조하는 것이라 `boundary` 위반이 아니다(위반은 기존 1건뿐).
   - 항목 4(이름표 12px, 반투명 판, 외곽선 2): 반영됐다. 캡처에서 "요격 210", "광선(전열) 180", "미사일(포격) 260"이 이전보다 잘 읽힌다.
   - 항목 5(뇌격 선+점): 12/12 파선 위에 3px 점(2/22, offset −6)을 겹친다. 적벽 데이터 캡처 장면엔 뇌격 고리가 없어 화면으로는 확인하지 못했다(사용자 확인).
2. **공개 경계:** 투영 키 추가 없음. `battle_projection.gd`는 변경이 없고, 기존 `form` 키만 매 틱 읽는다. `squadron()`은 자기 전대 전용이고 적 접촉(`contact()`)에는 `form`이 없다. 탐지 고리는 아군 자기 센서 점수만 쓴다. `fog_ui`·`detection_rules` 통과.
3. **AMMO_LABEL 사용처:** `battle_source.gd:286`(정의), `command_deck.gd:732`(탄약 줄), `tactical_overlay.gd:112-115`. P9a는 `command_deck.gd`의 사거리 줄에서도 `src.AMMO_LABEL.get`을 쓴다. 테스트에는 "포격 N"이나 "직사"를 기대하는 하드코딩이 없다(grep에 나온 "포격"은 함종·함대 이름이고 라벨이 아니다). P9a `tests/info_panel.gd`도 라벨 문자열을 검사하지 않는다. 숨은 의존은 없다. p12+p9a 병합 트리에서 `info_panel` 통과, 캡처(select)로 보면 패널 폭 안에 들어간다.
4. **"탐지 N" 이름표:** F-1. 코드와 측정 모두 "대부분 안 그려지고, 그려지면 화면 위 밖"이다. 로컬 확인 항목에 넣는다.
5. **테스트:** §3.
6. **누락 파일:** F-2.
7. **병합 충돌:** §4.

## 3. 테스트 결과 (p12 `4ae3bd4`, 별도 worktree, 개별 실행, 제한 150초)

| 테스트 | 결과 | 비고 |
|---|---|---|
| fx_follow_formation (새) | 통과 | main에서는 실패(:30). 회귀를 잡는 테스트다 |
| range_rings, formation_display, fog_ui, detection_rules | 통과 | |
| battle_flow, commander_ai, core_rules, data_rules, decision_flow, fleet_follow, formation_rules, formation_ui, mouse_input, order_undo, pacing, roster, rule_text, rule_text_salvo, safe_area, salvo_rules, selection_groups, squadron_strip, stratagem_rules, succession_rules, supply_rules, touch_hold, touch_input, touch_targets, ui_flow, victory_rules, world_link, bench_density | 통과 | |
| smoke, ui_sound | 통과 | 첫 회차는 임포트가 끝나기 전에 돌아 실패(리소스 미임포트). 재임포트 후 재실행해 통과. 코드 원인 아님 |
| boundary | 실패(기존) | `battle_source.gd:172 BattleRules.BP` 1건. main과 같다(줄 번호만 이동) |
| capture_3d_poc | 실패(기존) | `TEST_FAIL selected` |
| capture_ui, capture_formation, capture_world | 미실행(헤드리스 타임아웃) | 창 실행 전용. `capture_ui battle`·`select`는 창으로 실행해 통과 |
| audit_3d_models, audit_user_ver3_models | 실패(도구) | 감사 스크립트. 판정 대상 아님 |
| autoresolve, salvo_compare | 제외 | 통계 실행기 |
| p12+p9a 병합 트리: info_panel, fx_follow_formation, range_rings, formation_display, fog_ui, smoke | 통과 | |

새 실패 없음. 안드로이드 export는 이번 리뷰에서 실행하지 않았다.

## 4. 병합 충돌 예측

- `p9a-info-panel`(`461b7c5`): `git merge-tree --write-tree` 충돌 없음(`edef30e`). 겹치는 파일은 `battle_view_model.gd`(p12는 :168 squadron 갱신, p9a는 :269 `_apply_contact`로 다른 함수), `battle_source.gd`(p12는 :286 AMMO_LABEL, p9a는 :309 detail `commander`). 의미상 상호작용: p9a 사거리 줄이 새 이름을 그대로 쓴다. 병합 트리 테스트·캡처 정상.
- `p6a-terrain-display`: 리뷰 시작 시엔 커밋이 없었다(미커밋 `tactical_overlay.gd` +54, `git apply --check`로 p12 위에 깔끔히 적용됨). 리뷰 중에 커밋됐다(`ef7a246`, `c62d415`). `merge-tree` p12×p6a 충돌 없음(`ab82fb3`), p9a×p6a도 충돌 없음. p6a의 hunk(`tactical_overlay.gd` :29, :81 부근)는 p12 hunk(:95~)의 바로 위라 순서와 관계없이 자동 병합된다. 지형 이름표가 `_ring_label`과 비슷한 판을 쓰면 나중에 하나로 합칠 수 있다(선택).

## 5. 사용자 로컬 확인 체크리스트

- [ ] 센서가 높은 전대(예: 주유)를 선택하고 카메라를 당기거나 이동했을 때 "탐지 N" 이름표가 보이는가. 센서가 낮은 전대(관우 등)는 이름표가 없는 것이 맞는가, 아니면 추정 반경에도 이름표가 필요한가(F-1 결정)
- [ ] 탐지 고리(회백색 점선 2종)와 광선(전열) 실선 고리가 한눈에 구분되는가
- [ ] 사거리 이름표 "미사일(포격) / 광선(전열) / 요격 / 뇌격"이 성운 위에서 읽히는가. 태블릿에서도
- [ ] 뇌격 고리가 있는 전대(뇌격함 편성)를 선택했을 때 긴 선 + 점 모양이 보이는가. 색약 필터(적록)에서 요격과 구분되는가
- [ ] 정보 패널에서 "포격 6 · 전열 9"(함종)와 "미사일(포격) 35"(탄약)가 헷갈리지 않는가(F-7)
- [ ] 태블릿 APK에서 아군 전대 여럿과 줌인 상태의 FPS(logcat "FPS")가 이전과 비슷한가(F-5)
- [ ] (참고) 진형 전환 뒤 피격 섬광·폭발은 상품 렌더러가 그린다. 이번 수정(FxLayer)과는 무관하다(F-3)

## 6. 병합 전 할 일

1. `tests/fx_follow_formation.gd.uid`를 커밋한다(`.import` 변경은 제외).
2. F-1: 이번 PR에서 고칠지(추정 고리 폴백 + 각도 변경), `CHECKLIST-OPEN.md` 대기열로 넘길지 정한다.
3. F-4 주석 한 줄(선택).
