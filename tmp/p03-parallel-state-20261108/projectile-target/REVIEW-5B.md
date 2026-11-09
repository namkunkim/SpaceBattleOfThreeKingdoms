# 미사일 target 단일 변이 5b

판정: **PASS — 이 한 POC 사례에 한함**. 보존 기록과 runner를 독립 검독했으며 재실행은 하지 않았다.

- 수용 후 attempt-03의 본시험 기록 exit 0, 3개 명명 사례·76개 확인·실패 0, 강제 실패 exit 1과 의도된 marker를 확인했다. 양 Job active 0, timeout과 진단 0이다. 실제 stdout의 초기/복원 후 두 guard 출력은 canonical enclosing 경로와 상수·실제 객체 동일성 true를 기록하며 중첩 raw path는 빈 문자열이다.
- runner는 첫 target의 정수 2→999 한 경로와 구조 통과, `projectile_reference` 거부, 기존 객체·warm cache·packet·입력 및 사건 보존을 확인한다. 양성은 새 roster/미사일과 논리 참조 재연결, 다음 tick의 6개 미사일 age·속도·ID, ordered 사건과 세 전체 packet을 비교한다. 위치는 별도 수기 좌표 oracle이 아니라 세 경로 간 exact 비교다.
- manifest SHA `4d6a25031f9c3fd5a88ef57cfc3920814fce99f0628269f73c7be6b6053ac1cf`와 전후 목록이 일치하며 현재 49개 기록 입력 SHA 불일치는 0이다. 기록 HEAD는 `fb660cea69207fd332e26128643007694910a253`. 실제 runner SHA는 수용된 제안과 일치한다. 이전 guard 심사의 65자리 표기 오기는 REVIEW-GUARD-HASH-CORRECTION.md에 정정했다.
- Git 상태의 전후 차이 8행은 전용 경로다. 이는 무시된 파일이나 기존 dirty 파일의 전체 바이트 불변을 증명하지 않는다. attempt-01 실패와 수용 전 시작된 attempt-02는 이 PASS에 합산하지 않는다.

src 위조, Swarm, 명중 피해, 제품 발사 및 운영 복원은 범위 밖이다. 기존 광역 런타임 반려와 P03 NOT_READY 등 상태는 유지한다.
