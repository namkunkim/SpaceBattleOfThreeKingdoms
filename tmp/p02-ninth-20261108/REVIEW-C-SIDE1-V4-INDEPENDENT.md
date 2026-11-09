# C side 1 v4 독립 심사

판정: **조건부 판정기의 정적 보강으로 수용, 실제 oracle·제품 통과는 미승인.** `C-SIDE1-STRICT-V4-REVIEW.md` SHA `5c0a3d1fa3652a47242d4f40799cb38392db6427d809ad82b5213818cdee6e9a`, manifest `20ec67668bbbdcd454dda0be5bb58e1125a0329a869465e4884ec9750179472f`, verifier `b1aa5d5ea31dd991fa547502b929ebe469a7642f1b33d3cd6c704957268294e2`, synthetic log `9573d5227f9fc67d900462a0bcd511ef91b81b603881c201fdb52d661c284f77` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

이전 bool/int 및 70.0 타입 혼동은 `type(value) is int`로 해당 필드에서 거부하며 좌표·offset은 bool과 비유한 수를 거부한다. `detection.gd`의 score 및 zero-view short circuit과 4+12−floor(51/25)=14<15는 기술된 fixture·비음수 EW/은폐·효과 부재 등의 전제 아래 성립한다. 증인 10×(32+192)×2 lane×2 instance=8,960, 초기 80, phase capture 160 산술도 맞다. 다만 실제 fixture 구성과 최초 빈 contact, 주기/모든 `_eval` 직전 raw 상태, capture 및 복원 사이의 연결은 아직 관측되지 않았다. 합성 1 pass/31 reject는 실제 증인이 아니다.

**남은 검증기 한계:** `require_absence`는 capture를 집합 `seen`으로 비교하므로 누락·중복은 거부하지만 capture 순서를 검사하지 않는다. 문서의 160개 capture 순서 검증 주장과 다르다. 정해진 ordered key 목록에 대해 역순/phase 교체 합성 반례를 추가하거나, 순서가 요구가 아니면 문구와 이후 소비자의 순서 계약을 명시적으로 바로잡아야 한다. 증인의 SHA 비교는 외부에서 전달된 문자열과 문서의 동일성을 검사할 뿐 현재 파일의 bytes를 직접 재해시하거나 원본 시점·producer 진실성을 증명하지 않는다. source closure 및 실제 per-eval 생산기/instance identity와 각 receipt를 별도 검증해야 한다. 증인 값을 조작하거나 실제 `_eval`을 누락한 채 가짜 행으로 채우는 공격은 schema/count만으로 차단되지 않는다.

`distance`의 float32 근사와 Godot 실제 빌드 precision·모든 formation offset·sensor 설정 및 skill/chain/terrain 상태를 raw producer와 독립 기준에 결합하고, 빈 offset 또는 조건 미충족·timeout은 실패로 남긴다. certificate는 부재 판정만 제공하며 restore receipt, typed source/target bytes, detach·alias, 사건과 callback의 다른 원래 검증을 대체하지 않는다. fixture SHA가 의미하는 정확한 파일·canonical 구성과 digest 계산을 실행 전 고정한다.

제품 없는 observer/producer의 설계와 합성 반례를 독립 심사하되 제품 fixture를 실제 실행하는 시점은 K6 소진 정의에 따른다. GUI provenance, OS-backed filesystem·Job, B 실제 경로 및 최종 manifest는 미해결이다. K1~K5 이력과 마지막 K6 한 회, P03 및 기존 원문을 보존하고 제품 실행을 금지한다. HEAD lane은 현재 P03 변경과의 결합을 입증하지 않는다.
