# K6 준비 개정 V2

이 개정은 ORACLES.md의 미구현 항목에 아래 준비를 추가한다. 앞선 manifest와 파일은 별도로 보존한다. Godot, editor import, GUI 입력은 실행하지 않았다.

- 행 5는 제품 _pump가 실제로 소비한 viewer 사건의 독립 typed 사본과 native viewer drain을 비교한다. 이는 별도 계측 overlay이며 승인된 제품 변경과 분리한다.
- 행 6은 실제 장면에 POC profile fixture를 설정하고 init_game에서 새 sim 게시와 고정 seed, 10Hz, 0/1/10/100틱 원문을 검사한다.
- 행 9는 무계측 after 성공·오류 shape를 별도 프로세스로 검사한다. I에서만 진입과 생성 횟수를 검사한다.
- 행 10·13은 새 observer에서 거절 이후 동일 명령·다음 틱의 제품 사건을 비교하고, 원래 accumulator와 RNG 사건 ID도 snapshot에 추가한다.
- suite 계측은 기존 단언 함수에서 typed [label,bool] 행을 출력한다. 동일 문자열의 정당한 반복은 원래 순서와 호출 ordinal을 보존한다. 동결된 실행 전체 목록·분모 및 clean 서막 한 건 편차의 자동 비교기는 여전히 심사 대상이다.
- runner_v2.py는 차단 manifest를 읽고 시작 전에 거절한다. 새 복제, 환경, capture, 상한 및 단언 index를 구현했으나, 연속 foreground/provenance 및 전체 자식 트리 종료가 미검증이라 GUI가 포함된 모든 실행을 거절한다. 행 삭제 우회도 21행 분모 게이트에서 거절한다.

Sky 공식 로컬 API 문서는 target Window, opaque id, capture 및 Promise<void> click/press_key를 정의한다. 노출된 public action 결과는 별도 input source token, OS 이벤트 고유 ID 또는 발생 timestamp를 반환하지 않는다. 같은 전경에 대한 Win32 snapshot과 Godot event 시각의 일치는 보조 근거다. 승인된 출처 구별·연속 전경·혼재 배제 수단이 확인될 때까지 실행 승인 금지 상태를 유지한다.
