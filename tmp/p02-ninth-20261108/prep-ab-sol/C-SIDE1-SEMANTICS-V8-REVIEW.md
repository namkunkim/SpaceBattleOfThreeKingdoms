# C side 1 서비스 패킷 의미 판정 v8

v7과 독립 심사 원문을 보존했다. 이 조각은 별도 오프라인 판정기와 합성 반례까지다. 실제 제품과 Godot을 실행하지 않았다.

OperationServiceState.capture_partial의 format/context/detection/supply 구조를 대조했다. 새 판정기는 Godot ed1daf0bf의 제한 subset에서 nil/bool/int/float/String/StringName/Vector2와 ordered array/dictionary 및 built-in typed container header를 읽는다. 타입을 보존하며 중복 키, 불완전 데이터, trailing bytes 및 지원하지 않는 객체/metadata를 거부한다. 실제 fixture 전량의 engine byte 유형은 미확인이다. [Godot marshalls.cpp](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/core/io/marshalls.cpp)

- Packet과 scoped live projection의 seed/profile/hz/tick/clock/roster를 대조한다. 정수 contact ID가 반대편 roster에 속하는지와 각 typed field 및 순서를 검사한다. 양측 decoded side 1과 reported records가 모두 비어야 한다. Candidate packet과 live에 같은 잘못된 fixture를 넣는 경우에 대비해 외부에서 승인된 독립 typed context를 검사하는 별도 함수를 둔다.
- Wrong-position control은 선택된 opposing ID의 side 0 contact.pos를 별도 live position으로 바꾼 구조를 기대한다. 그 한 위치 외 전체 packet의 typed 값과 dictionary/array 순서, context, module 값을 보존해야 한다. 변경된 packet과 target live contact도 대조한다. 합성 ID 7·15나 좌표를 판정기에 고정하지 않았다. 제품 연결 시 원문이 지정한 선택 ID를 independently pinned context의 roster 순서에 결합해야 한다.
- Source stability는 profile/seed/hz/tick/clock/roster, ordered contact와 typed fleet positions를 비교한다. 별도 receipt_metadata의 ordinal/mono_ns는 변경 가능하며, 외부 snapshot dictionary field 순서도 비교 대상이 아니다. 원래 packet과 nested contacts의 순서는 유지한다. 이는 원문 _all과 detach/alias 전체 단언을 대체하지 않는다.
- 합성에서 위치만 바뀐 packet/target, receipt metadata 차이와 envelope key order 차이를 수용했다. 반례 11건에서 hidden records, 타입/ID 오류, 위치 외 변경, 잘못된 위치, 대조군 미적용, source state 변경, contact 순서 변경 및 joint fixture substitution을 거부했다.

v8은 v7 원본 event pipeline에 통합되지 않았다. Scoped live snapshot과 정확한 _eval/restore 경계의 producer, 독립 typed fixture context 원문, 실제 engine marshaling, 전체 승인 closure, OS-backed Job/filesystem, Sky GUI provenance는 미입증이다. 제품/Godot/GUI/Job 실행 0회, K6 한 회 보존.
