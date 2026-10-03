# 상품화 표현 계층: 함대 표현 · HUD · 화면 흐름 · 터치

브랜치 `feature/ui-fleet-visuals` (2026-10-03). 목업은 `docs/ui/mockup-battle-v2.html`.

## 무엇이 바뀌었나

| 영역 | 이전(POC) | 지금 |
|---|---|---|
| 함대 | 전대당 28척, 척당 3.4만~6만 삼각형 노드 | 남은 전력에 비례해 전대당 50~75척(정원의 60%), 함종별 MultiMesh, 저폴리 LOD 2단계(2,400 / 480 삼각형) |
| 사격 | 매 프레임 깜빡이는 2D 선 | 1.5~2.3초 주기 일제 포화. 앞줄부터 물결처럼 발사, 화면을 향한 광선 띠, 포구 섬광 |
| 피격·격침 | 2D 점 파편 | 방어막 섬광(육각 무늬), 선체 피격 섬광, 화구·충격파·불씨·연기, 표류하며 타는 잔해, 함대 궤멸 시 연쇄 폭발 |
| 공간감 | 배경판 + 격자 | 높이가 다른 공간 먼지(시차), 원경판, 빛 번짐 후처리 |
| HUD | 절대 좌표, 기본 폰트, 단색 상자 | 흑칠·금장 테마, Pretendard·본명조, 앵커 배치(16:9·16:10·21:9) |
| 화면 흐름 | 브리핑·일시정지·종료 카드 1종 | 타이틀(전투 허브) → 브리핑 → 전투 → 일시정지·설정 → 결과 |
| 입력 | 마우스 | 마우스 + 터치(제안서 §7.2) |

## 파일

```
view/fleet_render/
  battle_source.gd       전투 상태를 읽는 유일한 통로(어댑터). M1 BattleProjection이 정해지면 이 파일만 고친다
  fleet_renderer.gd      함대 대량 표시, 진형 슬롯, 일제 포화, 격침·잔해, 미사일·함재기 연출
  fx_pool.gd, beam_pool.gd                     연출 스프라이트·광선 MultiMesh 풀
  fx_sprite.gdshaderinc, fx_sprite_add/mix.gdshader, beam.gdshader
hud/ui_kit/
  presentation.gd        진입점. FleetBattle3D가 만든다. POC 3D 함대·HUD를 숨긴다(지우지 않는다)
  command_deck.gd        전투 HUD와 화면 전환
  deck_screens.gd        타이틀, 브리핑, 일시정지, 설정, 결과
  tactical_overlay.gd    명패, 선택 괄호, 사거리 부채꼴, 명령선·도착 예상, 터치 끌기 미리보기
  radar_scope.gd         전술도
  battle_pacing.gd       시간 진행: 선택 감속 ×0.2·5초 유휴 해제(Q31·Q55), 조용한 구간 자동 ×4·건너뛰기(Q52)
  rule_text.gd           규칙 값(BattleSource.rules) → 화면 문구. POC 틀과 확정 규칙(v02) 틀
  factions.gd            세력 글리프(촉 蜀·사각, 위 魏·마름모, 오 吳·원)와 색
  order_undo.gd          명령 되돌리기 알림(4초, U2)
  decision_card.gd       결정 카드(§5). 코어 분기가 오면 뜬다. 지금은 자리만
  ui_sound.gd            효과음 훅(사건 이름으로 재생), 음량 버스(Sfx·Ui), 자산이 없으면 합성 임시음
  squadron_strip.gd      전대 띠(U4): 아군 초상 띠. 탭 선택·다시 탭 화면 이동·길게 눌러 추가·끌어서 명령
  session_guard.gd       중단 처리(Q53): 백그라운드·포커스 상실 시 즉시 일시정지
  ui_theme.gd, ornate_style.gd, ui_draw.gd, deck_widgets.gd, screen_kit.gd, commanders.gd, game_settings.gd
input/touch/
  touch_controller.gd    터치 제스처
  hold_tip.gd            길게 누르기 툴팁(명령·시스템 버튼)
  touch_metrics.gd       터치 목표 크기 계산(dp), 모바일 첫 실행 UI 크기
assets/models/fleet_lod/ 저폴리 LOD(재생성: tools/blender/build_fleet_lods.py)
```

