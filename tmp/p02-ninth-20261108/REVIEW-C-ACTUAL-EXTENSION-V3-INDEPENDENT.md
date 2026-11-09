# C extension v3 source·합성 독립 심사

판정: **이전 v2의 두 결함을 좁은 정적/단위 범위에서 보완한 조각은 수용한다. 통합 5-b 및 실행은 미승인이다.** `c_actual_extension_raw_v3.py` SHA `03ff2a2c4bdf6786f084331b3d4b08a806cd4e023be77a14ea015ea1657534ea`, unit `95cb013f460e36312dbfa4b71f2dcbdf0610bece7ce40ef86967b9f75cf025da`, 독립 representative template `b0c53d6492a7743e5d73b829d8e702a455a4f3cf5624fbe9da924aaa25e267b3` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

v3는 packet mutation·alias state 및 suffix의 지정 필드에서 decoder Variant node를 그대로 비교해 container metadata와 dictionary key 순서를 보존한다. 기존 v2 `plain`의 전면 손실은 이 검사 경로에서 보완됐다. 그러나 나머지 `case_base`·`check_case`는 여전히 `plain`을 사용하며, decoder는 scalar wire 폭/flags를 반환 구조에 보존하지 않는다. 따라서 전체 raw bytes·모든 필드의 wire 수준 동등성이나 원래 `_plain`이 의도적으로 지운 타입까지 검증한다고 말할 수 없다. 원본 packet bytes와 semantic Variant type/metadata, `_all`의 의도된 plain 범위를 각각 명시하고 필요한 wire 차이의 별도 검사·반례를 둔다.

`split_stdout`은 동일 raw bytes에서 base/supplement line offset과 SHA, stream ordinal 및 receipt의 run/lane/PID 정보를 연결하고 base 기존 `evidence` offsets와 재대조한다. v2의 별도 prefix 전용 입력에 raw 출처가 없던 결함을 정적으로 해결하는 방향이다. receipt는 독립 소유/launcher 증거가 자동으로 생성한 것이 아니며 외부 승인 SHA를 호출자가 주는 신뢰 경계는 그대로다. 실제 line flush·프로세스 identity, 재사용된 run/조작된 receipt 및 혼합 stdout 전체의 진단·크기/시간 제한은 별도다. 알 수 없는 일반 stdout line은 허용되므로 최종 suite 판정기는 예상 출력과 오류를 별도로 검사해야 한다.

unit 원문은 typed 차이 5개 거부, splitter 정상 1개 및 ordinal/중복/미종결/잘못된 prefix 4개 반례를 담는다. hand-authored 전체 case·실행 결과가 아니다. 독립 representative template은 runtime 값·events·fingerprint·identity 및 oracle 승인이 `null`/미해결로 명시돼 있으며 올바르게 실제 oracle로 취급할 수 없다. `verify_lane`은 empty cases 또는 provenance 누락을 거부하도록 설계됐지만 20개 동적 pin, 11개 통합 negative 및 동일 잘못된 producer/oracle·외부 state/alias/suffix event 반례 전체는 아직 없다. base/v9/geometry·actual source/owner 결합도 미완료다.

다음 유효 작업은 독립적으로 hand-authored 단일 경계 transcript와 각 반례의 실패 지점/해시를 고정해 v3의 실제 통합 진입점으로 검증하고, 전체 lane의 dynamic oracle을 확보할 수 있는지 먼저 판정하는 것이다. 확보 불가면 미완료로 남기며 후보 결과를 기대값에 복사하지 않는다. 현재 HEAD `0be09755b70378286105972f35ac5b7031715664`, P03 및 worker SHA는 앞선 관측과 일치했다. 이는 한 시점의 결과이며 K3 실패와 K6 잔여 1회 및 원본 보호를 유지한다. 실제 제품 import·Godot·GUI/Job은 승인하지 않는다.
