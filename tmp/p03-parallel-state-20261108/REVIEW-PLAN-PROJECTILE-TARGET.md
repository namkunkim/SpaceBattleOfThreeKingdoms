# 미사일 target ID 계획 독립 심사

판정: **PASS — POC 미사일 target 단일 변이 조각에 한함**. 심사한 계획 SHA256은 `9d9925d3ba55c00226d4140801e2b73bf690603bf4470237d884d5482df6928c`이다.

- `_fire_missiles`는 먼저 발사 event ID 하나를 소비한 뒤 6개 미사일 각각에 새 ID를 붙이고 launch 사건을 발행한다. 1에서 시작하면 ID 2~7 및 다음 ID 8이라는 기대가 원문과 일치한다. 10Hz 두 하위 걸음에서 age는 100ms 늘고 `missile_accel=120`에 따라 속도는 각 걸음 6씩 늘어난다. 적 기함의 첫 AI 평가가 event ID 하나를 소비하는 조건은 이전 clock 조각과 같다.
- 구조 검사 통과와 단일 정수 변이, 정확한 `projectile_reference` 거부 및 기존 객체·warm cache·packet·대기/사건 보존을 명시했다. 원본 P의 양성 복원은 새 roster와 미사일 객체, 논리 ID 연결 및 전체 packet을 확인한다. 다음 전진은 독립 age/속도·ID oracle과 세 owner exact 비교를 함께 사용하며 좌표를 수기 정답으로 과장하지 않는다.
- 의도 실패 프로세스, 실제 종료/marker, canonical 경로·Job과 전후 입력 동결은 계획 조건으로 수용한다. 중첩 Missile의 실제 script resource_path 표현은 실행 환경에서 원본과 대조하되 경로 형식을 추정해 우회하지 말고 실제 runner 및 로그를 사후 확인해야 한다. 실제 입력 및 의존성 동결, marker와 owner 분기 도달은 별도 독립 5b에 남는다.

src 위조, Swarm, 명중 피해, 실제 플레이 발사 및 운영 복원은 범위 밖이다. 이 PASS는 실행 성공이나 전체 projectile 안전성을 뜻하지 않으며 P03 NOT_READY 등 기존 상태를 유지한다. 최신 rollout turn_context `01a1ba72-dee8-79f3-9ca7-a70829e7dc13` 모델은 `gpt-6.1-terra`다.
