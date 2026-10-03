# UI·함대 표현 세션 인수 메모

새 세션이 "게임 UI 상품화" 작업을 이어받을 때 먼저 읽는 문서다. 갱신: 2026-10-04(UI-3 세션).
맨 아래 "새 세션 첫 프롬프트"를 그대로 붙여 넣으면 된다.

## 현재 상태

- `main`에 UI-2 세션 작업이 모두 병합·푸시됐다(작업 브랜치 `feature/ui-polish-2`, `feature/tablet-touch`, 원격에 남아 있음).
- 구조·연결 지점·리뷰 반영표·테스트·남은 일: `docs/ui/UI-FLEET-VISUALS.md`. 반드시 먼저 읽는다.
- 컨셉 세션의 UI 리뷰: `docs/battle-core/REVIEW-UI-v2.md`(§1~§12). 1~4차 지적(U·C·V·W·X) 가운데 지금 고칠 수 있는 것은 모두 반영했다.
- 목표 디자인: `docs/ui/mockup-battle-v2.html`(브라우저로 연다).
- 확정된 방향(사용자 결정)
  - 레이아웃은 제안서 §7.1. 코어에 없는 값(사기, 국면, 탄약·에너지·열, 진형 변경)은 가짜 값으로 채우지 않고 숨긴다. 화면 숫자는 코어 카운터만 쓴다.
  - 폰트 Pretendard(본문·숫자)·Noto Serif KR(제목·이름). 아트는 흑칠·금장 + 홀로그램. 세력은 글리프로도 나눈다(촉 蜀·사각, 위 魏·마름모, 오 吳·원).
  - 함대 표현은 은하영웅전설 수준(MultiMesh·LOD, 일제 포화). 입력은 터치와 마우스.
- 측정값: Intel Arc 130V 내장 GPU, Compatibility, 1600×900에서 표시 함선 약 760척, 60fps.

## 1차 목표 플랫폼(Q56)

- **안드로이드 태블릿 + 윈도우 PC**. 폰은 1차 목표가 아니다.
- 터치 목표 48dp: 모든 화면의 누를 수 있는 컨트롤을 52단위 이상으로 맞췄다(16:10 태블릿 UI 100%에서 약 48~49dp). `tests/touch_targets.gd`가 태블릿 3종 기준으로 전 화면을 검사한다.
- UI-3에서 안전 영역(`input/touch/safe_area.gd`), 가로 고정, ETC2/ASTC 압축 설정, Android 내보내기 프리셋, 모바일 첫 실행 표시 밀도(낮음, 임시), 밀도 측정 도구(`tests/bench_density.gd`)를 넣었다. 자세한 것은 `docs/ui/ANDROID-EXPORT.md`.
- **아직 못 한 것: 실제 내보내기와 실기기 확인.** 이 PC에는 내보내기 템플릿·JDK·Android SDK가 없어 APK를 한 번도 만들지 못했다. 사용자가 설치한 뒤 ANDROID-EXPORT.md의 "사용자가 해야 할 것"을 따른다.

## 사용자 작업 방식

- 판단은 Claude가 하고 특이점이 없으면 확인 없이 진행한다. 결정이 정말 필요한 것만 묻는다.
- **"커밋 푸시"는 작업 브랜치를 main에 병합(--no-ff)해 main을 푸시한다는 뜻이다.** 병합 뒤 main 폴더에서 `--import`를 한 번 돌려야 `플레이하기.cmd`가 새 `class_name`을 안다(`.import` 줄바꿈 변경은 `git checkout -- assets`로 되돌린다).
- 같은 폴더를 다른 세션도 쓴다. 병합 전에 ListAgents로 확인하고, 병합 뒤 같은 폴더 세션에 알린다. 다른 세션의 미추적 파일(`.claude/`, `CLAUDE.md` 등)은 건드리지 않는다.

## 다른 세션과의 규칙

