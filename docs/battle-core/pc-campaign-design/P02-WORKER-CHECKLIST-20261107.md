# P02 제한 CLI worker 체크리스트

- [x] 계획 SHA와 비-Astra 독립 계획 수용. [계획 판정](../../../tmp/p02-next-20261107/REVIEW-PLAN-INDEPENDENT.md)
- [x] 실제 CLI의 명시 `--operation-worker`, 제한된 입력과 기존 `--operation-input` 상호배제, join 후 결과. W1/W2 자연종료와 W3 timeout 및 clock/sentinel 대조.
- [x] 직접 native 요약·사건 순서·타입과 기존 동기 CLI 출력 일치. W4/W6 원본 및 반환 사본 분리, 중복 시작, legacy guard, 미게시 취소, 실패 후 재시작 확인.
- [x] W5 거부 17개 exit 1, 오류·경로 일치, 새 출력 부재 및 기존 target 보존. 기존 부정 CLI 17개 재실행. 이전 세 옵션의 `unknown_option` 분류 편차 기록.
- [x] 기존 동기 출력·통계 바이트 및 P02/private/core/WorldLink 회귀. WorldLink 종료 진단과 전체 diff-check의 기존 33행 실패 기록.
- [x] 시도 1/2 반례 및 시도 3의 입력·실행·보존 SHA 기록. [결과](P02-WORKER-RESULT-20261107.md) · [구현 독립 5-b](../../../tmp/p02-next-20261107/REVIEW-5B-INDEPENDENT.md)
- [ ] 전달물의 독립 마감 판정.
- [ ] 전체 P02/K01~08 및 WorldMap operation 입력·BattleOutcome·진행 표시, UI host, replay. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED.
- [ ] 서비스 보급 완료 E2E, Thread.start OS 실패 주입, 엔진 예외, 디스크 장애, 동시 writer 및 제품 화면·Android·성능 검증.
