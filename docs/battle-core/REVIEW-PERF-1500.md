# 리뷰: 렌더링 최적화 (perf/render-1500)

대상: 브랜치 perf/render-1500, 커밋 0c5a4c4 ~ 2a139ee (main 병합 77bdbbb 포함). 리뷰 2026-10-10, 코드는 고치지 않았다.

## 범위

- 읽은 파일: `hud/ui_kit/tactical_overlay.gd`, `hud/ui_kit/ui_draw.gd`, `scripts/FleetBattle3D.gd`, 맥락으로 `view/battle_view_model.gd`(apply/interpolate), `view/battle_view_3d.gd`(sync), `hud/ui_kit/presentation.gd`, `view/camera_rig.gd`, `out/bench-density.md`.
- 같은 구간의 core/ 변경(O1 organization.gd 등)은 범위 밖이라 보지 않았다.
- 성능 수치는 재측정하지 않았다(구현자 보고 기준).

## 실행한 테스트와 결과

`--headless --path . --import` 후 `-s tests/<이름>.gd`. 전부 PASS.

| 테스트 | 결과 |
|---|---|
| smoke | FLEET_3D_SMOKE_PASS |
| ui_flow | UI_FLOW_PASS |
| fog_ui | FOG_UI_PASS |
| formation_display | `OK formation_display` (PASS 문자열 없이 OK 출력, 종료 정상) |
| fleet_follow | FLEET_FOLLOW_PASS |
| selection_groups | SELECTION_GROUPS_PASS |
| touch_input | TOUCH_INPUT_PASS |
| order_undo | ORDER_UNDO_PASS |
| pacing | PACING_PASS |
| ui_wording | UI_WORDING_PASS |
| terrain_display | TERRAIN_DISPLAY_PASS |
| range_rings, squadron_strip, decision_flow (추가) | 각 PASS |

종료 시 "resources still in use" 경고는 전 테스트 공통이며 이번 변경 전부터 있던 소음으로 본다(정적 파선 텍스처 캐시가 더하는지는 확인 못함). boundary, rule_text는 지시대로 돌리지 않았다.

헤드리스는 렌더링이 없다. 그리는 순서, 파선 모양, 투영 결과는 테스트가 검증하지 못한다(아래 "사람이 확인").

## 항목별 검토

1. 파선 텍스처: `dashed_poly`가 `ci.texture_repeat == ENABLED`일 때만 새 길로 간다. 켜는 곳은 `TacticalOverlay.setup` 하나뿐이고 이 노드에는 자식이 없다. 속성은 상속되지 않으므로(DEFAULT는 ENABLED가 아님) radar_scope, world_canvas(천하 지도), 편성 화면은 옛 길을 그대로 쓴다. 새어 나갈 경로는 없다. 위상은 옛 `acc = -offset`, `cyc = fposmod(acc + t, 주기)`와 새 `u0 = acc / 주기`가 같고, 무늬는 화면 px 기준이라 줌·회전과 무관하다(옛 코드도 화면 px 기준). 차이는 무늬 길이가 1/4 px로 양자화되는 것과 선형 필터로 끝이 약 0.25px 번지는 것뿐이다.
2. 명패 순서: 회귀가 있다(R1).
3. `_pump` 생략: 안전하다. 사건과 투영은 `sim.step()`과 `issue()`/`debug_*`에서만 생기고, 후자는 직접 `_pump()`를 부른다. `vm.apply`는 `advanced` 가드가 있어 틱 없는 프레임의 `_sync`가 원래도 ppos를 덮어쓰지 않는다. `vm.interpolate(a)`는 매 프레임 유지된다. 일시정지, 결정 카드, 브리핑은 `G.state != "play"`라 이 블록 자체가 안 돈다. 배속은 `clock.set_speed`가 틱 수만 바꾸므로 영향 없다. 카메라 따라가기, 선택, 미리보기는 `_pump`와 무관한 화면 쪽 상태이고 fleet_follow, selection_groups, order_undo, touch_input이 통과했다. 접촉 이동(`cgoal`)도 `advanced`일 때만 움직이므로 동일하다.
4. `view3d.sync` 생략: `presentation == null`일 때만 매 프레임 부르므로 POC·테스트 경로는 그대로다. 표현 계층이 있으면 틱마다 `_sync` 안의 sync는 그대로 불리고, 숨김은 presentation `_process`가 매 프레임 한다. 약점은 R3.
5. `_proj_begin`: `_draw` 맨 앞에서 부르고 `_ground_ring`의 모든 호출이 `_draw` 안(`_terrain`, `_contact`)이다. 카메라는 `rig.update()`가 `_process`에서 갱신한 뒤 그려지고, 행렬과 `_vs`는 그릴 때마다 새로 읽으므로 창 크기 변경에도 낡지 않는다. 수식은 `Camera3D.unproject_position`과 같은 구조다. 다만 같다는 증거가 테스트로 없다(R2).

## 발견 사항

