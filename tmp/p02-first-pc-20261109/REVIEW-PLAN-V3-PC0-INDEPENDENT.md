# PC0 v3 독립 계획 심사

판정: **격리된 manifest·observer/runner 준비 범위에 한해 수용한다. 실제 실행은 완성물 독립 재심 전 보류다.** `PLAN-V3-PC0.md` SHA `3c73b8dbfffb659c2920a9547a52858cda266bae282fb0e8d937ac28dcf0751e` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

V3는 기존 `randi()`를 한 번 소비한 뒤 미지정 seed만 777로 덮어 V2의 추가 RNG 소비 차이를 줄인다. 고정 seed 자체가 의도적 fixture이며 전체 임의 시드와 동일하다고 주장하지 않는 경계가 적절하다. phase별 동일 sim identity·두 시점 clock/tick 및 phase 이탈 시 무효는 변화할 때만 기록하는 기존 ui_state의 공백을 메우는 적절한 설계다. 실제 overlay가 epoch 재진입·placing→running과 pause→running 각각 첫 advancing frame 및 terminal 2초 구간을 기록하는지, 시계·상태·명령·drain을 바꾸지 않는지 diff와 반례를 검토해야 한다. 두 관측 사이 모든 순간의 불변까지 주장하지 않는다.

`command_applied` 단독을 수용으로 보지 않고 동일 ID의 command log·rejected 부재·has_move/목표 및 실제 방향성 있는 displacement와 화면을 함께 요구한 것은 타당하다. 다만 실제 선택·move target의 기존 입력 경로와 `_fit_to_field`의 좌표 변환/field clamp를 정확히 구분하고, 관측자가 raw sim의 입력·출력만 기록해 예상 성공을 스스로 만들어내지 않는지 검토한다. 대상 roster ID·controls의 기대는 동결된 scenario/organization source와 이전에 수용된 기준에서 독립 유도한다. 실제 렌더로 보이는 목표만 선택하고 trace의 side 0 이외 숨겨진 정보를 플레이어 시야처럼 제시하지 않는다.

종결 oracle 보강은 필요하다. 정적 source상 `_tick`은 tick을 먼저 증가시키고 0.1초 tick을 2개의 50ms substep으로 나누며 `_substep`은 clock을 증가시킨 뒤 첫 substep에서만 `Victory.check()`를 호출한다. 따라서 `time_limit=1200`의 최초 eligible 시점은 단순 100ms grid 또는 1,200,000ms로 선결하지 않는다. 정확 initial clock/tick, period, 이전 승패 우선순위 및 end tick/ms를 코드 기반 별도 기대값으로 고정하고 terminal event·outcome·UI와 대조한다. actual battle이 조기 자연 종료할 수도 있으며 그 사유를 우선순위에 맞게 분리한다. 1,920초 wall 상한 및 1배속은 보장된 완료 시간이 아니라 실패 시 종료 경계다.

아직 실제 overlay diff/hash·fixture/input closure, expected roster/deadline, runner의 process/job/GUI 소유 및 오류·timeout cleanup, 화면과 시간표시의 연계가 없다. V3는 이전 Python broker K3 소진 이력과 console-host 관측을 해결했다고 주장하지 않으므로, 선택된 소유 방식이 이전 동일 미해결 경로를 새 이름으로 재시도하지 않게 설계·독립 심사해야 한다. 필요 이상의 전용 read-deny를 새로 요구하지 않되, 새 project/user/cache/log·소유 프로세스만 종료·기존 사용자 창 비침범과 protected HEAD/index/P03/worker 사전후 SHA를 고정한다. GUI 요청과 foreground/HWND/렌더·실제 수신의 원문을 남기고 제3자 입력 완전 배제는 주장하지 않는다.

이 수용은 준비 산출물 구현에 한정된다. 완결된 review-only manifest와 정확 실행 명령·overlay·실제 기대값·유한 정리 계약이 별도 독립 재심되기 전 제품을 시작하지 않는다. 기존 여덟째 후보 K1~K5·K6/21행 및 P03 +9를 보존한다. PC0은 legacy 기준선이며 자동 입력/자연 AI 종결은 사람 플레이·P07 목표/철수·작전 권위 연결 또는 전체 P02 완성이 아니다.
