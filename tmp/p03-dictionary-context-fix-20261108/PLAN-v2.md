# P03 Dictionary context 수정 계획 보완 v2

2026-11-08 KST. [PLAN.md](PLAN.md)의 표는 **변경 후(after) 계약 기대값**이다. 단계1 현행 소스(before)는 정확 거부·활성 무변이/후속 advance와 실제 수용·교체를 별도 관측 결과로 기록한다. 현행 소스의 절차 완료를 계약 통과로 집계하지 않는다. 바뀐 소스의 conformance gate에서만 표의 모든 격리 metadata 차이의 `replacement_context_mismatch` 거부를 요구한다.

각 방향/대조군의 정상 create, capture, 독립 prepare, 입력→packet→prepare에서 metadata 불변, 단일 변수 전제 및 독립 오라클까지 확인해야 표본으로 집계한다. 실패는 절차 실패이며 MATCH/MISMATCH나 관측 완료로 분류하지 않는다. 정확한 명명 거부가 아닌 거부도 절차 실패다. 받아들인 결과는 실제 새 sim 교체 및 독립 준비 상태 일치·원 context와 packet 보존을 확인한 때에만 MISMATCH다.

단계1의 13개 실제 논리 입력은 동일 대조군 1, Dictionary value 차이 6(세 축×두 방향), 기존 context 대조 6이다. value 차이 6 중 기존 단방향 builtin 재현 1과 새 검증 5를 분리한다. 6개 기존 controls는 신규 결함 관측 분모에 넣지 않는다. 방향·프로세스·assertion 분모를 별도로 기록한다. 공유 수정은 P02 소유권 합의 및 독립 계획 수용 전 금지다.
