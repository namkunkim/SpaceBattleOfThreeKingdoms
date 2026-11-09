# cursor/drain 실제 네 번째 실행 인계

attempt-05의 종합 5-a는 PASS다. 실제 Godot 실행 4회/K6이며 attempt-04는 사전 중단으로 엔진을 실행하지 않았다. 이번 승인에서 실제 실행은 한 번이었다. 이전 attempt-01~03의 실패와 attempt-04 사전 중단 기록을 유지한다.

Godot actual exit 0, 정확한 네 명명과 고유 단언 32개 PASS, SCRIPT ERROR/ERROR/WARNING/누수 진단 0, timeout 없음이다. 엔진 본체 PID 31576과 console launcher PID 37120을 구분했고 Job active 0/total 2였다. 종료 후 보호 범위 재해시 시간도 launcher elapsed에 포함된다. 실행 직전 두 차례 Godot 부재와 두 trace 목록·해시 일치, 승인 계획과 launcher/출처 어댑터의 SHA를 확인했다.

동결 입력 141개의 시작과 종료 목록·SHA·크기가 동일하다. 재귀 보호 목록의 시작·종료 내용과 같은 HEAD, 시작·종료 status 경고 0, 예약 밖 status 변화 0 및 보존 오류 0을 확인했다. 허용 부모의 신규 trace는 0이다. 따라서 신규 P02 trace 귀속을 시도하지 않았고, 기존 파일명의 PID를 독립 증거로 사용하지 않았다. 보호 분모 및 실행 원문별 SHA는 ATTEMPT-05-5A-AUDIT.json에 기록했다. 이 전후 증거는 미관측 순간 변경이나 보호 범위 밖 전체 트리 불변을 입증하지 않는다.

네 제한 시나리오는 정상 pending/suffix, pending 재주입, suffix 순서 변경·누락, P/D 복원 후 외부 Array 수신이다. 제한 runtime 관측이며 실제 운영 host ACK나 커밋·idempotency 계약을 입증하지 않는다. Terra 독립 5-b와 마감 대기다. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
