# raw 시각 증원 계획 독립 심사

판정: **PASS — raw BattleSim의 단일 시각 증원 경계에 한함**. 심사 계획 SHA256은 `c3836e953ce2c38c6183850aace1e0d850c2a24e36f2b170607949fc60e7a1f8`이다.

- 원문 `_substep`은 시계를 먼저 50ms 전진하고 `clock_ms > R.reinf_ms`를 검사한다. 따라서 100ms에서는 미발동, 150ms에서 발동하고 두 번째 10Hz step 종료 시 200ms다. `_spawn_reinf`는 reinf와 시각을 설정한 뒤 side 1로 roster를 추가하고 spawn 다음 reinforcements 사건을 낸다. 세 번째 step은 reinf latch로 재발동하지 않는다.
- 최초 roster 2개에서 다음 ID 3과 form_counter 2인 조건은 생성 시 증가 규칙과 부합하며, warm cache 갱신과 새 객체 identity, 사건 순서·재발동 부재를 각각 확인하도록 되어 있다. 증원 객체 관련 '생성 직후'는 초기 sim 생성이 아니라 150ms의 증원 생성 직후를 뜻하며, 관찰은 계획대로 둘째 step 종료부터 수행해야 한다.
- 명명된 세 경계와 타입 실패 대조, 실제 종료/marker, 전용 Job 및 SHA/HEAD 보존 조건은 이 좁은 계획에 적절하다. 실제 runner와 입력, 자식 프로세스 및 정확 사건은 실행 후 독립 5b에서 확인해야 한다. 이 PASS는 실행 결과나 제한 owner의 복원 승인이 아니다.

전멸 증원, 일반 95초 전투, host/P02 및 C0/Cn 복원은 미검증이다. P03 NOT_READY 등 기존 상태를 유지한다. 최신 rollout turn_context `01a1ba79-8bf2-7af0-872a-ce5ebe629a36` 모델은 `gpt-6.1-terra`다.
