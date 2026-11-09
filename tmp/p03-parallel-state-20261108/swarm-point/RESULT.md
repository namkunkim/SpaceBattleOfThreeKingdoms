# Swarm 점 반경 타입 단일 변이 검증 결과

[attempt-01](attempt-01/suite.json)의 suite 실제 exit 0. 본시험 실제 Godot exit 0, 명명 3개·145 확인. 검사기 타입 불일치 대조 실제 exit 1, 확인 1개, 실패 marker 1·성공 marker 0. 두 Job은 각 총 2/active 0, SCRIPT ERROR/ERROR/WARNING/ObjectDB·리소스 종료 진단 0이다.

- launch_and_point_candidate. Swarm 1개와 점 22개, 키 순서 pos/a/r/w, 타입 및 반경 범위, life 9050, ID와 초기 사건 순서를 확인했다. 후보는 첫 점 r 한 경로의 float→int이며 같은 경로에서 정수 절삭을 했다. 패킷 구조 검사를 통과했다.
- positive_swarm_rebind. 원본의 공개 restore가 성공했고 새 sim/state/roster/Swarm/첫 점 객체가 만들어졌다. ID를 새 roster 객체로 연결했고 capture는 원본과 exact 일치했다.
- reject_point_and_advance. 후보는 swarm_point_number로 정확 거부됐다. 활성 sim/state/fleet/Swarm/첫 점 객체, warm 캐시, ready/busy, 패킷·입력 후보·사건과 빈 queue/log가 보존됐다. 다음 틱 100ms에서 life 8950, ID 3, 비명중, 최초 점 각도 두 번 갱신과 반경·속도 유지, 사건 세 건, 세 owner의 전체 capture exact가 일치했다. 독립 위치 수치 대신 각 점이 속한 전체 capture를 대조했다.

초기 및 정상 복원 뒤 중첩 Swarm raw resource_path는 빈 문자열이었다. 실제 canonical enclosing BattleState의 Swarm 상수와 prototype/runtime Script의 객체 동일성을 확인했다. [실제 본시험 로그](attempt-01/fixture/stdout.bin)

manifest SHA256 6946072e124d8a5ead7a3cc2b712c952fdea2d48ccf7e9f9a099d9b29bc53dfc. 선행 guard 기준과 승인·현재 계획·리뷰를 포함한 49개 입력 SHA 및 HEAD 전후 동일. Git 상태 차이 8행 모두 전용 경로이며 P02/동시 외부 경로 차이 0. 상태 비교는 전체 작업 트리 바이트 감사와 별개다. [manifest](attempt-01/manifest.json) · [Git 상태 비교](attempt-01/git-comparison.json)

실제 플레이 발진, 다른 점·참조 변이, 명중·피해, 운영 복원은 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 5b 대기.