M1이 만들 `view/battle_view_3d.gd`, `view/camera_rig.gd`, `view/fx_layer.gd`, `hud/battle_hud.gd`, `hud/fleet_labels.gd`, `hud/radar.gd`와 이름이 겹치지 않는다.

## POC와의 연결 지점(FleetBattle3D.gd, 12줄)

- `signal battle_event(kind, text, fleet_id)`: `add_log`, `toast`에서 1줄씩 발행한다. 교신 기록·컷인·알림 띠가 받는다.
- `_ready` 끝에서 `hud/ui_kit/presentation.gd`가 있으면 만든다. 표현 계층 스크립트가 실패하면 POC 화면이 그대로 남는다.
- 전투 규칙, 난수, 입력 처리(마우스·키)는 바꾸지 않았다. HUD 버튼은 POC 함수(`do_cmd`, `_toggle_menu`, `_group_down/up` 등)를 부른다.

## 입력

| 동작 | 마우스 | 터치 |
|---|---|---|
| 선택 | 클릭, Shift+클릭, 드래그 상자 | 탭, 길게 눌러 추가·제외 |
| 이동 / 공격 | 빈 곳 / 적 클릭 | 아군 함대에서 끌어 빈 곳 / 적 위에 놓기 |
| 끌기 취소 | Esc | 출발 함대 위로 되돌려 놓기 |
| 화면 이동 | 우클릭 드래그, 방향키 | 빈 곳에서 끌기 |
| 확대 | 휠 | 두 손가락 |
| 전대 띠 | 클릭 선택, 다시 클릭 화면 이동, 끌어서 명령 | 탭 선택, 다시 탭 화면 이동, 길게 눌러 추가, 끌어서 이동·공격(띠로 되돌리면 취소) |
| 버튼 설명 | 올려 두기 | 길게 누르기(0.45초). 툴팁이 뜬 뒤 떼면 버튼은 눌리지 않는다 |

### 터치 목표 크기(§7.2, 48dp)

- `tests/touch_targets.gd`가 HUD 버튼 크기를 기준 기기(폰 6.1", 태블릿 11", PC)의 dp로 바꿔 `out/touch-targets.md`에 표로 남긴다.
- 모바일 첫 실행 UI 크기는 `TouchMetrics.pick_ui_scale`이 고른다. 명령 버튼이 48dp에 닿는 가장 작은 배율이되 HUD가 화면에 다 들어가는 배율(화면 1500×680 단위 이상)까지만 키운다. 폰(20:9)은 130%, 4:3 태블릿은 100%.
- 지금 결과: 명령 버튼은 폰 130%에서 49dp, 태블릿 100%에서 71dp로 통과. 시스템 아이콘(44×40)·명령 탭·그룹 탭은 폰에서 25~27dp, 태블릿에서 36~40dp로 모자란다. 데스크톱 배치를 유지한 채로는 더 키울 자리가 없어, 폰 전용 배치(시스템 버튼 접기, 그룹 탭 세로 배치 등)가 필요하다.

터치는 Godot의 마우스 흉내(`DEVICE_ID_EMULATION`)로 HUD 버튼을 누른다. 전장으로 내려온 흉내 이벤트는 `TouchController`가 막아 POC 상자 선택과 겹치지 않는다.

## 테스트