- "컨셉·시나리오" 세션은 `docs/battle-core/`, `data/scenarios/`, `tools/scenario/`만 수정한다. UI 의견은 UI 세션으로 보낸다. 인수 메모는 `docs/battle-core/SESSION-HANDOFF.md`.
- M1 구조 분리(`FleetBattle3D.gd` → `core/battle/`, `view/`, `hud/`, `input/`)는 구현 세션 몫이다(`docs/battle-core/IMPLEMENTATION-HANDOFF.md`).
- UI 작업은 새 파일로만 한다. 위치는 `hud/ui_kit/`, `view/fleet_render/`, `input/touch/`.
  - `FleetBattle3D.gd`의 HUD 함수(`_build_hud`, `refresh_panel`, `_draw_ui`, `_draw_label`, `_draw_radar`)와 3D 생성부는 고치지 않는다.
  - M1 예정 파일과 이름이 겹치지 않게 한다: `view/battle_view_3d.gd`, `view/camera_rig.gd`, `view/fx_layer.gd`, `hud/battle_hud.gd`, `hud/fleet_labels.gd`, `hud/radar.gd`.
- 전투 상태는 `view/fleet_render/battle_source.gd`로만 읽고, 쓰기(배속, 시간 배율, 되돌리기)도 여기를 거친다. M1 BattleProjection이 정해지면 이 파일만 고친다.
- 구현은 `git worktree`와 새 브랜치에서 한다.

## 코어가 생기면 바꿀 곳(BattleSource)

| 함수 | 지금(POC) | 코어 |
|---|---|---|
| `rules()` | set "poc" 값 | set "v02" 값(문구가 자동으로 확정 규칙으로 바뀐다) |
| `quiet()` | 아군·적 전체 거리 | 공개 투영의 접촉만(V-2) |
| `command_mode(id)` | "" (표시 안 함) | "direct" / "delegated"(●/○) |
| `faction(id)` | side로 촉·위 | 투영의 세력 |
| `composition(id)` | [] | 함종 카운터 |
| `decision_progress()`, `decision_incoming()` | {} | 결정 분기 n/m, 곧 분기(3초 전) |
| `restore_orders()` | POC 필드 직접 쓰기 | "직전 상태로 돌아가는 새 명령" |
| `set_time_scale()` | `Engine.time_scale` | 틱 누산기 소비 속도만(틱 폭 100ms 유지, Q40·Q41) |

결정 카드는 투영의 `time_left`를 `time_left_src`로 그리고, 위임 판정은 코어가 한다(의심 80 카드 시간 = min(30, 간파까지 남은 게임 초 − 2)도 코어 계산). 강조 포화는 코어 일제사격 사건에서 `FleetRenderer.emphasis_volley(id)`를 부른다. 화면 값(카드 30초, 예고 3초, 빠른 알림 2초·×0.2)은 시나리오 JSON `realtime_rules.decision_cards`와 같다. 코어가 시나리오를 읽게 되면 거기서 읽는다.

## 작업 요령(겪은 함정)

- 새 `class_name`을 추가하면 `godot --headless --path . --import`를 한 번 돌려야 전역 클래스로 인식된다(가끔 종료 시 세그폴트가 나지만 등록은 된다).
- 정적 변수(`GameSettings.vol_*` 등)는 `set()`/`get()`으로 못 바꾼다. match로 직접 대입한다.
- 선택 감속은 `Engine.time_scale`이라 UI `_process`의 delta도 느려진다. UI 시간은 `UiDraw.real_dt(delta)`, 트윈은 `set_ignore_time_scale()`.
- 헤드리스 실행은 60fps보다 빠르다. 시간 대기는 프레임 수가 아니라 `create_timer`로 한다.
- 전역 난수(`randf` 등)는 POC 규칙 난수열이다. 표현 계층은 전용 `RandomNumberGenerator`만 쓴다(W-4).
- 캡처는 창 포커스를 잃으면 자동 일시정지(Q53)가 걸린다. `capture_ui.gd`는 `guard.enabled = false`로 막는다.
- bash 한 명령에 긴 파이썬 heredoc 여러 개를 넣으면 따옴표가 깨진다. 긴 편집은 스크래치 파일의 파이썬 스크립트로 한다.
- 전체 화면 Control은 `set_anchors_and_offsets_preset(PRESET_FULL_RECT)`. `draw_string`은 폭 0이면 정렬을 무시하므로 `UiDraw.text`를 쓴다.

