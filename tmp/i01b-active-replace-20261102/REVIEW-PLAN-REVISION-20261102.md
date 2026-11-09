# 제한 활성 owner 교체 — 독립 계획 검토 1

2026-11-02 KST / **현 계획은 최소 보완 후 재심**. 생산 코드·검사 수정 없이 PLAN과 P2c owner, 실제 FleetBattle3D/AutoResolver 진입점, D04 §4·K06~K08을 대조했다. 검토자는 구현 비참여 `/root/independent_review` (`gpt-6-astra`)다.

기존 owner handle을 유지하면서 검증된 새 private sim을 옮기는 한 메서드 범위는 P2c 다음의 작은 통합 조각으로 적절하다. 새 facade를 만들지 않고 실제 UI/시계·스레드·적벽 모듈이 필요한 host/headless/replay 연결을 완료로 주장하지 않는다. 동일 원입력만 허용하는 국소 제한도 새로운 게임 정책이나 외부 schema 확정으로 확대하지 않으면 수용 가능하다. 다만 아래 네 항목을 구현 전 명시해야 한다.

## R1 — 실제 readonly I/O와 계획 문장의 불일치

PLAN의 "이 호출에 ... 파일 I/O는 없다"는 기존 prepare 재사용과 양립하지 않는다. `operation_private_state.gd:_packet_error`는 `_code()`의 `FileAccess.get_sha256`을 호출하고 `_profile_error`는 현재 combat JSON을 `ProfileLoader.read_json`으로 읽는다. PocSetup의 최초 cache 초기화도 파일을 읽는다.

이를 제거하는 새 코드가 필요하다는 뜻이 아니다. 기존 readonly 코드/설정 조회를 그대로 재사용하고 신규 파일 쓰기/외부 부작용을 추가하지 않는다고 정정한다. 원자 교체는 단일 스레드의 외부 callback/await 없는 소유권 경계로 설명한다.

## R2 — busy와 candidate 소유권 이전 순서

기존 `_guard`는 busy 또는 unprepared_owner를 반환하고 `close()`는 자신이 가진 sim의 모듈 참조를 해제한다. 계획에는 메서드 입구 guard만 있고 준비/정리 전체의 busy와 candidate에서 옮겨온 sim의 소유권 해제 시점이 분명하지 않다.

guard→현재 owner busy 설정→candidate의 전체 prepare/맥락 검사→한 번의 sim 교체→candidate의 sim 소유권 해제→이전 sim retire→busy 해제를 명시한다. prepare 실패 또는 context 불일치에는 현재 sim/모듈을 닫지 않으며 busy를 원상복구한다. context 실패 candidate만 닫는다. 성공 직후 candidate.close나 현재 owner.close가 새 sim의 bindings를 끊는 경로가 없어야 한다. 테스트의 old-binding retirement/new-binding identity·실패 뒤 정상 호출을 이 순서와 연결한다. 공개 close 반환형과 기존 API 의미는 변경하지 않는다.

## R3 — 동일 context의 exact 의미

profile/seed/hz/initial_controls의 "정확히 같은 원입력"을 검사 가능한 비교 규약으로 적는다. Variant 타입/값, Dictionary 키 타입/삽입 순서, Array 원소 순서와 typed array metadata를 각각 어떻게 취급하는지 명시한다. 기존 Service._same은 Array 원소를 재귀 비교하지만 typed array metadata는 비교하지 않는다. 이를 그대로 쓸 수 있으나 그 의미와 다른 exact metadata 보존 주장을 혼동하지 않아야 한다.

예컨대 initial_controls=[]와 같은 실효 제어를 만드는 명시 delegate 배열은 원입력 관점에서 다르다. 자동 정규화하지 않을 것인지 명확히 한다. 동일 profile_id만 비교해서 다른 규칙/편성을 수용하지 않으며, 별도 prepare가 가능한 다른 context 반례로 replacement_context_mismatch임을 확인한다. 전역 작전 ID나 새로운 외부 호환 정책을 만들 필요는 없다.

## R4 — 실제 활성 전제와 snapshot 기준의 사건 의미

20 정상 사례를 유지하되 POC 계열은 실제 진행 투사체/타이머, Salvo-D/S 계열은 실제 nonempty contact와 supply 진행 또는 완료 뒤 재고 지출을 assertion으로 보증한다. suffix가 실제 경계에 도달해야 보급 중복 효과가 없다는 주장을 할 수 있다. 단순히 모듈 객체가 생성되어 있고 아직 아무 일도 하지 않은 fixture는 이 주장의 근거가 부족하다. 원래20/8 분모를 늘리거나 별도 제품 기능을 추가할 필요는 없다.

복원되는 사건 상태는 **packet 시점**이다. packet 시점 이미 drain된 사건은 빈값이고, packet 시점 미소비 사건은 복원 후 원래 순서로 한 번 drain된다. packet 이후 옛 active에서 소비한 사건도 더 옛 packet으로 돌아가면 다시 미소비 상태가 될 수 있다. 동일 packet 재복원이 전역으로 사건/명령을 한 번만 허용한다는 dedup/cursor 정책은 이번 범위 밖이다. restore 자체가 issue/step/drain/보급완료를 실행하지 않는다는 제한과 구별해 적는다.

네 항목을 계획에 반영하면 기존 helper 최소 hunk·신규 검사·P2c OUT-only 회귀/core/data와 보존 감사 구성은 유지할 수 있다. 구현은 독립 계획 재수용 전 시작하지 않는다. 원래 P2c 최종 수용/zip은 불변이며, 이번 판정은 다음 계약의 계획만 대상으로 한다. 전체 I01b/A04~A06 NOT_READY 및 외부 schema UNCLASSIFIED 유지.