| 심각도 | file:line | 내용 | 권고 |
|---|---|---|---|
| 중간 | hud/ui_kit/tactical_overlay.gd:89-98 | R1. 도형 전체 → 글자 전체 → 아이콘 전체 순이라 겹친 명패의 앞뒤가 깨진다. 옛 코드는 명패 단위(배경, 글자, 아이콘)라 뒤 순서 명패가 앞 명패의 글자를 가렸다. 지금은 모든 배경이 먼저 깔리므로 아래 명패의 이름·경고 아이콘이 위 명패의 몸통과 선택 금테를 뚫고 비쳐 보인다. 선택·조사 중인 명패와 안개 속 적 명패도 같은 영향을 받는다(애초에 선택 우선 정렬은 없었으나 글자 비침은 새 현상). 부수 변화로 `_contact`/`_symbol`이 전부 명패 아래로 깔린다. | 선택(`selected`/`inspect`) 명패와 겹침이 있는 명패는 별도 묶음으로 뒤에 그린다. 최소안: `plates`를 선택 여부로 정렬해 선택 명패를 마지막에 두고, 선택 명패는 단계 3개를 한꺼번에 그린다. 겹침이 없으면 지금 방식 유지. |
| 낮음 | hud/ui_kit/tactical_overlay.gd:28-40 | R2. `_ground_ring`이 `unproject_position`을 손으로 복제한다. 카메라 뒤 점(w<=0)과 카메라 `h_offset`/`keep_aspect` 같은 변형에서 같은 결과인지 테스트가 없다. `_proj_begin`을 안 부르고 `_ground_ring`을 쓰면 영행렬로 조용히 틀린다. | 카메라 임의 자세 몇 개에서 `_ground_ring`과 `battle.w2s` 결과를 비교하는 헤드리스 테스트 하나를 추가한다(range_rings에 넣어도 된다). |
| 낮음 | scripts/FleetBattle3D.gd:321 | R3. 숨김을 presentation `_process`가 맡는다. `presentation`이 있어도 그쪽 `renderer`가 null이거나 함대가 비면 조기 반환해 POC 노드가 숨겨지지도 갱신되지도 않는다(틱 때만 갱신). 정상 경로에서는 발생하지 않는다. | 조건을 `presentation == null or presentation.renderer == null`로 좁히거나 현재 상태를 주석으로 명시한다. |
| 낮음 | hud/ui_kit/tactical_overlay.gd:16 | R4. 오버레이 전체에 texture_repeat를 켜므로 글자 아틀라스 가장자리 샘플이 감싸질 수 있다(이론상 글리프 가장자리 번짐). 오버레이에 텍스처를 쓰는 그리기가 추가되면 파선 길이 조건이 깨진다는 전제가 코드 주석에만 있다. | 화면에서 글자 가장자리를 확인한다. 이상이 있으면 파선 띠만 별도 자식 CanvasItem에 repeat를 켜서 그린다. |
| 낮음 | hud/ui_kit/tactical_overlay.gd:359-400 | R5. `_tri_fan`이 삼각형마다 `append_array([k, k+i, k+i+1])`로 임시 배열을 만든다. GDScript 비용이 명패 수에 비례한다. 현 측정에서는 문제가 아니다. | 필요할 때 `_ti.resize` 후 직접 대입한다. 지금은 손대지 않는다. |
| 정보 | out/bench-density.md | 목표 "최악 프레임 33ms 이하"는 PC 1,500척에서 34~55ms로 미달이다(평균 FPS 67~89, 최소 45 FPS 기준은 충족). 구현자도 원인을 core `sim.step()` 틱 프레임(약 11ms, 최대 23ms)으로 적었고 이는 이번 범위 밖이다. | 판정에서 뷰·HUD 몫은 달성, 최악 프레임은 코어 최적화로 이월한다고 CHECKLIST에 적는다. |

심각도 높음, 정확성을 깨는 결함은 찾지 못했다.

## 사람이 화면에서 확인할 목록

1. 함대 여러 개가 겹쳐 명패가 포개진 장면에서 이름·경고 아이콘이 다른 명패 몸통을 뚫고 보이는지(R1). 선택한 함대 명패가 이웃 명패 글자에 가려지거나 반대로 이웃 글자가 선택 금테 위에 겹치는지.
2. 안개 속 적(추정 %, 상실·마지막 위치)과 명패가 겹칠 때 읽을 수 있는지.
3. 사거리·오차·지휘 범위 파선 고리: 점·틈 간격, 흐르는 파선(명령 미리보기, 이동 표식)이 이전 빌드와 같은지. 줌 최소·최대, 카메라 회전 후에도 확인. 카메라 바로 아래를 지나는 고리가 찢어지거나 번쩍이지 않는지.
4. 같은 빌드에서 천하 지도(`world_canvas`의 파선 경로), 레이더, 편성 화면의 파선이 이전과 같은지.
5. 한글 글자(명패 이름, 말풍선, 부유 숫자) 가장자리가 번지지 않는지(R4).
6. 일시정지, 배속 변경, 결정 카드, 재생 중에 선택, 명령 미리보기, 카메라 따라가기가 즉시 반응하는지. 정속에서 함대 이동이 매끄러운지(틱 없는 프레임 `_pump` 생략 후 보간).
7. 창 크기를 바꾸거나 전체화면 전환 직후 바닥 고리가 함대와 어긋나지 않는지. 안드로이드 태블릿에서 같은 확인.
8. 1,500척 프리셋에서 FPS와 최악 프레임을 사용자가 직접 한 번 더 본다.

## 판정

조건부 수용.

- 수용 근거: 요청 범위(뷰·HUD) 안이고, 요청한 테스트가 모두 통과하며, `_pump` 생략과 sync 생략과 행렬 캐시는 코드 추적상 안전하다. 파선 새 길은 다른 화면으로 새지 않고 위상이 옛 로직과 같다.
- 조건: R1(겹친 명패, 특히 선택 명패)을 사람이 화면에서 확인한다. 거슬리면 위 권고대로 선택 명패를 마지막에 그린다. 최악 프레임 33ms는 코어 틱 비용 때문에 이월로 기록한다.
