# P03 Dictionary 컨텍스트 수정 결과

OperationPrivateState._context_same의 Dictionary 분기 한 곳에서 key와 value의 builtin 타입, native class명, script identity를 비교하도록 했다. 기존 Dictionary 순서·재귀와 Array 처리는 유지됐다. Git 미추적 공유 파일의 before 원문과 after를 직접 비교했다. 허용 hunk는 7행 삽입이며 해당 삽입 제거 후 before 바이트와 정확히 일치한다. SHA-256 c555099934bdd0a80f4f4d89100e435e621db6f2f0fe5b98c2be9b2d63619a6e → ac59a7547469c705d33854742e9503b08422770b01956a47861b45735ab8c1c6.

| 실행 | 실제 결과 |
|---|---|
| Dictionary attempt-01 | exit0, 7명명/22입력/314확인. 정확 거부 20, 교체 성공 대조 2 |
| P2c fresh attempt-01 | 30초 timeout, 실제 exit124, 전용 Job 회수, 이전 원문 보존 |
| P2c fresh attempt-02 | exit0, 정상70/11553확인/45거부 |
| Active replacement | exit0, 20/20099/8명명·9거부 호출 |
| Viewer | exit0, 4/47 |
| Same-tick suffix | exit0, 6/91 |

원본 before 13개와 after를 행별 대조했다. Dictionary value builtin/class/script 차이 양방향 6개가 잘못된 수용에서 정확한 replacement_context_mismatch로 바뀌었다. 나머지 7개 판정과 양측 입력 metadata는 일치했다. 추가 key 3축 양방향 6개, 동일 typed key, 역방향 완전 typed/untyped 및 controls 차이를 확인했다. 실패 시 같은 활성 sim과 기존 컨텍스트, pending/log/events, 입력 및 ready/busy를 유지하고 후속 정상 advance에서 pending을 한 번 적용했다.

성공한 다섯 실제 호출의 진단 및 입력 SHA는 각각의 run.json에 있다. K6는 Dictionary 1, fresh 2, active 1, viewer 1, suffix 1이다. legacy runner는 자체 PID 경로를 출력하지 않아 console/body SHA, 정본 실행 인자·버전 및 Job 두 프로세스 accounting을 보존했다. 나머지 runner는 실제 엔진 본체 경로도 보고했다. 기존 전체 diff-check exit2와 신규 파일 및 허용 hunk 검사는 별개다.

P02 revision11/12는 읽기 확인만 했다. P03 구현 범위는 Dictionary 비교 hunk 하나다. 활성 미지원 모듈 처리, host/UI/외부 소비, 저장 스키마와 나머지 전체 체크포인트는 별도다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
