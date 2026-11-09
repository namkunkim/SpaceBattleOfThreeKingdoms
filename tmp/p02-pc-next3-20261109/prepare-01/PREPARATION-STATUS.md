# 적벽 직접 출격 난이도 준비 상태

독립 심사에 넘길 격리 후보와 시험 패키지를 준비했다. 원본 제품과 PC0 기록의 변경이나 Godot 실행 및 OS 입력은 없었다.

- before/after/scripts/FleetBattle3D.gd와 candidate.diff. 원본 SHA 029a11be7c08038f2ed4a482f0b2668bd924c842c33a2a671409cd486f0191c9, 후보 SHA 0be6a03729a0906b6170169e607c0d26cb08ae046f9e31785c8862f372b10e81. 적벽 경로는 BattleBrief.PROFILE_DEF로 제한하며, 호스트 난이도 게시를 _publish_game에 둔다. POC는 이전 난이도를 사용한다.
- verify_oracle.py는 두 정본 JSON만 읽고 SHA, 진영/정렬, 조조군 제한, 전대 ID/사기/대기, AI 사전 및 브리핑 선봉을 독립 추출한다. 기존 oracle과 구조 동등 검증을 통과했다.
- source-inventory.json은 직전 동결 경로 1,480개와 관련 엔진·감독기·설정 바이트를 기록한다. 현재 closure 669,710,348 B이며 조사 후 가용 공간은 3,265,716,224 B였다. 이전 closure 대비 4개 경로가 바뀌었다. tracked 런타임 prefix에서 빠진 경로들은 별도 tests이고 manifest에 명시했다.
- p02_difficulty_probe.gd는 D01–D13의 관측/판정 및 물리 입력 수동 관측 코드를 담는다. before는 7개 red 행, after는 전 행 pass가 기대값이다. Godot 구문 분석, 실제 데이터 상태, 버튼 전환 및 진단 수는 독립 검토 후 승인된 시도에서 확인해야 한다.
- EXECUTION-REVIEW-ONLY.json의 SHA는 52cadcb43c6993efb37102275f895ff2c6f7d3318899f1b8b4cafe997759301c다. 29개 계획 행 및 3,720초 timeout 합을 기록한다. runner는 정확한 SHA의 독립 headless-28-only 승인만 받으며 29번째 Windows 행은 미검증과 OS 입력 0건으로 기록한다.
- CUA-PHYSICAL-POLICY.md에 실제 Windows 입력의 별도 승인 범위를 기록했다. 현재 실행 승인 경로에 Windows 입력 코드는 없다. 물리 관측은 실제 생성 Brief seed와 전장 seed를 비교하며 headless 고정 777과 구분한다.
