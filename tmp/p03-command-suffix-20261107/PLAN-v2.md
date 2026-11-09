# P03 같은 틱 절단점 계획 보완 v2

2026-11-07 KST. [초안](PLAN.md)의 타임라인, 입력, 보존 조건을 유지한다. 독립 계획 검토가 요청한 수용/논리 적용 구분과 raw twin 독립 입력을 다음과 같이 추가한다. 명명 검사 **6개**, context restore 거부 4건, 구조 명령 거부 2건을 별도 집계한다. K6 사용 0.

- `suffix_06_reject_structure_keeps_active`는 prefix 완성 후 capture 전 실행한다. 중복 ids `[1,1]`을 가진 stop을 `issue`, 필수 `point` 키를 뺀 stop을 `queue`에 각각 전달한다. 두 호출 모두 `{ok:false,error:"invalid_command"}`을 정확히 반환해야 한다. 각 호출 직전/직후 owner handle·sim identity·ready/busy·전체 independent 관측·log/pending/events·명령 입력 타입/순서/값을 비교한다. raw twin에 거부 입력을 보내지 않는다. 정상 capture와 같은 T의 B/R 및 후속 advance가 이어져 다음 정상 호출 가능성을 확인한다. wrapper 성공과 `rejected/no_selection` 사건을 내는 R과 분리한다.
- 독립 raw twin의 명령은 수기 fixture 값으로 각각 새 Dictionary/typed ids를 만들어 raw core에 전달한다. owner caller의 Q 참조를 공유하거나 owner에 전달한 객체를 변이한 뒤 raw에 복제하지 않는다. prefix queue 이후 owner caller의 Q를 변이해도 양쪽 대기 목록이 동결 수기 `[Q,Q,S]`와 일치해야 한다.
- 각 suffix의 첫 advance 후 drain과 바로 이어지는 **같은 상태에서의 빈 drain**을 확인한다. 그 뒤 두 번째 advance 후 drain은 빈값을 가정하지 않고 raw twin 및 이전 suffix 실행과 정확히 대조한다.

Godot 및 runner 미실행. 독립 계획 판정 이후에만 구현한다.
