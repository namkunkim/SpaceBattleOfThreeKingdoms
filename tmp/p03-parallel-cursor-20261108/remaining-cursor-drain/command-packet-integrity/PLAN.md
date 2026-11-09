# 제한 checkpoint의 명령 이력 검증 범위 읽기 계획

Terra 심사 전 조사 구현과 엔진 실행 없음. 범위는 owner가 in-memory packet을 검사·복원할 때 command_log, _queue, _events를 어떤 책임으로 확인하는지에 대한 정적 읽기 원장이다. 기존 명령 suffix는 정상 checkpoint 이후 실제 재개, cursor/drain 시도는 뒤쪽 suffix 실험, lifecycle 원장은 진입 가드와 오류 DTO를 다뤘다. 이번에는 packet validator와 복사·관측 일치가 **각 이력 항목의 정합성을 어떤 수준까지 판정하는지** 분리한다.

정본 입력 후보는 operation_private_state.gd의 _command_error, _packet_error, prepare, _restore, _context_same, restore_completed, operation_service_state.gd의 _same/_data, battle_sim.gd의 queue/issue/step/emit, operation_replay.gd의 fresh 소비, I01 K05~K07 및 D04 ST02/ST18이다. 이전 suffix·fresh 결과·lifecycle 원장을 겹치는 범위 근거로 쓴다. 조사 시작에 실제 인용 경로, SHA-256 및 크기를 확정하고 종료에 같은 집합을 대조한다.

정적 원장은 6개 고유 행을 등록한다. log 명령 구조, log 시간, pending 구조/입력 tick, event 구조/시간, 컨테이너 복사·관측 일치, 행 순서와 state/이력 상호 대조다. 각 행은 코어 생성 규칙, candidate의 검사 위치, 정확 거부 값 또는 이 검사에서 검증하는 조건의 범위, 관련 기존 실행 증거를 구분한다. 별도 반례 3개는 유효한 두 log 행의 역순, 형식상 허용되는 미래 입력 tick의 pending, 자체 형식과 시간 범위가 맞지만 log와 인과 관계가 확인되지 않은 사건이다. 명시된 guard 통과 가능성은 소스 추론으로만 남기고 실제 후보 전체의 수용이나 결함으로 판단하지 않는다.

5-a는 6 고유 행·3 반례와 근거 위치·기존 실행 범위, 같은 SHA/크기 집합을 요구한다. 누락, 읽기 실패, 입력 차이, 근거 불일치 또는 검증 위치를 특정할 수 없는 경우 원문·사유를 보존하고 실패로 남긴다. 5-b는 별도 Terra가 validator 경로와 기존 증거를 교차 검토한다. 제품의 이력 신뢰 정책이나 외부 형식은 정하지 않는다. 신규 실행 조각이 필요하면 별도 계획·승인·보존 게이트를 요구한다. 기존 cursor/drain 3/K6과 5-a 미통과를 보존한다.