```
godot --headless --path . --script tests/smoke.gd        # 기존 규칙 스모크
godot --headless --path . --script tests/touch_input.gd  # 터치 8항목 + 마우스 클릭
godot --headless --path . --script tests/ui_flow.gd      # 타이틀→브리핑→전투→일시정지→결과→타이틀
godot --headless --path . --script tests/pacing.gd       # Q52 자동 ×4·건너뛰기, Q53 포커스 상실 일시정지
godot --headless --path . --script tests/touch_hold.gd   # 길게 누르기 툴팁, 툴팁 뒤 떼면 명령 취소
godot --headless --path . --script tests/touch_targets.gd  # 터치 목표 크기 표(out/touch-targets.md)
godot --headless --path . --script tests/rule_text.gd    # 화면 문구 규칙 값 = POC 동작, v02 틀
godot --headless --path . --script tests/order_undo.gd   # 명령 되돌리기
godot --headless --path . --script tests/squadron_strip.gd  # 전대 띠
godot --headless --path . --script tests/ui_sound.gd     # 효과음 훅·음량
godot --path . --script tests/capture_ui.gd -- battle res://out/ui-battle.png   # title|brief|quiet|battle|pause|suspend|result
```

측정(Intel Arc 130V 내장 GPU, Compatibility, 1600×900): 표시 함선 약 760척, 60fps.

## 시간 진행과 중단 처리(Q52·Q53)

- **조용한 구간:** `BattleSource.quiet()`가 판정한다. 아군·적 전대가 모두 교전 거리대(미사일·함재기·주포 사거리 중 가장 긴 값 ×1.15) 밖이고 날아가는 미사일·함재기가 없으면 조용하다. 코어의 "알림 분기"가 생기면 이 함수만 바꾼다.
- **자동 ×4:** 조용한 상태가 1초 이어지면 ×4로 바꾸고, 교전이 시작되면 플레이어가 고른 배속(×1·×2)으로 돌아온다. 조용한 구간에서 배속 버튼을 누르면 그 구간 동안은 자동 ×4를 쓰지 않는다. 설정에서 끈다(`user://settings.cfg`의 `play/auto_fast`).
- **건너뛰기:** 우측 상단 ⏭ 버튼. 조용한 구간에서만 누를 수 있고 ×8로 진행한다. 교전이 시작되거나, 경보·적 사건(`sys`, `foe` 교신)이 오거나, 전장·키를 누르면 멈춘다. "다음 분기"는 코어에 아직 없어 교전·경보로 대신한다.
- **상단 상태 문구:** 교전 중 / 정찰 / 정찰 · 자동 ×4 / 건너뛰는 중 · ×8.
- **중단:** `NOTIFICATION_APPLICATION_PAUSED`(모바일 백그라운드)와 `NOTIFICATION_APPLICATION_FOCUS_OUT`(창 포커스 상실)에서 전투 중이면 즉시 일시정지하고, 일시정지 화면에 "자리를 비워 자동으로 멈췄습니다" 안내를 띄운다. 저장(초기 상태 + 명령 기록 + 틱)과 국면별 체크포인트는 코어가 생긴 뒤 `SessionGuard.suspend_requested`에 붙인다.
- 배속은 `BattleSource.set_speed()`로만 바꾼다(POC는 프레임당 시뮬레이션 횟수).

## 컨셉 세션 UI 리뷰 반영(`docs/battle-core/REVIEW-UI-v2.md`)

