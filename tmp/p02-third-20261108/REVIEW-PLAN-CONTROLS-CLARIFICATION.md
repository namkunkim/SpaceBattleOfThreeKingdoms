# 계획 문구 정정 독립 판정

2026-11-08. `PLAN.md` SHA-256 `4fe0b4d9137934ecba7d08401fa116ecf138ddc83dbca4db2d1ffc05ce122f9e`의 계약 1항 중 “factory 기본값 []”은 오해의 소지가 있다. 실제 `operation_runtime_adapter.gd`의 `FIELDS`에 `initial_controls`가 필수이고 `normalize`는 누락을 `missing_field / initial_controls`로 거부한다. 빈 배열을 명시하면 유효한 값으로 받아 private factory에 그대로 전달한다.

기존 input을 변경 없이 factory에 한 번 전달하고 factory 오류 path에 `input.`을 붙이는 계획의 명시 계약을 우선 적용한다. 따라서 `initial_controls: []`는 허용하고 키 누락은 `missing_field / input.initial_controls`로 거부하는 해석을 수용한다. 새 기본값 삽입이나 adapter 변경은 허용하지 않는다. 명시 빈 배열 성공과 누락 실패를 각각 실제 CLI 프로세스에서 검증하고 오류 출력 및 출력 파일 부재를 기록해야 한다. legacy replay와 비교할 기본 controls도 누락이 아닌 명시 `[]`로 표현한다. 이 정정은 계획의 지원 범위를 넓히지 않는다.
