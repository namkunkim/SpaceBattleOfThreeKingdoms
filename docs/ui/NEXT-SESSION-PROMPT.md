# UI·함대 표현 세션 인수 메모

새 세션이 "게임 UI 상품화 수준 개선" 작업을 이어받을 때 먼저 읽는 문서다. 갱신: 2026-10-03.
맨 아래 "새 세션 첫 프롬프트"를 그대로 붙여 넣으면 된다.

## 현재 상태

- `main` `596cbd9`: 상품화 표현 계층이 병합·푸시됐다(작업 브랜치 `feature/ui-fleet-visuals`, 병합 완료, 원격에 남아 있음).
- 구조·연결 지점·테스트·남은 일: `docs/ui/UI-FLEET-VISUALS.md`. 반드시 먼저 읽는다.
- 목표 디자인: `docs/ui/mockup-battle-v2.html`(브라우저로 연다). Godot 구현은 이 목업의 방향을 따른다.
- 확정된 방향(사용자 결정)
  - 레이아웃은 제안서 v0.2 §7.1. 코어에 없는 값(사기, 국면, 탄약·에너지·열, 진형 변경)은 가짜 값으로 채우지 않고 숨긴다.
  - 폰트는 Pretendard(본문·숫자)와 Noto Serif KR(제목·이름). `assets/fonts/`, OFL.
  - 아트 방향은 흑칠·금장 + 홀로그램. 진영은 색만으로 나누지 않는다(촉 = 사각·蜀, 위 = 마름모·魏).
  - 함대 표현은 은하영웅전설 수준이다. 함선이 많고 진형이 덩어리로 보이며, 일제 포화를 쓴다.
  - 입력은 터치와 마우스를 모두 지원한다.
- 측정값: Intel Arc 130V 내장 GPU, Compatibility, 1600×900에서 표시 함선 약 760척, 60fps.

## 다른 세션과의 규칙

- "컨셉·시나리오" 세션은 `docs/`, `data/scenarios/`, `tools/scenario/`만 수정한다. 인수 메모는 `docs/battle-core/SESSION-HANDOFF.md`.
- M1 구조 분리(`FleetBattle3D.gd` → 최상위 `core/battle/`, `view/`, `hud/`, `input/`)는 아직 맡은 세션이 없다.
- UI 작업은 새 파일로만 한다. 위치는 `hud/ui_kit/`, `view/fleet_render/`, `input/touch/`.
  - `FleetBattle3D.gd`의 HUD 함수(`_build_hud`, `refresh_panel`, `_draw_ui`, `_draw_label`, `_draw_radar`)와 3D 생성부는 고치지 않는다.
  - M1 예정 파일과 이름이 겹치지 않게 한다: `view/battle_view_3d.gd`, `view/camera_rig.gd`, `view/fx_layer.gd`, `hud/battle_hud.gd`, `hud/fleet_labels.gd`, `hud/radar.gd`.
- 전투 상태는 `view/fleet_render/battle_source.gd` 어댑터로만 읽는다. M1의 BattleProjection이 정해지면 이 파일만 고친다.
- 같은 폴더를 여러 세션이 쓴다. 구현은 `git worktree`와 새 브랜치에서 하고, 병합·푸시는 사용자가 요청할 때만 한다.

## 작업 요령(겪은 함정)

- 새 `class_name`을 추가하면 `godot --headless --path . --import`를 한 번 돌려야 전역 클래스로 인식된다.
- 가져오기를 돌리면 `.import` 파일의 줄바꿈만 바뀐다. 내용 변경이 없으면 `git checkout -- assets`로 되돌린다.
- 전체 화면 Control은 `set_anchors_and_offsets_preset(PRESET_FULL_RECT)`로 놓는다. `set_anchors_preset`은 크기가 0으로 남는다.
- `draw_string`은 폭이 0이면 정렬을 무시한다. 오른쪽·가운데 정렬은 `UiDraw.text`를 쓴다.
- 2D 선을 하나씩 그리면 느리다. `draw_multiline`으로 묶고, HUD 패널은 초당 10회만 다시 그린다.
- 헤드리스 입력 테스트는 창이 작아 좌표가 변환된다. `root.push_input(e, true)`를 쓴다.
- 캡처(`tests/capture_ui.gd`)는 창이 있는 실행에서만 의미가 있다. Godot 경로는 `C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe`다.

## 다음 할 일(우선순위)

1. **사용자 플레이 피드백 반영:** 원래 폴더의 `플레이하기.cmd`로 실행해 받은 의견을 먼저 처리한다.
2. ~~**모바일 결정 반영(Q52·Q53)**~~ 완료(브랜치 `feature/ui-polish-2`). 조용함 판정은 `BattleSource.quiet()`의 거리 기반 임시 판정이고, 저장은 `SessionGuard.suspend_requested`에 코어가 붙인다. 자세한 내용은 `UI-FLEET-VISUALS.md`의 "시간 진행과 중단 처리".
3. ~~**터치 보완**~~ 완료(`feature/ui-polish-2`): 길게 누르기 툴팁, 터치 목표 크기 점검(`tests/touch_targets.gd`), 모바일 첫 실행 UI 크기 자동 선택. 남은 것: 폰 전용 HUD 배치(시스템 아이콘·탭·그룹 탭이 폰에서 25~27dp).
4. **소리:** UI 효과음 훅(버튼, 명령 확정, 경보, 격침)과 음량 설정. 자산은 라이선스를 확인하고 사용자 승인 뒤에 들인다.
5. **정본 편성 연결:** `data/scenarios/red_cliffs_208_realtime.json`의 전대·지휘관·함종 구성을 브리핑과 정보 패널에 보여 준다. 함종 구성은 지금 표현용 배치다.
6. **코어 값이 생기면:** 사기 막대, 5국면 표시, 탄약·에너지·열 게이지, 진형 탭을 목업 v2의 자리대로 붙인다.

## 테스트

```
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/touch_input.gd
godot --headless --path . --script tests/ui_flow.gd
godot --headless --path . --script tests/pacing.gd
godot --headless --path . --script tests/touch_hold.gd
godot --headless --path . --script tests/touch_targets.gd
godot --path . --script tests/capture_3d_poc.gd
godot --path . --script tests/capture_ui.gd -- battle res://out/ui-battle.png
```

## 새 세션 첫 프롬프트

```
성한지(C:\WorkSpace\SpaceBattleOfThreeKingdoms) 게임 UI·함대 표현 상품화 작업을 이어서 한다.
먼저 docs/ui/NEXT-SESSION-PROMPT.md, docs/ui/UI-FLEET-VISUALS.md, docs/battle-core/SESSION-HANDOFF.md를 읽고,
BATTLE_DECISIONS.md의 Q51~Q54와 이후 새 결정을 확인해라.
같은 폴더를 다른 세션도 쓰므로 구현은 git worktree와 새 브랜치에서 하고,
FleetBattle3D.gd의 HUD·3D 생성 함수는 고치지 말고 hud/ui_kit/, view/fleet_render/, input/touch/에 새 파일로 작업해라.
시작 전에 테스트 5종을 돌려 현재 상태가 통과하는지 확인하고, 인수 메모의 "다음 할 일" 1번부터 진행해라.
```
