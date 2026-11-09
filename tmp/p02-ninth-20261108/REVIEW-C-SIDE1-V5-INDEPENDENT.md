# C side 1 v5 독립 재심

판정: **v4 순서 누락의 정적 수정 수용, 실제 증거·실행 승인은 보류.** `C-SIDE1-ORDERED-V5-REVIEW.md` SHA `c0ef2cb9979dbbac1026d579eca3cf7ad31982c694cef5ece37b5f16aa8b69ab`, manifest `ffb639652b616a4fd0ee2aaa529063ba86b566cf5e7587faf55487b46965b5f`, verifier `9fedc128b4728aa5c46839e2fc41c890f7886331c7a0ffc487e38fc525b28c22` 확인. 심사 모델 gpt-6.1-terra. 제품·Godot·GUI·Job 실행은 없다.

`require_absence`는 v4의 집합 비교와 달리 canonical lane→instance→seed→case→phase 순서에서 모든 key와 빈 side 1 records를 검사한다. 보존된 합성 로그는 canonical·unchanged bytes 2건 수용, 역순·인접 phase 교환·label 변경·lane 순서 교환·중복·누락·stale/missing source 8건 거부를 기록한다. 검증기가 실제 역순을 거부하도록 바뀐 점은 소스와 일치한다. 이는 합성 기록이며 실제 producer나 Godot에서 얻은 자료가 아니다.

순서의 의미는 실행 전에 더 구체화해야 한다. `tests/i01b_service_state.gd`는 하나의 fixture에서 첫 restore와 repaired를 순차 실행하고 source/target이 함께 존재한다. v5 기대는 instance별 전체 블록이다. 실제 원본의 interleaved event를 어떻게 독립 instance stream으로 나눌지, 고정 파일 순서가 각 파일의 실제 ordinal을 유지하며 누락·중복·cross-instance 혼합을 막는지 명세해야 한다. 합성 순서에 맞추는 임의 정렬은 시간 순서 증명이 아니다. 별도 원본 sequence와 restore request/result/identity·phase 인과관계를 확인하지 않으면 key 순서만 맞는 다른 사건을 배제하지 못한다.

`verified_sources`는 지정 root의 6개 실제 파일 bytes를 읽어 각 값과 canonical digest를 비교한다. 다만 `source_manifest` 자체는 함수 인자로 들어오고 내부에서 신뢰된 manifest SHA를 고정하지 않으므로, 공격자나 잘못된 호출자가 manifest와 파일을 함께 교체하면 자체 일관성만으로 통과할 수 있다. launcher가 독립 승인된 manifest의 정확한 SHA 및 전체 closure를 동결·확인해야 한다. resolve 후 read 사이 교체나 실행 중 교체는 이 함수의 단일 시점 재해시로 막지 못하며 reparse·읽기 전용 격리와 시작/종료 확인을 별도로 검증한다. 샘플 사이 불변이나 producer 신뢰를 hash만으로 주장하지 않는다.

실제 `_eval` 직전 authoritative tick과 run/lane/instance/fixture·process identity, 초기 빈 contact→평가→restore→source/target captures의 receipt chain과 raw line offset/해시 검증기는 아직 없다. 두 lane·두 인스턴스의 실제 생산기, 8,960 witness·80 초기·160 capture 및 side 1 부재는 미측정이다. 기존 typed bytes, restore 성공·원본 불변·detach/alias·사건은 별도 판정이다. GUI provenance와 Job/filesystem 격리도 미해결이며 전체 K6 실행은 금지한다. K1~K5, 마지막 K6, P03 및 기존 원문을 보존한다.
