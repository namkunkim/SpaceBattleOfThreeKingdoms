# 첫 PC 난이도 정합 재검증 동결

독립 승인 범위는 focused-normalized-headless-14-only이다. 새 attempt-01에서 before와 after 각각 import 및 D01–D04, D08, D09를 한 번씩 실행한다. 두 import와 12개 테스트, 총 14개 프로세스의 timeout 합은 1,860초다. 재시도는 이 승인에 포함하지 않는다.

첫 시도의 GDScript 파서 오류, focused-01의 D02 비교 오류, type-proof-01의 진단 결과를 각각 보존한다. 타입 진단은 실제 정수와 JSON 실수의 값이 일치하더라도 배열 판정이 거짓임을 재현했다. 이번에는 동일 프로브의 기대 roster 대기 틱과 시작 사기에만 타입·유한성·범위·정수성 검사를 적용하고 int로 정규화한다. 오라클과 제품 후보, 실제값, 비교 및 assertion ID는 그대로다. 기대값 형식이 틀리면 별도 fixture 실패로 중단한다.

before D01/D03/D04는 각각 profile.host, profile.rules, roster.full, roster.wait만 실패해야 한다. 그 외 모든 행의 종료는 0이다. 검사 ID 및 raw 결과, sentinel, Job 정리 및 원문 진단의 기존 게이트를 유지한다. 구문 오류나 raw 결손은 예상 적색으로 세지 않는다.

원본 HEAD/index 및 closure 1,480개, 엔진, 프로브, supervisor 및 이전 진단 증거의 SHA를 고정한다. 시작 여유 2.90 GB 및 진행 중 1.50 GB를 재확인한다. phase 전환에서 재활용하는 것은 이 실행의 새 .godot만 해당하며, 링크·절대경로·400 MB 상한과 두 단계 정리 확인이 필요하다. 이전 실행 기록과 cache는 보존한다.

실제 Windows GUI는 미검증이며 실행 명령이 없다. PC0 기존 2/2를 재실행하거나 새 증거로 집계하지 않는다. 이 자동 검증은 제품 적용이나 최종 인수 승인과 별개다.
