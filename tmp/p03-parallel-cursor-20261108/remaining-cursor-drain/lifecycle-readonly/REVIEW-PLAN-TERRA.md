# owner lifecycle 읽기 계획 독립 심사 — 변경 요청

대상 PLAN.md SHA-256 `8D2452AC09CE1F4CF077091B74775F1A46E4238E750E80E15850DB37EE1B9130` 확인. 구현·엔진 실행 없이 심사했다.

1. 차별화 범위를 정정해 달라. `tests/p02_viewer_events.gd:232`는 이미 `drain_events_for(false)`의 busy 우선 및 정확한 `{ok:false,error:busy,path:owner}`를 실제로 검사한다. `tests/p02_headless_adapter.gd:323`은 read 계열 busy DTO도 검사하며 `tests/i01b_active_replace.gd:259`는 restore busy를 검사한다. busy+invalid side 전부가 새 검증은 아니다. 이 조각은 11개 진입점의 정적 교차 원장과 guard/DTO 차이 정리로 범위를 밝히고, 위 runtime 사례를 겹치는 근거로 표시하라.
2. 실패 게이트를 명시해 달라. 입력 정본 및 인용 테스트·실행 증거의 정확한 경로와 시작 SHA/크기를 사전에 확정하고 종료에 같은 집합을 대조한다. 누락·읽기 실패·해시 차이·근거 위치 불일치, 고유 행 11 또는 반례 3 부족, 불명확한 DTO가 있으면 원문과 이유를 보존하고 5-a 실패·5-b 수용 금지한다. 동시 P02의 상태를 전체 불변으로 주장하지 않으며 불확실한 기존 runtime 증거는 정적 추론과 분리해 미확인으로 둔다.

대상 함수 11개와 `close` void 예외, create/prepare 제외는 소스와 일치한다. `_guard`는 busy를 unprepared보다 먼저 검사하고 restore는 guard 성공 뒤 prepare하므로 정적 우선순위 원장에 가치가 있다. 이 조사만으로 동시성, 재진입, 외부 ACK를 입증하지 않는 범위도 적절하다. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED 유지.
