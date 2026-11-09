# P03 미사일 target ID 잠정 검증 결과

[guard 변경안](GUARD-REVISION-PROPOSAL.md)은 독립 수용 대기다. attempt-01 실제 fixture exit 1, 강제 대조 exit 1, suite exit 1. 3명명·76 확인에서 두 nested 경로 guard가 실패했다. Godot이 돌려준 nested path는 원본과 복원 후 모두 빈 문자열이다.

attempt-02는 canonical enclosing Script의 Missile 상수와 prototype/모든 실제 missile Script의 객체 identity를 대조했다. raw nested path는 그대로 빈 문자열로 기록됐고 enclosing path는 res://core/battle/battle_state.gd였다. 본시험 exit 0, 3명명·76 확인, 의도 실패 실제 exit 1 및 suite exit 0. 기준 변경 독립 수용 전에 시작된 실행이므로 잠정 관측으로만 기록한다.

관측은 미사일 첫 target 2→999 한 경로, 구조 통과, projectile_reference 정확 거부, 기존 sim/state/roster/missile/warm cache·packet·queue/log·events 보존이었다. 원본 양성은 새 객체와 src/target ID 재연결을 확인했다. 다음 틱의 나이 100ms·속도 두 번 +6·ID 및 ordered 사건과 세 패킷이 일치했다. 좌표는 비교 경로에서 exact이며 수기 위치값은 계산하지 않았다.

attempt-02 manifest SHA256 9805d4b93219bb5b9be3b0a54a51bf6781dd9097b186df1f998894ac1b8ff588, 입력 47개 및 HEAD 전후 동일. Git 상태 차이 8행 전부 전용 경로이며 P02·다른 동시 외부 경로 차이는 0이었다. 전체 작업 트리 바이트 검증과는 범위가 다르다. [첫 결과](attempt-01/suite.json) · [잠정 둘째 결과](attempt-02/suite.json) · [raw 경로와 본시험](attempt-02/fixture/stdout.bin) · [Git 상태 대조](attempt-02/git-comparison.json)

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. src 음성, Swarm, 명중·실제 제품 발사 및 운영 복원은 미검증이다.
