# C side 1 v6 독립 심사

판정: **인과 순서 판정기의 정적 보강은 수용, 실제 producer·결합 및 제품 실행은 미승인.** `C-SIDE1-CAUSAL-V6-REVIEW.md` SHA `f30d16ab5ea918a33711f7ac0c219a303b5fd342bc361a405bb31e0fb7c89ffa`, `c-side1-v6-sha.json` `bb2db43e685c2232a13ba38354a68fa5a3e5f36e4b455f31a281afb531375e50` 확인. 심사 모델 gpt-6.1-terra. 제품·Godot·GUI·Job을 실행하지 않았다.

`_detection` 원문의 A/B 최초 20틱, 위치 이동, A 후 B 추가 진행, 첫 restore, wrong-position control, repaired restore 및 suffix 이전 경계와 `plan()`의 순서는 정적으로 양립한다. lane 파일 순서를 고정해 원본 line에서 hash·merged ordinal을 계산하고 lane 내 ordinal·actor별 ID·restore request→success 순서를 검사하므로 v5에서 지적한 임의 instance block 정렬 문제를 다루는 설계다. 합성 로그는 9,600 receipts 정상과 9종 거부를 기록하지만 실제 사건 증거가 아니다. 파일 연결 순서는 서로 다른 프로세스의 실제 전역 시간 순서를 뜻하지 않는다.

실행 전 구체적 결합이 여전히 필요하다. `check_events`는 시간·geometry·packet·상태 payload를 포함하지 않고 event 이름과 tick/ID만 검사한다. 동일한 이름의 다른 요청이나 임의 성공 receipt를 받아들일 수 있으며, 실제 `_eval` 호출과 일치하는 authoritative tick·monotonic timestamp, source/target 실제 identity, raw geometry 및 최초 contact, request packet digest와 성공 결과·capture의 동일 digest 인과관계가 입증되어야 한다. 이 판정기만으로 v4의 8,960개 geometry witness 및 160 capture 증명은 되지 않는다. `_eval` 시점 누락을 가짜 행으로 채운 경우, 동일 tick에서 packet을 교체한 경우, raw event와 geometry witness ID/값 불일치, process 재시작과 reused identity, phase 후 상태 변조를 거부하는 반례를 추가한다. `sim_id`의 lane 내 전역 유일성은 구현체의 안정적인 run-scoped 식별 방식으로 보장해야 하며 주소/PID만으로 추정하지 않는다.

`pinned_inputs`는 별도 전달된 승인 SHA와 manifest bytes를 비교하고 부분 6개 파일을 재해시하므로 동일 manifest+파일 교체에 대한 합성 반례의 범위에서 유효하다. 승인값을 후보가 계산하는 방식으로 연결하면 독립성이 없고, `confirm_envelope`는 문자열로 주어진 receipt의 동등성만 검사한다. 실행기에서 승인된 전체 closure·engine/cache/overlay와 before-spawn/after-join receipt의 생성 경로, process HANDLE 및 동일 원본 로그 hash를 고정해야 한다. 전후 hash는 중간 교체 및 프로세스가 실제 해당 bytes를 읽었음을 증명하지 않는다. 실제 OS-backed 읽기 전용 격리·reparse/TOCTOU 방지 및 별도 log sink가 미구현이다.

원문 v5/v4와 P03 활성 변경을 보존하고, GUI provenance·Job/파일시스템 격리와 최종 manifest를 독립 수용하기 전 K6을 시작하지 않는다. K1~K5와 마지막 한 회, 최초 제품 import의 소진 정의는 유지한다. HEAD lane은 활성 P03 결합 미검증이다.
