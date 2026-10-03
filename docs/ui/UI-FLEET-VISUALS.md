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
  ui_theme.gd, ornate_style.gd, ui_draw.gd, deck_widgets.gd, screen_kit.gd, commanders.gd, game_settings.gd
input/touch/
  touch_controller.gd    터치 제스처
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

터치는 Godot의 마우스 흉내(`DEVICE_ID_EMULATION`)로 HUD 버튼을 누른다. 전장으로 내려온 흉내 이벤트는 `TouchController`가 막아 POC 상자 선택과 겹치지 않는다.

## 테스트

```
godot --headless --path . --script tests/smoke.gd        # 기존 규칙 스모크
godot --headless --path . --script tests/touch_input.gd  # 터치 8항목 + 마우스 클릭
godot --headless --path . --script tests/ui_flow.gd      # 타이틀→브리핑→전투→일시정지→결과→타이틀
godot --path . --script tests/capture_ui.gd -- battle res://out/ui-battle.png   # title|brief|battle|pause|result
```

측정(Intel Arc 130V 내장 GPU, Compatibility, 1600×900): 표시 함선 약 760척, 60fps.

## 남은 일

- 사기, 국면, 탄약·에너지·열, 진형 탭: 코어에 값이 생기면 붙인다(목업 v2에 자리 설계가 있다). 지금은 표시하지 않는다.
- 표시 함선 수는 남은 전력 비율을 따른다. 함종 구성은 표현용 배치이고 규칙 값이 아니다. 정본 편성(`data/scenarios/`)과 연결되면 함종 카운터를 읽는다.
- 효과음·음악 없음(훅 없음).
- 터치에서 명령 버튼 툴팁(마우스 올림)이 뜨지 않는다. 길게 누르기 툴팁이 필요하다.
- 끌기 중 시간 감속(§7.3), 도착 방향 고리, 경유점: POC 규칙에 없어 넣지 않았다.
- 모바일 실기기, 텍스처 압축(ETC2/ASTC)은 아직 검증하지 않았다.
