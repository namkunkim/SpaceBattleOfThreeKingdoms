# Swarm 점 타입 단일 변이 5b

판정: **PASS — 첫 점 r의 float→int 단일 사례**. 보존 실행 증거와 runner를 검독했으며 독립 재실행은 하지 않았다.

- 본시험 기록 exit 0, 3개 명명·145개 확인·실패 0, 강제 타입 실패 exit 1 및 의도된 marker를 확인했다. stderr는 비고 Job active 0, timeout·진단 0이다. 초기 및 복원 후 canonical BattleState의 Swarm 상수와 실제 Script identity는 true이며 raw 중첩 경로는 빈 문자열로 보존됐다.
- runner는 점 22개의 키·타입·범위, 첫 r의 정확한 단일 경로 변이, 구조 통과와 `swarm_point_number`, 기존 객체·첫 점·warm cache·입력 및 packet 보존을 확인한다. 양성은 새 roster·Swarm·첫 점의 논리 참조와 packet exact를 검사한다. 다음 틱은 life 8950, 첫 각도 두 번 갱신, 사건 및 세 packet을 대조한다. 점 좌표 수치의 독립 정답을 주장하지 않는다.
- manifest SHA `6946072e124d8a5ead7a3cc2b712c952fdea2d48ccf7e9f9a099d9b29bc53dfc`, 전후 입력 목록과 현재 49개 입력 SHA가 일치한다. HEAD 기록은 `fb660cea69207fd332e26128643007694910a253`. Git 상태 차이 8행은 전용 경로이며, 이 비교는 무시된 파일 및 기존 dirty 파일의 바이트 불변을 입증하지 않는다.

다른 점·참조 변이, 실제 플레이 발진·피해와 운영 복원은 미검증이다. P03 NOT_READY 등 기존 상태를 유지한다.
