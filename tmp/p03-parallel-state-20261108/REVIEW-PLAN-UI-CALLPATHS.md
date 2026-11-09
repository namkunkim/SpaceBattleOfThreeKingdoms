# UI 호출·표시 경로 계획 독립 심사

판정: **PASS — 고정 생산 소스의 읽기 경로 조사에 한함**. 계획 SHA256은 `46c944ba0545ece0f3dec8953b6a2bc1f0c16c6c64c63cac3ebcf87130e249f3`이다.

- 기준 정책 원장 SHA 및 user_choice 빈 8개의 정확한 `(행, ui_publish)` 튜플을 독립 대조했다. POST_FILTERED_DRAIN은 선택 축이 있어 제외된다. `FleetBattle3D.gd:344,562–565`는 초기 raw drain과 이후 filtered pump를 보여주며, 동일 사건의 두 번 소비로 해석하지 않는 계획의 구분과 맞는다.
- 각 주장에 현재 소스, 제한 runtime, 범위 내 호출 미발견, 미검증을 구분하고 검색 패턴·파일 집합·동적 경로 한계를 남기도록 한 접근은 적절하다. 정적 호출 순서에서 재진입 안전성이나 제품 복원 연결을 추론하지 말고, 미발견을 전역 부재로 승격하지 않아야 한다.
- 정확 tuple 누락, busy/closed의 미검증 결과 승격 및 anchor 부재 대조는 이 계획의 최소 반례로 적절하다. 소스 후보 집합의 실제 동결, 8행의 연결 경로와 runtime 증거 수준, 별도 선택이 필요한지 여부 및 child exit는 결과 작성 후 독립 5b에서 확인한다. 이 PASS는 해당 경로가 현재 제품에서 실행됐다는 뜻이 아니다.

제품 정책 채택, 신규 UI 실행, 운영 복원 및 반사·외부 플러그인 전체는 범위 밖이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED를 유지한다. 최신 rollout turn_context `01a1ba96-16ad-7ab3-a2cd-cfa23634de69` 모델은 `gpt-6.1-terra`다.
