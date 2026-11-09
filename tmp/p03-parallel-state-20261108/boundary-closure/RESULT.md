# K06/K07 경계표와 A06 인수표 결과

[경계 원장](boundary-matrix.json)은 계획이 분해한 12개 경계에 owner/host, UI 게시, 외부 효과 전달, durable/cursor의 4개 책임을 붙였다. 48개 셀은 SUPPORTED_EVIDENCE 10, REJECTED_EVIDENCE 3, POLICY_REQUIRED 24, UNCLASSIFIED 11이다. 각 셀의 근거는 현재 확인 범위와 관련 원문을 가리킨다. 정적 지원 표시는 해당 경로의 코드 책임이며 운영 실행 승인을 의미하지 않는다. raw/filtered drain은 동일 큐의 대안적 소비다. [A06 조합](A06-ACCEPTANCE.md)은 단일 미실행 인수 조건으로 별도 유지했다.

| 사례 | 실제 exit | 판정 |
|---|---:|---|
| normal | 0 | 12행·48셀, 4열, A06 조건, cursor 판정 일치 |
| row_omission | 1 | QUEUE_RETURN 한 행만 누락 |
| cursor_misclassification | 1 | attempt-03의 공식 미통과를 지원 증거로 올린 변이 거부 |
| missing_anchor | 2 | 근거 경로 부재, 정상 비교 출력 없음 |

[실제 suite](attempt-01/suite.json) exit 0, 네 사례의 실제 종료·argv와 stdout/stderr 보존. 이번 5a는 존재하는 근거, 분모, 허용 disposition 및 지정 차집합 검사다. 셀의 의미나 정책 결정은 독립 사후 대조 대상이다.

동결 manifest SHA256 0fcd7988b794f1d8bd16c88770bc98a266a09de553cb0cfe13604d2641459201. 20개 입력 및 HEAD 전후 일치. [Git 상태 비교](attempt-01/git-comparison.json)의 차이 10행은 모두 이 전용 경로이며 P02·동시 외부 경로 차이는 0이었다. 이 비교는 전체 dirty 파일의 바이트 감사를 포함하지 않는다.

추가 Godot 실행, 운영 복원, 외부 cursor/ack/idempotency, 제품 게시 정책 및 공유 체크리스트 변경은 없었다. 기존 cursor 실행 판정 유지. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 5b 대기.
