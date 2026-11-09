# PC0 실행 준비물 독립 심사

판정: **실행 반려. terminal 판정기의 정상 경로 결함을 수정한 뒤 재심한다.** `REVIEW-MANIFEST.json` SHA `a337f9f3d101520cd5a7081761784befb1dc873be82f6f3649285afbae744961` 및 11개 part hash가 일치한다. source manifest의 1,470 source와 641 generated import 참조, unresolved 0을 확인했다. 심사 모델 gpt-6.1-terra. 제품·Godot·GUI·Job을 실행하지 않았다.

## 실행 전 수정할 결함

`trace-reader.gd.txt`는 `sim.st.over`가 처음 참인 프레임을 terminal point 1로 기록하고 2초 뒤 point 2를 기록한다. 원본 `FleetBattle3D._on_event("battle_end")`는 `end_game`을 호출해 `G.end_t=1.6`을 두고, 종료 화면에 도달하면 `G.state`를 `play`에서 `end`로 바꾼다. `verify.py::stable("terminal")`은 두 표본의 `state`와 `screen`까지 동일해야 한다고 요구한다. 이 UI 전환이 관측 구간 내에 일어나는 정상 경로는 종료 tick/clock이 정확히 정지해도 실패할 수 있다. terminal 안정성은 동일 host/sim/epoch·최소 2초·동일 tick/clock 및 필요한 focus를 확인하고, UI state/screen의 정상 play→end 전환은 별도 `pc0_end_screen` 및 시간 순서로 확인해야 한다. placing/paused의 UI 동일 조건은 유지한다. 정상 terminal의 1.6초 전환을 포함한 hand-authored trace 양성과 tick/clock 변경·sim 변경·end 화면 누락 반례를 실제 `verify_battle` 경로에서 확인한 후 새 manifest SHA로 재심한다.

## 확인한 범위와 남은 실행 검증

- seed overlay는 원본 `randi()`를 한 번 실행하고 그 결과만 덮는다. three-file diff의 결과/시계 관측은 추가 scene 이동·drain 호출을 하지 않는다. 관측이 GDScript에서 parse되는지, 원래 callback/시뮬레이션 및 시간에 부작용이 없는지는 실제 engine 미실측이다.
- `verify.py`는 실제 command request/applied의 동일 ID·log 증가·rejected 부재·move 목표·10초 내 방향/거리와 input trace를 결합한다. outcome의 실제 terminal reason·clock·loss 및 WorldLink publish/consume/display를 별도로 비교한다. `oracle.json`의 timeout tick 12010 / 1,200,950ms는 원본의 tick 선증가, 50ms substep과 10tick 주기에서 정적으로 유도되며 실제 run은 미측정이다. 정지 시점 판단 외 기능의 실제 렌더·행동 및 독립 screenshot/action 원문은 수집 후 별도 5-b가 필요하다.
- launcher는 일반 GUI exe를 suspended 생성하고 정확 HANDLE의 전용 Job assign·membership 이후 resume하며 timeout/abort 때 그 Job만 정리하도록 구현됐다. 현재 Windows에서 assign/로그/`--headless --editor --import` 및 GUI exe stdout 대신 `--log-file`의 print 전달은 미실측이다. 첫 isolation marker 또는 import가 실패하면 제품 action 전 중단한다. expected extra Job member가 있으면 보수적으로 실패하며 기존 사용자 창/프로세스는 종료하지 않는다. tool/session 외부 강제 종료 시 정상 cleanup receipt가 없으면 실패다.
- HEAD source 복제와 새 APPDATA/cache, user:// 사전 관측 및 P03/index/worker 보호를 명시한다. 이 baseline은 현재 active P03 +9 결합 및 여덟째 후보 K6과 다르다. 원본 user/cache 전후 hash는 두 관측 시점의 차이만 검사한다. local screenshots/actions에는 ally 및 실제 렌더만 사용하고 적의 숨겨진 raw를 플레이어 시야로 주장하지 않는다.

이 결함을 고치고 source/overlay/runner/oracle의 실제 SHA, engine/사용자 경로 및 변경 범위 재검증 뒤 재심하면 PC0 실행 가능성을 다시 판정한다. 강제 terminal이나 기존 통과를 이번 자연 종료로 대체하지 않는다. PC0은 legacy 기준선이고 첫 캠페인 작전, 목표/철수, 실제 operation 연결 및 전체 P02/P03 완료가 아니다. 기존 Python K3과 여덟째 K6/21행은 보존한다.
