# C side 1 v8 독립 심사

판정: **v7의 두 합성 의미 결함에 대한 보강을 수용하되 실제 제품 oracle/실행은 미승인.** `C-SIDE1-SEMANTICS-V8-REVIEW.md` SHA `5bf9deb68475ce4b9ddf04f046dfa5aa06f56193a2eee4ed07f0dd5ec1b903ca`, manifest `b84d71a51b16c513e08c46f65ed4a86aafc19dda1d61925b2ad47428b1705b0b`, verifier `694f410424817d3579c1daa72572a5492b73f892c5ca12b99791f4309943281b` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

별도 typed decoder를 통해 packet과 live의 side 1 contact를 실제 decoded 구조에서 확인하고 `records: []`와 대조하므로 v7의 별도 빈 JSON만으로 숨긴 contact를 통과시키는 문제를 합성 subset에서 해결한다. Wrong-position packet은 source live의 선택 ID 위치를 제외한 모든 구조·순서를 유지하도록 기대값을 만들어 비교한다. 기존 v7처럼 임의로 다른 packet이면 되는 문제도 합성 범위에서 해결한다. `capture_partial`의 네 envelope key와 context 필드·record 필드는 source와 정적으로 양립한다. 11건의 거부와 정상 변형은 보존 로그의 합성 결과다.

완료 경계는 좁다. `verify_fixture_identity`는 별도 함수이고 v7 이벤트 pipeline 또는 `bind_capture`에서 자동 호출되지 않는다. 독립 승인된 exact context가 누락되거나 후보가 제공한 context로 검증하면 packet/live 동시 fixture 치환을 막지 못한다. 선택 contact ID도 호출자가 제공하므로 독립 roster 순서 및 원문 fixture의 상대 ID와 연결해야 한다. 각각 누락·거짓 pin·ID 치환 반례를 최종 판정기의 필수 경로에서 거부해야 한다. `bind_wrong_control`은 대상 contacts를 비교하나 대상 `fleet_positions`와 source의 일치를 요구하지 않는다. contact 변화 이외 target 위치 변조는 이 함수 단독으로 통과할 수 있으므로 실제 원문의 external-state/atomicity 단언과 연결하고 해당 반례를 둔다. 실제 값 구조뿐 아니라 capture 후 element 변경과 identity detach/alias는 별도 실측이 필요하다.

Decoder는 지원 subset을 벗어나면 거부하도록 설계됐으나 실제 Godot fixture byte 및 typed container/header·StringName·float width에 대한 엔진 교차 검증은 없다. 정확한 variant type과 구조를 받아도 원래 bytes의 모든 직렬화 표현 차이를 보존하는지 별도로 확인해야 하며, 미지원 실데이터는 실패로 남긴다. `receipt_metadata`와 envelope 순서 차이 허용은 scoped 비교의 의도된 경계다. 이 범위는 원문 `_all`의 전체 비선택 상태 불변을 대체하지 않는다.

v8은 v7 원본 사건 pipeline에 통합되지 않았고, 실제 producer·raw source/target 순서·geometry witness·독립 fixture context·승인 closure·OS-backed filesystem/Job 및 Sky 입력 귀속은 미증명이다. 통합 후 hidden contact, wrong field, target external-state 변조, joint fixture 및 decoder boundary 반례를 필수 게이트로 묶고 독립 심사해야 한다. K6은 최초 제품 import부터 소진되는 마지막 1회를 유지하며, 현 조건에서 시작하지 않는다. P03 현재 변경과 기존 산출물·K1~K5 기록을 보존한다.
