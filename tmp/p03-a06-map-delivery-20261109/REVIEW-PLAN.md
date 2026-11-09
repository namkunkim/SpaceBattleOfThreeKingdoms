# A06 지도 표시 계획 독립 심사

판정: **조건부 수용**. PLAN SHA-256 `9b3f07115814f7851fd78e369274bb81dffe8e92a60b80de744b4b061e388dd3`. `take_outcome` 슬롯 소비 후 `_show_result`가 즉시 결과를 표시하고 0.6초 뒤 `state == result`일 때 canvas 소유 상태를 갱신하는 원문을 확인했다. `data/scenarios/base/world_208.json`의 RGN-02 초기 소유는 contested이고 승리 결과 중 wu 변경이 있다. runner는 선택한 DTO kind가 정확히 해당 매핑을 선택하는지 명시하고 검증해야 한다.

정상/타이머 전 버튼 이탈/슬롯 소비 후 재진입 3개와 15개 단언은 기존 정상 성공 시험과 차이를 만든다. timer 예약과 이탈 시각을 기록하여 이탈이 실제 0.6초 이전임을 확인하고, 실제 결과 버튼 연결 신호를 사용하며 결과 UI의 visible 대상과 DTO seed를 직접 검증하라. 재진입의 초기값은 새 scene의 world 데이터에서 생기는 canvas 값이며 재전달이나 권위 저장·재시도 보장이 아니다. 0.7초 대기는 timeout과 프레임 처리를 포함하여 검증한다.

실제 scene 및 WorldLink autoload의 canonical resource_path와 경로별 SHA, engine/class map/fixture, 별도 사용자 데이터, 실제 exit 및 오류·종료 진단을 보존한다. 필수 canonical guard 실패 시 성공 표식을 내지 않으며 K3은 실패를 포함한 총 실행 수이고 첫 실패를 보존한다. 초기·목표 차이, 동등한 DTO, 버튼 연결, 실제 타이머 만료 및 각 사례 격리를 실행 근거로 확인해야 한다. 픽셀·애니메이션 완료, 내구 저장, ACK, 패킷 재전달 및 운영 A06 완료는 주장하지 않는다. 구현과 독립 5b는 별도다.
