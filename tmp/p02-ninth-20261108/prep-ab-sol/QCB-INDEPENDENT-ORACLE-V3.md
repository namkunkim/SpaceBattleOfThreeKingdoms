# Q/C/B 독립 기준 보강 v3

제품 경로, Godot, GUI와 Job을 실행하지 않았다. 다음 변경은 검토용 새 산출물이다.

## Q/C typed bytes

`variant_subset_oracle.py`는 고정 engine banner와 동일한 Godot ed1daf0bf의 Variant enum 및 marshalls.cpp encoding에서 사용 subset을 별도 Python으로 읽는다. Dictionary 27/Array 28을 사용하며 이전 버전 숫자가 남은 일반 문서 표를 기대값에 사용하지 않았다. Unsupported flags/types, padding, duplicate key, trailing bytes, 무한값과 JSON type/value 차이를 거부한다. `independent_qc_oracle_v3.py`는 native/product 양 스트림을 decode하고 기존 independent Q/C 검증을 적용한다. C 역사 side 0 case는 정확히 20개의 unique ordered key를 요구한다. 합성 typed payload 변조 여섯 종을 거부했다. 실제 엔진의 raw bytes는 아직 캡처하지 않았으므로 decoder의 실제 fixture 적용 및 Godot parser는 미검증이다.

고정 Vector2 구현의 distance_to 산식에 따라 별도 float32 모델을 사용한다. (4096,1)과 (4096,0)은 실수 거리는 다르지만 이 모델에서 sqrt 이후 동률이며 순서상 먼저 보이는 목표를 고른다. 첫 값을 (4096,2)로 바꾸면 둘째가 더 가깝다. 합성 검사는 두 조건을 구분한다. 실제 바이너리의 연산 최적화·build precision과 raw projection의 진실성은 미측정이며 제품 정책의 기대값을 같은 함수에서 얻지 않는다. [Godot marshalls.cpp](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/core/io/marshalls.cpp), [Variant enum](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/core/variant/variant.h), [Vector2 distance_to](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/core/math/vector2.cpp)

## C side 1 독립 조건

tests/i01b_service_state.gd의 detection fixture는 ally ID 1에 10×SHP-01, foe ID 2에 4×SHP-02, 시작 위치 (400,450)/(500,450) 및 foe 후속 강제 위치 (1500,450)를 사용한다. SalvoFixture.def의 formation FRM-01과 command 70에서 intellect 70을 얻는다. combat_m3.json에서 SHP-02 sensor 1, FRM-01 bonus 0, intellect bonus 12, estimate 15, 거리 단위 25를 얻는다. 시험 설정은 view/radar 0, ship_points_div 1, 지형 없음이다. 따라서 상한 sensor 16에서 distance ≥51이면 distance penalty ≥2라 점수 ≤14다. d>2×max formation offset +1이면 Detection.in_view의 0-radius short circuit도 강제된다. 각 평가의 raw state가 이 보수적 경계를 만족하면 side 1의 빈 기록을 독립적으로 도출할 수 있다. 후반 동선·배치·조합은 static spawn 좌표만으로 보증하지 않는다.

`c_side1_bound.py`는 위 전제가 들어 있는 2,240개의 순서 있는 source witness가 전부 존재할 때만 side 1 []를 인증한다. 키는 10 seeds × (estimated 32 + lost 192) eval ticks다. Witness는 Detection._eval 호출 직전 raw positions, form_offsets, equipment, intel, formation, 살아 있는 ship category, bonus/skill/chain을 기록해야 한다. 기존 _restore의 native/target contact 결과로 이 witness를 만들면 안 된다. 현재 witness producer와 실측 자료가 없어 actual presence는 미완료다. 합성에서 witness 부재인데 양측이 빈 경우, 나란히 불가능한 ID가 생긴 경우, 평가 누락과 불충분 거리 등을 거부했다. 실제 fixture에서 보수적 거리 조건을 벗어나면 해당 eval을 통과시키지 않는다. 조건부 verifier의 성공을 새 역사 record로 기록하지 않는다.

## B의 독립 의미 기준

`b_semantic_oracle.py`의 기대는 WorldMap constructor 및 result source에서 고정한 label 순서와 3 device다. Expected NodePath를 같은 runtime 객체에서 얻지 않는다. `b-semantic-review/world_link.gd`는 기존 실제 _buttons traversal에 관측만 추가하며 raw path·visibility·enabled·label·ordinal을 기록한다. 동일 개수 오동작 label, 누락, hidden, 실제 path alias를 거부하는 합성 확인을 했다. label만으로 handler 바인딩이 같음을 보증할 수 없다. 기존 actual product button routes의 action/transition 단언과 함께 써야 하며, 동적 이름의 정확한 절대 NodePath, 실제 count 109 및 실행 명세 전체는 미확정이다.

## Watchdog 및 종료점

W4 55초 설계에서 global이 먼저 만료되면 stage 성공으로 분류하지 않는다. local 및 global이 동시에 도달하면 global hard timeout을 우선 기록한다. POSTVERIFY_BEGIN durable receipt 누락은 stage 귀속 실패다. 7초 reserve 중 owned drain 최대 5초, outside final journal 최대 2초다. 어느 기록이든 flush 실패는 정상 취소나 종료 성공으로 바꾸지 않는다. 현재 WindowsSandbox.exe 두 위치와 docker/podman/WindowsSandbox.exe 명령 조회에서는 사용할 실행기를 확인하지 못했다. 이는 capability 전수 검사나 호스트의 기능 부재 증명이 아니다. OS-backed write confinement가 입증된 launcher 또는 독립 환경이 별도 제공되지 않으면 env·path checks만으로 controller/engine을 실행하지 않는다. 기존 OS 보안 설정과 권한을 바꾸지 않는다.

이 선행 조각은 정적 원문과 합성에서 검증할 수 있는 verifier까지다. B absolute path/semantic action, C 실제 pre-eval witness와 측정, watchdog OS confinement/owned execution 및 GUI per-request provenance가 남아 있다. 독립 검토 전 제품 프로세스를 시작하지 않는다. HEAD lane은 활성 P03 +9와의 결합을 검증하지 않는다. K6 잔여 한 회와 K1~K5 이력을 유지한다.