| # | 처리 |
|---|---|
| U-1 측면·후면 | 문구를 `BattleSource.rules()` 값으로 만든다(`RuleText`). 지금은 POC 규칙("측면 +30%, 배후 +60%")이라 동작과 같다. 코어가 `set = "v02"`를 주면 "측면 명중 +10%p·적 사기 타격 ×1.25, 후면 +25%p·×1.5"로 자동으로 바뀐다. `tests/rule_text.gd`가 POC 리터럴과 대조한다 |
| U-2 사기 | 코어에 사기가 생길 때(M4) bp로 붙인다. 지금은 표시하지 않는다 |
| U-3 방어진형·돌격 | 같은 방식. v02에서는 `has_command("def")`가 거짓이 되어 버튼·단축키 안내·브리핑 줄이 빠지고, 돌격 설명은 "열 용량 40%, 사기 안정일 때만"이 된다 |
| C-1 표시 척 수 | 표시 함선 = 정원 × 고정 배율, 손실도 같은 배율. 화면 숫자는 언제나 실제 척 수 |
| C-2 강조 포화 | 코어의 일제사격 사건이 생기면 붙인다(남은 일) |
| C-3 오 | 吳·원 글리프와 보라 계열 색. 아군 명패에 소유 표시(● 직접 지휘 / ○ 동맹 세력). 세력은 `BattleSource.faction(id)` |
| C-4 성능 | 설정 "함선 표시" 낮음·보통·높음(정원의 35%·60%·85%) |
| Q55 | 선택하면 ×0.2(`Engine.time_scale`), 명령이 확정되거나 5초(실제 시간) 입력이 없으면 해제, 선택 강조는 유지. 설정에서 끈다. UI 연출·입력 판정은 `UiDraw.real_dt`로 실제 시간을 쓴다 |
| U2 되돌리기 | 이동·공격·방어진형 명령 뒤 4초 알림. POC에서는 `BattleSource.restore_orders`로 직전 상태를 쓴다. 코어에서는 "직전 상태로 돌아가는 새 명령"으로 바꾼다 |
| U3 길게 눌러 확정 | 돌격·후퇴는 0.6초 누르면 고리가 차고 실행된다. 짧은 탭은 안내만. 단축키(C·G)는 바로 실행 |
| U8 | 상단 상태 문구에 "접적까지 약 N초", 배속이 바뀌면 반짝임 |
| 결정 카드·"결정 n/m" | 자리와 모양(`decision_card.gd`, 상단 시계 옆). 분기가 없으면 숨긴다. 캡처 `decision`은 견본 데이터 |

## 소리

- 사건: button, tab, confirm(명령), confirm_heavy(길게 눌러 확정), denied(할 수 없음 알림), undo, pause, alert(증원 경보), decision(결정 카드), volley(일제 포화), ship_kill(함선 격침), fleet_destroyed(적 함대 격파), fleet_lost(아군 함대 궤멸).
- 자산은 `assets/audio/ui/<이름>.ogg|wav`, `assets/audio/battle/<이름>.ogg|wav`에 두면 그것을 쓴다. 없으면 코드로 합성한 임시음을 쓴다(외부 자산 아님). 실제 자산은 라이선스 확인과 사용자 승인 뒤에 들인다.
- 같은 사건은 최소 간격(gap) 안에서 한 번만 난다. 경보·결정·아군 손실은 진동도 낸다(§7 접근성: 화면 표시와 짝).
- 설정은 탭 3개(화면·진행·소리). 음량은 전체·전투 효과음·UI·알림음, 움직이는 대로 들려 주고 취소하면 되돌린다.
- 음악은 아직 없다.

## 남은 일

- 사기, 국면, 탄약·에너지·열, 진형 탭: 코어에 값이 생기면 붙인다(목업 v2에 자리 설계가 있다). 지금은 표시하지 않는다.
- 표시 함선 수는 남은 전력 비율을 따른다. 함종 구성은 표현용 배치이고 규칙 값이 아니다. 정본 편성(`data/scenarios/`)과 연결되면 함종 카운터를 읽는다.
- 실제 효과음 자산과 음악(라이선스 확인·승인 필요).
- 강조 포화(C-2): 코어 일제사격 사건이 오면.
- 폰 전용 HUD 배치: 시스템 아이콘·탭·그룹 탭이 48dp에 못 미친다(위 "터치 목표 크기").
- 끌기 중 시간 감속(§7.3), 도착 방향 고리, 경유점: POC 규칙에 없어 넣지 않았다.
- 모바일 실기기, 텍스처 압축(ETC2/ASTC)은 아직 검증하지 않았다.
