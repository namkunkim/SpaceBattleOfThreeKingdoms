# P03 명령·cursor 인수 우선순위

1. cursor/drain 기존 실행 조각의 보존 판정이 선행이다. 실제 3회/K6, attempt-03 Godot exit0/32 PASS는 종합 5-a 미통과로 유지한다. 04 사전 중단은 엔진 실행으로 집계하지 않는다. 재개에는 독립 보존 게이트 수용, 새 동결 입력·보호 범위 감사, 실행창과 독립 P02 trace/PID 증거 또는 해당 변화 없는 증거, 그리고 별도 실행 승인·5-a·5-b가 필요하다. 기존 P02 trace 두 건의 경로·SHA와 독립 PID 부재는 RESULT-P02-PID-BLOCKER.md를 따른다. P02 중단을 요구하지 않는다.
2. 별도 정적 조각으로 packet의 log/pending/event **검증 강도**를 조사한다. 기존 suffix 검사는 이미 보유한 pending과 이후 명령을 어떻게 실행했는지를 다뤘다. 이 조각은 candidate가 어떤 행·시간·순서를 검사하고 어떤 정보를 기존 state와 상호 검증하는지를 대조한다. 읽기 원장 계획은 command-packet-integrity/PLAN.md다.
3. 이후 운영 계약 인수는 정본 H2/D04/I01의 명령 접수·적용·완료와 pending/suffix 절단점에 대해 소유자 간 결정을 먼저 확보한다. 완료 증거는 정상·중복·누락·재정렬·거부·종료 경계에 대한 실제 복원 후 동일 suffix, 독립 상태 및 순서 사건 오라클, 기존 host와 게시 효과 보존이다. 외부 저장 스키마, seq/commit/ack/idempotency 및 전역 cursor는 별도 소유·계약·증거가 필요한 미결이다.
4. 공개 owner lifecycle 11개 진입점의 guard 및 DTO 차이는 별도 제한 정적 원장과 독립 심사의 범위에 둔다. 이 근거를 운영 계약 또는 packet 내부 명령 이력의 유효성 검증으로 승격하지 않는다.

전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED. 공유 파일은 읽기만 한다.
