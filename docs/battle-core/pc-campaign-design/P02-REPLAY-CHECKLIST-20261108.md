# P02 제한 fresh replay CLI 체크리스트

2026-11-08 KST. 이 체크리스트는 새 제한 CLI 경로만 다룬다. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

- [x] 계획·controls 해석 독립 판정, 구현 전 기준선 7,967개 및 native oracle 동결. [계획](../../../tmp/p02-third-20261108/PLAN.md) · [오라클](../../../tmp/p02-third-20261108/oracle-freeze.json)
- [x] 실제 CLI opt-in에서 명시 순서·경계 틱·전술 거부·자연종료와 명령 소비, native 사건 순서·자료형 대조. [실행 결과](P02-REPLAY-RESULT-20261108.md)
- [x] 명시 []·direct/delegate와 controls 필드 누락, 입력·출력 거부, 실패 시 출력 부재 및 기존 출력 보존. [실제 부정 케이스](../../../tmp/p02-third-20261108/attempt2/results.json)
- [x] legacy·sync·worker 바이트 및 기존 회귀 확인. 2/K6 74/75, 3/K6 BattleFlow 1회 재실행. 진단과 실패 원문 보존. [5-a](../../../tmp/p02-third-20261108/IMPLEMENTATION-5A-NOTES.md)
- [x] 구현 독립 5-b 한정 수용. [판정](../../../tmp/p02-third-20261108/REVIEW-5B-INDEPENDENT.md)
- [ ] 문서·새 ZIP의 독립 마감 판정.
- [ ] 제품 UI host, WorldMap·BattleOutcome, 제품 replay 및 legacy trace, 전체 입력·외부 schema 공동 인수. [P02 진행표](P02-PROGRESS-CHECKLIST.md)
