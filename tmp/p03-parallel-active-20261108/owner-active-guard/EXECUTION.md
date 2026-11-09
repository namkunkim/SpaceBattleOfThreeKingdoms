# 승인된 DecisionBoard 단독 가드 검증

작업 모델은 2026-11-08T10:21:53Z 로컬 rollout의 gpt-6.1-sol이다. 사용자 승인 hunk는 `core/battle/operation_private_state.gd`의 restore guard 직후, busy 설정/prepare 전 DecisionBoard 검사 2행이다. 기존 busy, unprepared_owner, 활성 오류, 기존 packet 검사 순이다. P02 마감과 공통 owner 기준 SHA AC59…를 확인했고 부모 조율에서 알려진 실행 충돌은 없었다.

- active_decision_valid_packet_refused_preserving_identity
- guard_and_packet_error_precedence
- ordinary_replacement_and_suffix_unchanged
- scenario_packet_atomic_refusal_unchanged
- capture_active_refusal_unchanged

먼저 정상 owner 두 개에 동일 stop→advance→queue(move)를 수행한다. 한 sim에 실제 정본 DecisionBoard와 marker 47을 강제 주입한다. 유효 C0 및 잘못된 packet을 사용해 active·busy·unprepared 우선순위를 검사한다. 직접 읽기 오라클로 identity·tick/clock·pending/events를 검증하고 fixture가 모듈을 정리한 뒤 기존 제한 공개 동작을 무개입 대조군과 비교한다. 별도 기존 owner-contract 사례로 scenario 거부와 정상 restore를 확인한다. 코드 지문 회귀는 이전 owner 지문만 넣은 동일 packet의 code_mismatch를 확인한다.

I01b active replacement 및 P02 headless adapter 기존 검증은 출력 상수 한 줄만 user://로 변경한 전용 복제본을 실행한다. 시작 동결 목록과 소스 원본 사본, 시도별 입력 전후 SHA·HEAD·원문 출력·실제 exit·engine/job 정보를 보존한다. 순차 세 검증 프로세스를 한 시도로 묶고 최대 총 3회다. gate 통과 뒤 독립 Terra 5-b를 요청한다. 제품 도달, 운영 스키마, 전체 원자성은 열린 상태다.
