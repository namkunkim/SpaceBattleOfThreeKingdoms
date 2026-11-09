# C side 1 v9 독립 심사

판정: **한정된 합성 case 판정기 조각 수용. 실제 원문 증거·제품 성공·실행 승인은 아니다.** `C-SIDE1-PIPELINE-V9-REVIEW.md` SHA `cd276a5b3af6fbc8aaf92163d1fac4220ea3ab1c5c39209be4409ae75b04832e`, manifest `ef03c3cf6e1b14281bc754ca27ef6c330a9654bf8262075dba8d24b3f658ff68`, verifier `7239af540407d1552fa9c140a6a3f283f03a214418f2878b504888447c9289a5` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job은 실행하지 않았다.

`check_case`는 pin 파일의 SHA와 seed/case 및 typed roster 두 번째 ID를 확인하고 세 phase packet에 동일 context 검사를 필수로 호출한다. 원문 `_detection`의 `a.st.fleets[1].id` 선택과 정적으로 부합한다. 각 phase의 target 전후 외부 projection을 source와 비교하고 phase 간 상태를 이어 검사하므로 v8에서 지적한 대상 위치 변조와 생략 가능한 fixture pin을 이 함수의 합성 실행 범위에서는 해결한다. 실제 승인 SHA는 후보와 독립된 launcher 기록에서 공급해야 한다. 합성 로그의 정상 1·반례 10은 실제 엔진 관측이 아니다.

판정 범위는 context·contact·fleet position의 scoped snapshot이다. 원문 `_all` 전체, packet 변이 후 source/target alias detach, 객체 identity, 이벤트·명령과 fingerprint/suffix는 이 함수의 `external` 비교에 없다. `result`와 packet/state snapshots가 같은 실제 restore 호출에서 생성됐다는 사실도 `check_case` 자체는 입증하지 않는다. v7 원본 stream의 process/run/ordinal·request/result/packet hash 및 v6 causal order, v4 geometry certificate와 사건을 빠짐없이 연결하고, 서로 다른 실행의 정상 snapshot을 조합한 증거·phase/tick 치환·중복·누락을 거부해야 한다. receipt metadata는 비교에서 제거하므로 인과성과 timestamp는 별도 원문 chain이 책임져야 한다.

Decoder는 별도 subset에서 tag·container·field 검사를 하지만 실제 Godot 바이트·typed metadata·StringName 및 float 표현과의 호환은 아직 실측되지 않았다. 승인 pin의 typed context가 실제 정확한 fixture·rules·seed에서 독립 도출됐는지와 전체 파일/engine/overlay closure 및 생성 provenance도 별도다. `approved_pin_sha256`이 외부 매개변수이므로 후보와 함께 그 값을 바꿀 수 있는 호출은 독립 승인이 아니다. fixture의 실제 valid state 또는 metadata/순서가 scoped 모델과 다를 때 false negative가 날 수 있고, decoder unsupported 자료는 실패로 남겨야 한다.

현재 제품 producer, 실제 witness·원시 결과, OS-backed Job/filesystem, GUI provenance 및 21행 최종 manifest는 미구현 또는 미증명이다. 통합 판정기·독립 승인 pin·외부 상태/alias·raw chain 및 부정 사례를 별도 검토한 뒤 실제 fixture는 마지막 K6 안에서만 검증한다. 최초 제품 import 시 K6 소진, K1~K5 및 P03 현재 변경·기존 원문 보호를 유지한다. HEAD 기준 검증은 P03 결합을 보증하지 않는다.
