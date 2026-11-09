# PC0 v2 독립 계획 재심

판정: **준비용 계획으로 조건부 수용, 현재 실행 수용은 보류한다.** `PLAN-V2-PC0.md` SHA `7696a79aeb5a0bb1e9013c006a42f6edf5e382ffdda21bfd3366c3e583d438e9` 확인. 심사 모델 gpt-6.1-terra. 제품·Godot·GUI·Job은 실행하지 않았다.

WorldMap의 실제 버튼→direct FleetBattle3D→자연 terminal→WorldLink 전달을 GUI action으로 확인하는 범위는 첫 PC 우선 목적에 유용하며 강제 종료 smoke·P07 목표/철수·제품 operation 인수와 구분된다. 1,920초의 단계별 합산(180+180+1,440+120)은 맞지만 1,200 논리초가 그 wall-clock 안에 반드시 끝난다는 실측은 아니다. 지연·UI 결정 대기 또는 미완료는 실패/증거로 남기고 빠른 내부 주입이나 승리 변경으로 처리하지 않는다. 실제 time-limit은 `Victory.check()`의 1초 주기, 초기 tick 정렬 및 종결 우선순위까지 비교해 terminal clock을 확인한다.

**실행 전 필요한 구체 수정:**

1. `battle_trace.gd::sample`의 `ui_state`는 UI 상태가 바뀔 때만 기록한다. pause/placing 중 2초가 지나도 같은 상태의 두 번째 row가 생성되지 않으므로 현재의 두 row 기준은 정상 동작도 검증하지 못한다. 같은 sim identity 및 clock/tick을 2초 이상 떨어진 명시적 read-only 관측 두 번으로 남기고 resume 뒤 증가를 확인하는 좁은 probe를 diff·SHA에 추가한다. UI action, sim step/drain/clock 및 이벤트를 변경하지 않아야 한다. 배치 시작/확정도 같은 방법을 적용한다.
2. `FleetBattle3D.issue`의 `command_applied`는 `sim.issue` 직후 기록되므로 그 이름만으로 유효한 수락을 증명하지 않는다. 동일 command/ID와 reject 여부·명령 로그/실제 displacement 및 독립 목표 방향을 함께 판정한다. 유비 기함·입문 controls의 식별과 visibility가 실제 fixture에 부합하는지 기대 원문을 고정하고 모호하면 실패한다. trace의 `fleets()`는 side 0만 수집하므로 적 정보나 숨겨진 상태를 UI/플레이어 관찰로 주장하지 않는다.
3. seed 777 overlay는 실제 버튼을 보존하지만 원본 `make_brief`의 `randi()`를 생략하면 전역 RNG 소비까지 바꿀 수 있다. seed 외 영향이 없는 방식과 변경 diff를 확인하거나 RNG 차이를 명시한 fixture 한계로 분리해 독립 수용한다. callback 위치에서 outcome를 읽기만 하고 추가 `take_outcome`·결산·drain을 호출하지 않음을 검증한다. `battle_end`/result payload의 event 수·clock·손실 원문과 WorldLink 1회 전달을 독립 대조한다.
4. 현재는 manifest·최종 overlay/runner·입력 closure가 미완성이다. read-only 관측 위치, 각 action과 실제 화면·시계 연계, process/window 식별·fresh user/cache·콘솔/자손 종료, timeout 및 사용 중인 다른 창 비침범을 명세하고 독립 재심한다. user data/cache와 screenshots는 전용 경로에 두며, 확인되지 않은 OS 입력 주체의 완전 배제를 주장하지 않는다. 이전 P03 active 보호 상태와 HEAD-based 입력의 차이를 명시하고 P03을 복원하거나 stage하지 않는다.

PC1의 초기 실패/active 실패를 기존 해당 독립 증거로 분리 재사용한다는 범위는 적절하다. PC0은 legacy baseline이며 여덟째 후보 patch를 적용하거나 그 21행 증거로 바꿔 쓰지 않는다. 기존 K1~K5와 마지막 K6을 유지하고 동일 후보를 다른 이름으로 검증해 우회하지 않는다. 이 조각이 통과해도 실제 적벽 operation 연결, P07 목표/명시 철수 및 전체 P02/P03은 별도다. 위 수정과 완전한 실행 입력의 독립 수용 전 실제 GUI/제품을 시작하지 않는다.
