# C producer extension v2 独립 source 심사

판정: **source-only 구현은 검토 가능한 초안이나 독립 5-b·실행 수용은 반려한다.** `c_actual_extension_raw_v2.py` SHA `c830bf54cd247e362f6f534f924e97517045c1f623c84f6410fb7eab943d46c8`, `c-actual-extension-review-v2.gd` `d618012a3e9c8de121b2fb8ad4e05300f99c06231b83360b6901d68b9dbbb78e`, 독립 `CONTROL.md` `b6d371ae44e4c48f4b4b55663f8714e72347aa70efd0d26abef6ffd995684aa7` 확인. `SOURCE-SHA256.txt`의 실제 8개 파일은 현재 모두 일치한다. 심사 모델 gpt-6.1-terra. Godot·제품·GUI·Job 실행 없음.

정적 대조에서 original primary/repeat·wrong·repaired primary/repeat 5회 구조는 유지하고, 기존 `_suffix`의 A/B step→fingerprint→_all→각 drain 한 번의 순서를 값 변수에 담아 보존하는 형태다. `identity`는 양 side/record의 target-source 및 target-packet 쌍을 수집하며 `mutation`은 원 packet 및 양 `_all` 전후를 기록한다. 새 validator는 base anchor·request ID·case pin/expected pair·suffix drain을 결합하려 한다. 원본 실행과 비교해 추가 `_all`/직렬화/출력/observer의 runtime 부작용·부하 및 파서는 아직 확인되지 않았다. supply/refusal은 추가 receipt가 필터되지만 `_suffix` 함수 호출 자체는 변경되므로 해당 경로의 원래 결과와 호출 수를 실제 검증해야 한다.

**최소 수정과 보완 조건:**

1. 독립 `CONTROL.md`는 fixture source 기반 불변식이며 실제 per-case event transcript·동적 contact key·승인 oracle SHA가 없다고 명시한다. `verify_lane`은 `oracle["provenance"]`와 `cases`의 truthiness 및 외부 SHA만 확인하므로 승인자가 실제 독립 source/method·원문 digest·정확 20 case 및 event sequence를 외부에서 고정하기 전에는 완료/실행 가능이라고 할 수 없다. 후보 transcript에서 기대값을 복사하지 말고, 자료가 없으면 K6을 쓰지 않고 미완료로 둔다.
2. `plain`은 decoded typed container metadata를 버리고 Python dict로 바꾸며 `same`은 dictionary insertion order를 무시한다. 따라서 `_all`/packet의 typed Array/Dictionary metadata 또는 dictionary key 순서만 다른 경우 원래 typed raw 차이를 놓칠 수 있다. raw Variant 노드 또는 명시 typed canonical 형태를 비교에 유지하고 metadata·key 순서·StringName/int 구분 및 같은 숫자 다른 유형의 부정 사례를 전체 경로에 추가한다. 해당 범위가 원본 `_plain`에서 의도적으로 지워지는 경우에는 packet 원문과 구분해 제한을 명시한다.
3. `_k6_extra`는 base 사건과 같은 stdout에 출력하지만 `read_extra`는 각 입력 줄이 전부 extension prefix일 것을 요구한다. 원본 stdout에서 base/extension을 손실 없이 분리하는 승인된 raw line offset/hash 방식이 아직 연결되지 않았다. `base_ordinal_next`만으로 서로 다른 실행이나 조작된 split의 동일성을 증명하지 않는다. 동일 소유 process·run/lane·original raw SHA 및 ordered offsets를 결합하고 누락/중복/교차 run을 거부한다.
4. hand-authored fixed-byte positive와 11개 지정 negative의 원문 transcript·정확 hash·각 의도된 거부 지점에 대한 재현 결과를 확인하지 못했다. 기존 합성 결과를 이 extension의 독립 5-b로 대신하지 않는다. 특히 alias true, wrong mutation, same wrong config, source/target 외부 변경, 누락·순서 및 command/event 변조와 false result를 실제 통합 경로에서 확인한다. v9 lane gate, geometry 및 OS provenance도 연결이 필요하다.

이 조건을 충족하는 한정된 정적/합성 구현은 진행할 수 있다. 실제 제품 fixture/import는 마지막 K6을 소진하며 별도 완성된 21행·GUI·소유 Job 및 독립 심사 전 금지다. 기존 Python K3 실패와 P03/worker/Git 및 원본 파일을 보존한다. P02는 NOT_READY다.
