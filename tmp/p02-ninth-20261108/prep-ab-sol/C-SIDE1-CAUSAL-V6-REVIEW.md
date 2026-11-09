# C side 1 v6 원본 인과 순서 및 동결 입증

v5 원문을 보존했다. 이번 산출물은 독립 검토용이며 제품 경로·Godot·GUI·Job은 실행하지 않았다.

## 원본 순서

tests/i01b_service_state.gd의 `_detection`이 두 fixture를 만들고 A 20틱 → B 20틱 → A/B 위치 변경 → A 추가 진행 → B 추가 진행을 수행하는 순서에서 원본 사건 목록을 유도했다. 이어 첫 restore의 source capture → target request → 성공 → target capture, wrong-position control의 request/result, repaired restore의 같은 4개 사건이 이어진다. 마지막 scope-end는 suffix 진입 전의 tick이다. Suffix의 평가를 앞선 certificate horizon에 포함하지 않는다.

`c_side1_chain_v6.py`는 launcher가 해시를 남긴 lane별 JSONL 원본을 그대로 읽는다. before, after file order를 manifest와 함께 고정한다. 각 원본 line hash는 파서가 계산하고 producer가 merged ordinal이나 해시를 지정하는 입력은 거부한다. 병합 ordinal은 파일을 순서대로 이어 붙인 인덱스이며 별도 프로세스의 wall-clock 전역 시간은 아니다. 원본 stream ordinal은 각 lane에서 0부터 연속이고, event/actor/phase/seed/tick과 동일 simulation ID를 확인한다. 복제본은 원래 source/target interleave를 유지한 전체 사건 검증 뒤에만 v5의 instance별 증인 뷰로 투영한다. canonical 키를 만들려고 원본을 정렬하지 않는다.

## 승인 SHA 및 실행 시점

`pinned_inputs`는 외부 독립 승인 SHA에 대해 manifest 원문을 비교한 뒤 manifest에 명시된 소스 파일을 재해시한다. 해당 과정 직후 manifest를 다시 비교한다. 독립 승인값을 candidate manifest와 같은 폴더에서 읽거나 candidate에서 계산해 전달하면 joint replacement를 막을 수 없으므로, launcher의 독립 심사 기록에 exact approved manifest SHA와 exact full closure digest를 별도로 고정해야 한다. 현재 함수가 사용하는 소스 목록은 이전 검토용 6개 부분 manifest다. 실제 launcher에서 before-spawn/after-join receipt의 closure digest가 서로 같고 별도 승인값에도 맞는지 확인하는 정적 보조 판정기를 제공한다. 파일 검사를 통과한 시점 사이의 불변이나 실제 프로세스가 해당 파일을 읽었다는 증거는 별개다.

실제 producer 설계에서는 fresh isolated replica의 read-only source와 별도 log sink를 사용한다. Launcher가 engine/source/overlay/cache 전체 bytes, canonical path/relative manifest, process creation time와 Job membership, lane, run ID, exact argv를 spawn receipt에 고정한다. `Detection._eval`의 side 1 body 진입 직전과 테스트의 restore call 경계에만 추가 기록한다. actor의 sim instance ID와 single writer ordinal, monotonic clock 기준, authoritative tick, raw geometry witness 및 초기 contact, restore request packet digest와 actual return status를 각 사건에 붙인다. Source capture, target request/result, target capture의 phase·ID·packet digest 연결과 원본 byte offsets는 전체 구현과 독립 심사가 필요하다. After-join에서 raw file 해시·동일 launcher PID/HANDLE·closure 재해시와 stage 기록을 수집한다. Reparse 및 TOCTOU는 실제 OS-backed 격리와 읽기 전용 복제본으로 제한하며, env/path 검사나 전후 해시만으로 이를 충족했다고 주장하지 않는다.

v6 정적 판정기는 raw causal order와 source pin/receipt 비교까지만 구현했다. 실제 producer, geometry witness의 raw event payload 연결, full closure와 launcher, packet digest/receipt 연결, stage-backed filesystem 보호는 미구현이다. 독립 승인 없이 제품 fixture나 오버레이를 실행하지 않는다. C side 1의 실제 부재는 미증명이다. HEAD lane은 활성 P03 결합을 입증하지 않으며 K6 한 회가 남아 있다.

합성 정상은 9,600개 raw receipts 및 승인 원문·stage receipt다. 시점·actor 순서 변경, restore result 선행, instance 교체, 누락, 원본 로그 변경, manifest와 파일 동시 교체, 동일하지만 미승인 closure, after drift, 승인 receipt 변조의 9개 반례를 거부했다. 이 합성 결과는 실제 8,960개 평가 geometry 증인 및 160개 capture 실측이 아니다.
