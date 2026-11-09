# 복구 trace 보완 독립 판단

판정: **현재 증거는 계획 미충족**. `product-host-atomic-v2.gd:145-154`는 기존 prefix, close/start 개수와 종류, 새 파일 수, seed/hz 및 fleet_state 크기를 확인한다. 각 함대의 control·위치·정체성 등과 trace의 다른 필드가 틀려도 통과할 수 있다. `PLAN-v2.md`의 정규화된 trace와 사전 오라클 비교를 충족하지 못하며, 현재 atomic 10행/546단언 PASS만으로 해당 기준의 완료를 주장할 수 없다.

최소 보완: 고정된 구현 전 프로젝트의 독립 native 동일 입력으로 기존 close와 새 start 오라클을 생성하고 입력·실행·산출물 해시를 보존한다. 구현 후 복구 결과의 두 행 전체를 시스템 시각·monotonic 시각·임시 경로만 정규화해 비교한다. kind/seq/tick/sim_ms 및 모든 data, fleet_state의 각 값·순서·초기 controls, close reason을 포함한다. 각각 prefix 불변, 한 close, 한 새 파일, 한 start 기존 단언도 유지한다. control 또는 좌표 하나를 바꾼 음성 대조가 실패하는지 확인해 비교의 변별력을 입증한다. 동등한 seed/프로필/편성 등의 입력을 명시하고 추가 실행과 단언 분모를 기존 결과와 별도 기록한다. 고정 전 결과가 없으면 새 실행의 시간적 사전성을 가장하지 말고 독립 전 코드 오라클임을 명시한다.

종료 진단은 동일하다고 처리하지 않는다. 현재 기록의 공통 stderr는 before 318 ObjectDB / 18 resources, after 322 / 20; organization은 before 507 / 18, after 511 / 20이다. 숫자 차이와 원인 미확정을 별도로 기록하고 추가 검증 필요성을 독립 5-b에서 판단한다. 위 평가는 전체 구현 5-b나 보존 감사의 대체가 아니다.
