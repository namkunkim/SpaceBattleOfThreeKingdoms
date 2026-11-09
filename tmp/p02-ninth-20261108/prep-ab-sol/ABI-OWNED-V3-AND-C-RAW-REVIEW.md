# ABI 소유 실행기 v3와 C raw 연결 검토 인계

두 조각 모두 독립 재심용이다. 제품, Godot, Windows Job과 GUI는 실행하지 않았다.

## 비제품 ABI

variant-abi-review/abi_owned_runner_v3.py는 기존 V5 inert broker를 outer/inner에 사용한다. 각 broker의 정확 HANDLE을 Job에 할당하고 membership 확인 후에만 barrier를 해제한다. Job process ID list에서 handle을 유지해 creation time, image path 및 Job membership을 확인하며, 종료 때 active count와 모든 보유 HANDLE signalled를 검사한다. Inner engine은 20초, outer controller는 35초, drain은 5초다. Outer는 controller/inner의 stage·capture·fsync를 감시하고 타임아웃 시 자신이 소유한 Job만 정리한다. Outside journal은 drain 뒤 작성하므로 journaling 문제가 engine을 살려 두지는 않는다. Supervisor 자신의 초기 local setup, Popen/barrier 및 종료 후 journaling이 OS에서 붙잡히는 경우까지 독립 외부 hard stop이 입증된 것은 아니다.

manifest는 두 파일 최소 프로젝트, 승인된 console 및 가능한 GUI wrapper SHA, Python, 기존 broker/runner/comparator, exact argv templates/env, scratch 목적지와 보호 경로 SHA를 고정한다. Engine script의 800ms 짧은 체류는 실제 handle을 관측할 기회를 주며 시험할 ABI 내용은 그대로다. Launcher는 승인 파일의 SHA를 후보와 독립된 기록에서 받아야 한다. manifest status는 REVIEW_ONLY_NON_EXECUTABLE이라 이 상태로는 실행할 수 없다. Staging 이후 scratch rglob 목록에서 미지 경로·reparse를 실패 처리한다. 보호 항목은 raw .git/HEAD·index, project.godot, P03·worker 원문이다. 이 파일 목록은 전체 외부 쓰기, 실제 resolved Git HEAD 모든 참조, 관측 사이 변경·복구, OS DLL/stdlib 파일 전체를 보증하지 않는다. 현재 managed 경계를 강화했다고 주장하지 않는다.

정적·합성에서 Python compile, manifest의 source/protected hashes, wrong approval SHA 및 unexpected scratch path 거부를 확인했다. ABI strict comparator의 기존 banner/10행 및 stream cap 합성도 별도 유지한다. 실제 nested Job, Windows HANDLE polling race, process list 완전성, stdout/stderr drain, scratch 흔적 및 runtime closure는 미실측이다. 리뷰 승인 없이는 engine을 시작하지 않는다. 제품 없는 ABI probe는 성공해도 K6·GUI 또는 제품 fixture 결과가 아니다. [Microsoft Job process ID list](https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_basic_process_id_list)

## C 증거 결합

c_raw_overlay_mapping.py는 launcher receipt의 whole-file SHA와 원본 line offset/hash를 기록한다. 같은 raw stream의 single-writer ordinal을 확인하고 mono_usec×1000을 mono_ns로 변환한다. 같은 microsecond인 두 값을 임의로 늘리지 않는다. 원본 순서는 ordinal이 판정한다. 기존 v7의 strict 증가 timestamp와 동일 시각을 안전하게 연결하려면 계약 조정이 필요하다.

다섯 실제 호출의 raw source-before/request/result/source-after 20개 경계, run/lane/process 및 sim token, phase/tick을 대조한다. Nested Variant에서 실제 packet과 결과를 decode하고 ordered packet/source _all 불변, target outside, repeat _all no-op을 확인한다. 합성 1세트와 누락 repeat, source mutation, repeat mutation, ordinal 치환 4개 반례를 확인했다. 이 mapping은 오버레이에 맞는 중간 구조까지다. 정확한 v9 scoped pre/post와 독립 fixture pin, v4 geometry sensor 계산, original v7 packet sub-byte SHA 및 deterministic request ID, alias/detach/suffix IDs를 같은 raw run에 결합하는 코드는 미완료다. 재직렬화한 packet digest를 producer 원래 bytes로 바꿔치기하지 않는다.

실제 producer의 schema·collision 및 no-side-effect 검증과 7suite의 exact output volume/time budget은 별도다. 현재 overlay는 전체 config와 _all을 자주 기록하므로 성능을 추정해 통과를 선언하지 않는다. 실제 fixture 사용은 최초 제품 검증이며 최종 manifest 독립 수용 전 시작하지 않는다. GUI provenance, Job 실제 적합성, K6 21행 및 외부 5-b를 유지한다. K1~K5 이력과 마지막 K6 한 회를 보존한다.
