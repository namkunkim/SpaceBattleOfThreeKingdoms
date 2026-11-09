# C extension v4 wire 비교 독립 심사

판정: **wire-level 단위 보강을 한정 수용한다. 실제 engine ABI·동적 oracle·통합 5-b는 미완료다.** `c_actual_extension_wire_v4.py` SHA `bdaae7a25982f2aa8b87e585cd02825b42d281c729f144f47102c37df6cc5e1d`, raw adapter `ffd04c8e13398bde0db1b2521b0e40e02d549a825531e7e26d99fda8bf0eedb1`, unit `4bf13f3f20af9cb1695cb588559b26ddaea3e1dd9e52425666ae8e77d81adfab` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

[고정 Godot source](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/core/io/marshalls.cpp)의 encoder는 signed int가 32-bit 경계를 넘거나 double이 float로 정확히 표현되지 않을 때 64-bit flag를 쓰며 Vector2는 빌드 `real_t` 폭으로 직렬화한다. v4의 경계 seed·합법 f64·비정규 폭 거부 및 Vector2 flag 보존은 그 encoder 조건과 정적으로 부합한다. 실제 설치된 engine binary가 그 source/build precision과 같다는 뜻은 아니다. unit의 수작업 사례는 경계 int, f64, Vector2 폭, container metadata·dictionary 순서, 여분 flag 및 phase 중복을 점검하지만 실제 엔진 입출력이나 11개 전체 통합 negative는 아니다.

새 `decode_wire`는 지정 packet/alias/suffix에서 float·Vector2 flag, nested metadata와 순서를 유지하며 v3보다 wire 차이를 더 잘 드러낸다. 다만 canonical 정수 폭을 검증해 그 flag 자체를 반환하지 않는 점, 지원하지 않는 Variant/class/script metadata·비유한 수를 fail closed하는 점, source `_plain`이 이미 구조를 변환한 범위는 명시해야 한다. Godot decoder가 읽을 수 있는 비정규 인코딩까지 무조건 허용한다는 계약이 아니라 **해당 encoder에서 나온 canonical 자료**를 전제로 한다. String과 StringName의 동등 키·중복 의미, 잘린/과대 중첩 자료 및 float32 경계와 부호 있는 0의 반례를 추가해 잘못된 허용/합법 자료 거부를 점검한다. 최대 raw 및 재귀/container 상한은 실제 producer 출력에서 과도한 false negative가 없는지 확인한다.

`typed_checks`는 명시 필드에 wire 비교를 적용하지만 `case_base`/`check_case`는 여전히 plain projection을 쓴다. 전체 자료의 raw wire 동일성을 주장할 수 없고, 원본 `_all`의 의도적 plain 변환과 packet 원문 보존을 구분해야 한다. 단위 smoke는 independent dynamic oracle, 두 lane 전체, 실제 producer·process provenance·geometry/alias/detach/suffix를 입증하지 않는다. 독립 control의 null 값과 11개 통합 negative를 원문/해시 및 정확 실패 지점으로 채우는 것이 다음 유한 작업이다. 실제 engine 측정은 K6 및 관련 실행 조건을 우회하지 않는다.

현재 P03/worker의 SHA는 앞선 관측과 일치한다. 이는 단일 시점 결과이며 타 세션 변경은 보호한다. K1~K5, Python K3 실패 및 마지막 제품 K6을 보존하고, GUI/Job·최종 21행 미완성 상태에서 제품을 실행하지 않는다.
