# P02 일곱째 조각 독립 계획 심사

판정: **조건부 수용**. 대상은 기존 `init_game`의 명시 실패 표시와 최초 실패 탈출에 한정한다. 제품 operation 연결 또는 적벽 operation 지원의 인수 근거는 아니다.

## 수정 조건

1. 실패 문구의 예시는 `profile.ally`뿐 아니라 `profile.foe`도 가능한 현재 검증 범위와 일치해야 한다. 중립적인 “함대 편성 데이터가 올바르지 않습니다”를 쓰거나 경로별 정확한 문구를 검증한다. 최초 실패의 실제 두 버튼은 각각 실제 `WorldLink.back_to_world(null)` 및 프로세스 종료 결과를 증명한다.
2. 실제 연결 버튼 행은 `emit_signal`만으로 통과시키지 않는다. GUI 입력을 사용할 수 없다면 해당 실제 입력·가독성 판정은 보류한다. 초기 오류 컨트롤이 host process 비활성 상태에서도 클릭·키보드 작동함을 검증한다. 기존 비모달 경고는 입력을 가로채지 않고 반복 갱신 및 성공 뒤 제거되어야 한다.
3. 정상과 실패 상태의 session, controls, clock, 명령·사건, trace, UI 및 라우팅을 독립 관측값과 사전 기준선으로 비교한다. 새 UI가 사용자에게 보여진다는 사실은 트리 존재만으로 대체하지 않는다. legacy fallback 전후 보존과 별도로 제품 operation이 연결되지 않았음을 기록하고 operation 지원으로 간주하거나 임의 적벽 fallback을 추가하지 않는다.
4. 병행 P03 및 미귀속 파일은 실행 입력·수정 파일과 겹치는지 시점별 해시로 확인한다. 순차 관측은 그 사이의 변경 부재나 변경 주체를 증명하지 못한다. 충돌이 있으면 관련 실행을 보류한다.
5. 구현 5-b 및 마감은 구현과 독립된 심사자가 수행하고, 구현과 5-b의 실제 모델 차이는 권위 있는 세션 turn metadata에서 확인한다. 확인하지 못하면 unknown으로 기록하고 모델 차이를 주장하지 않는다.

## 근거와 한계

현재 `FleetBattle3D.init_game`은 실패를 반환하고 `push_error`한다. 최초 `_ready`는 그 직후 process와 input을 끄고 presentation을 만들지 않는다. `command_deck.begin_battle`, `restart`, `to_title`, `org_screen.start_auto`, `open_org`, `confirm_org` 및 `_restart`의 각 호출은 실패 시 반환하거나 결과를 버리므로 사용자에게 진단이 보이지 않는다. 기존 `_prepare_game`의 시나리오/POC fallback은 레거시 동작이며 operation fallback의 허가가 아니다. 계획은 최초 전용 탈출과 공통 실패 표시를 명시하고, 정상 경로 비교 및 실제 렌더러 확인을 요구한다. 실제 구현 및 GUI는 아직 검증하지 않았다.