## 다음 할 일(우선순위)

1. **사용자 플레이 피드백:** 원래 폴더의 `플레이하기.cmd`로 실행해 받은 의견을 먼저 처리한다(아직 받은 적 없음).
2. **태블릿 마무리(남은 것):** 템플릿·SDK 설치 뒤 실제 내보내기와 실기기 확인, 태블릿 성능 측정으로 표시 밀도 기본값 확정(PC 측정에서는 밀도가 프레임에 영향이 없었다. 병목은 고정 비용), 화면(타이틀 등)에도 안전 영역이 필요한지 확인.
3. **실제 효과음·음악:** 출처와 라이선스를 사용자에게 승인받은 뒤 `assets/audio/ui|battle/<사건>.ogg`로 넣는다(사건 15종, `UI-FLEET-VISUALS.md` "소리").
4. **조조군 전부 공개 화면 연결:** `roster_screen.open_roster(true, 난이도)`는 있다. 적벽 시나리오 전투의 결산이 생기면 거기서 연다(지금 결산은 시험 전투라 붙이지 않았다).
5. **코어 값이 생기면:** 사기(bp + ● ◐ ▽ ×), 5국면, 탄약·에너지·열, 진형 탭, 지휘 상태 ●/○, 결정 분기, 강조 포화, 리뷰 §11의 소리 자리(국면 전환, 사기 구간, 붕괴 위기, 화공 단계, 결집, 기함 위기).

## 테스트

```
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/touch_input.gd
godot --headless --path . --script tests/ui_flow.gd
godot --headless --path . --script tests/pacing.gd
godot --headless --path . --script tests/touch_hold.gd
godot --headless --path . --script tests/touch_targets.gd
godot --headless --path . --script tests/rule_text.gd
godot --headless --path . --script tests/order_undo.gd
godot --headless --path . --script tests/squadron_strip.gd
godot --headless --path . --script tests/ui_sound.gd
godot --headless --path . --script tests/decision_flow.gd
godot --headless --path . --script tests/roster.gd
godot --headless --path . --script tests/safe_area.gd
godot --path . --resolution 1920x1200 --script tests/bench_density.gd
godot --path . --script tests/capture_3d_poc.gd
godot --path . --script tests/capture_ui.gd -- battle res://out/ui-battle.png
godot --path . --resolution 1600x1000 --script tests/capture_ui.gd -- battle res://out/ui-tablet.png
```

캡처 장면: title, brief, quiet, battle, select, hold, undo, decision, wu, incoming, salvo, roster, roster_full, pause, suspend, settings(쪽 번호 인자), result.
Godot 경로: `C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe`.

## 새 세션 첫 프롬프트

```
성한지(C:\WorkSpace\SpaceBattleOfThreeKingdoms) 게임 UI·함대 표현 상품화 작업을 이어서 한다.
먼저 docs/ui/NEXT-SESSION-PROMPT.md, docs/ui/UI-FLEET-VISUALS.md, docs/battle-core/REVIEW-UI-v2.md,
docs/battle-core/SESSION-HANDOFF.md를 읽고, BATTLE_DECISIONS.md의 Q51 이후 결정을 확인해라.
1차 목표 플랫폼은 안드로이드 태블릿 + 윈도우 PC다.
같은 폴더를 다른 세션도 쓰므로 구현은 git worktree와 새 브랜치에서 하고,
FleetBattle3D.gd의 HUD·3D 생성 함수는 고치지 말고 hud/ui_kit/, view/fleet_render/, input/touch/에 새 파일로 작업해라.
"커밋 푸시"는 작업 브랜치를 main에 병합해 main을 푸시하라는 뜻이다.
시작 전에 테스트 13종을 돌려 통과하는지 확인하고, 인수 메모의 "다음 할 일" 1번부터 진행해라.
```
