# P03 운영 owner의 지원 밖 활성 모듈 경계 관측 계획

Sol 실행과 Terra 독립 심사, Astra 제외. P03 전용 fixture로만 수행한다. 공유 코어/host/P02/정본 체크리스트는 읽기만 한다. 계획 수용 전 구현과 엔진 실행을 시작하지 않는다.

우선순위 근거는 operation_private_state.gd:170–175/285–288에서 capture는 활성 DecisionBoard를 명시적으로 차단하지만 restore_completed:354–375는 현재 owner의 일반 guard 후 후보를 준비해 게시하는 경로다. 이 차이가 실제 same-context 교체에서 상태를 버리는지 확인한다. 현재 허용 제품 경로의 도달 가능성은 미입증이다. 활성 모듈을 삽입하는 fixture를 의도적 비정상 입력으로 분류하고 정책이나 수정안을 확정하지 않는다.

1. **supported_control** 동일 생성 입력으로 정상 owner와 대조 twin을 만들고 C0 packet을 캡처한다. 정상 owner를 실제 advance한 뒤 C0 복원 성공, 새 sim identity와 C0 정확 관측, 동일 suffix 재진행을 확인한다.
2. **capture_live_decision** 별도 같은 입력 owner를 실제 한 틱 전진한다. sim에 실제 정본 DecisionBoard를 붙이고 유일한 단일 변이로 표시용 비기본 seq marker를 지정한다. 기존 sim/모듈과 back-reference 및 marker, 코어 관측/사건·대기, ready/busy·C0 입력 보존과 capture의 정확한 unsupported_active_decisions를 확인한다. 삽입은 관측용이며 자연 플레이·복원된 카드 동작의 근거가 아니다.
3. **replace_live_decision** 위 활성 owner에 동결 C0 packet을 넘긴다. 후보 준비를 별도로 확인한다. 정확한 unsupported_active_decisions 거부와 전체 보존은 REJECTED_ATOMIC, 정상 성공 및 새 sim, DecisionBoard 소실 및 정상 C0/동일 suffix는 ACCEPTED_DROPS_ACTIVE_MODULE로 분류한다. 다른 거부·부분 교체·준비/오라클 실패는 절차 실패로 분리한다. 거부 분기에서는 모듈을 fixture가 떼어낸 뒤 기존 pre-restore 코어 상태 기준 정상 후속 호출을 확인한다. 기존 객체/marker 및 input SHA를 비교하고 강제로 붙인 순환 참조를 정리한다.

전용 Godot fixture 및 기존 승인 Windows Job runner 경로, class-map/source 경로와 입력, console/실행 엔진 SHA를 고정하고 전후 확인한다. 실제 exit와 Godot 오류/누수 진단 분리, K6 실제 호출 분모 기록, 사용량 제한 즉시보고·반복 금지. 새 fixture는 shared project 편집 없이 기존 격리 방식으로 실행한다. 범위는 관측 3개, 향후 제품 경로 재현, typed Dictionary 결함 수정, 운영 host/외부 ACK, 저장 스키마 및 전체 모듈 지원은 미결이다.
