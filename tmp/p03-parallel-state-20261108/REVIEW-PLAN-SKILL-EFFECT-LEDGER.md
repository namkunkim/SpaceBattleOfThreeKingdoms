# 기술 효과 원장 계획 독립 심사

판정: **PASS — 고정 시나리오와 생산 소스 범위의 읽기 조사 계획에 한함**. 심사한 계획 SHA256은 `b4fc7e70ed51d5d72ed2150feb0bffa6d51d00afeb812c21d2716a1199eab1b6`이다.

- 적벽 JSON의 `skills` 19개, `effects` 상위 (기술 ID, 키) 33개와 고유 키 24개를 별도로 계수해 계획과 일치했다. `SK-U-GUANYU`의 `assault_bp`도 실제 존재한다. 지정된 생산 GDScript 경로는 93개, 지정 lexical 패턴의 일치 행은 31개이며 detection.gd 94행의 sensor_mul_bp 호출도 확인했다. 이 확인은 모든 값과 소비 경로의 전수 검독을 대체하지 않는다.
- 상위 키와 하위 경로, lexical 행과 실제 접근, 기존 상태 원장의 분모를 분리하고, 직접 소비 근거 없는 키를 UNCLASSIFIED로 남기는 경계가 적절하다. 별도 진입 trace와 파일별 source anchor는 lexical 검색만으로 호출 완전성을 주장하는 위험을 줄인다.
- 정상, JSON 키 삭제, 소비 후보 행 삭제, 필수 입력 부재의 네 대조는 해당 누락 검출기의 수용 계획으로 적절하다. 독립 수기 oracle의 실제 값·순서와 소비 후보·진입 trace, SHA 동결 및 실제 child exit는 실행 후 5b에서 별도 확인해야 한다. 이 PASS는 원장이 작성됐거나 검증기가 동작한다는 뜻이 아니다.

테스트 소스, 동적 경로 및 런타임 호출 전체는 명시된 범위 밖이다. 생산 동작·복원 및 전체 상태 완전성은 입증하지 않으며 P03 NOT_READY 등 기존 상태를 유지한다. 최신 rollout turn_context `01a1ba6c-f4d4-76e0-b8bd-f18164ea8a16`의 모델은 `gpt-6.1-terra`다.
