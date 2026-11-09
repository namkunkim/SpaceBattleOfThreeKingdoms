# 직접 출격 난이도 V2 계획 독립 심사

판정: 후보와 독립 시험·실행 manifest 준비 범위 수용. 현재 원본 편집·Godot/Windows 실행은 수용하지 않는다. 후보·probe·독립 기대 JSON·launcher·실제 승인 명령의 바이트가 아직 없으므로 별도 심사에서 정확한 입력과 29 lane 및 실제 입력 안전성을 확인해야 한다. 사용자에게 다시 허락을 요청할 필요는 없다.

ScenarioProfile은 원문 전대를 순회하며 morale_group이 있는 전대만 cao_fleets 수로 제한하고 deploy_delay_s를 wait로 넣는다. BattleSim은 전대를 할당하고 AI는 wait 전이어도 교전 반경 안 적에 반응할 수 있어 제안된 allocated/wait 분리는 타당하다. 9/10/14/14와 suspicion 0.4/0.8/1.5/2.0의 데이터 원문은 앞선 심사에서 확인했다. 독립 Python 추출의 side mapping·정확 ID와 대기 시각 및 생성 JSON SHA를 실제 후보와 별도로 확인해야 하며 기대값 생성에 제품 profile loader를 재사용하지 않는다. D05 실제 유효한 제외 전대와 D11 실제 apply 거부는 fixture 구현에서 별도 확인한다.

invalid routed 적벽 난이도를 명시 거절하는 것은 기존 동작을 바꾸는 한정 정책으로 수용 가능한 제안이다. 기본 POC·standalone 및 데이터 고장 fallback과 혼동하지 않고 오류 표시와 이전 host/sim/seed/G/시계 보존을 검증해야 한다. 초기 G에 state 키가 없을 수 있으므로 존재와 값을 구분한다. 기존 미적용 K6 및 P03 FleetBattle3D hunk와 충돌 여부는 실제 적용 직전 재확인한다.

실제 입력은 소유 Job의 실제 root HWND·전경·client 좌표 및 화면 증거가 모두 확인된 경우만 별도 단일 행으로 고려한다. 초점 변경·SendInput과 실제 수신 기록의 구현 및 기존 사용자 창 비간섭은 아직 증명되지 않았다. 구체 manifest 심사 전 입력하거나 이전 PC0 2/2를 다시 시작하지 않는다. 전경 실패는 입력 0·미검증이다. 앱 viewport와 OS 화면 캡처 및 강제 결산을 구별한다.

29개 timeout은 계획치며 총 벽시계나 1.40GB 저장량을 보장하지 않는다. 현재 공간과 실제 closure/import 증가량, 2.90GB 시작 및 1.50GB 중간 바닥·실행중 증분 위험을 실행 전에 확인한다. 타 사용자 자료나 이전 증거를 정리 대상에 무단 포함하지 않는다. PC0/K6 및 첫 PC 전체 상태는 유지한다.
