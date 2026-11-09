# C producer·K6 통합 계획 독립 심사

판정: **다음 구현 설계로 조건부 수용. 실제 producer·최종 oracle·제품 실행은 미승인.** `C-PRODUCER-AND-K6-INTEGRATION-PLAN.md` SHA `5e1bd6a76ee637e9ee3a5ca8f2f96dd96687f61ce556da67d12d00d988dbb07d` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행은 하지 않았다.

원문 `_restore`의 primary와 repeated apply, `_detection`의 first → direct wrong-position → repaired 순서를 대조했다. 성공 경로는 segment당 5회, 10 seed × 2 case × 2 lane = 200회다. repeated apply의 원문은 `_check(Service.restore_into_prepared_target(...).ok and _same(...))`로 short circuit하며 계측은 호출 한 번과 평가 순서를 보존해야 한다. Wrong-position은 성공한 restore와 fingerprint 차이를 검증하는 negative control이지 거절이 아니다. v6/v7이 repeat 둘을 다루지 않고 v9도 의미상 3 phase만 다룬다는 정정은 정확하다. 200 calls와 별도 geometry witness·capture를 합산해 같은 분모인 것처럼 사용하지 않는다.

계획은 producer가 실제 원문을 읽고 native source/target instance, 5회 call의 pre/post·return·packet 및 `_eval` geometry를 같은 lane 원본과 연결하도록 요구한다. 이는 필요한 방향이지 이미 구현·검증된 도구가 아니다. 특히 원문의 alias mutation은 첫 restore/repeat 뒤 원 packet을 변경하는 별도 사건이고, wrong-position은 새 `_capture(a)`를 사용한다. 각 packet identity·bytes 및 call 시점, source/target identity·중복 apply·alias/원상 회복과 suffix를 명확한 ordered event에 배선해야 한다. 기존 3-phase 합성 판정기를 그대로 넘겨 전체 5회나 `_all`/detach를 검증했다고 주장할 수 없다. 각 anchor의 반복 호출·실패 후 short circuit·전체 다른 suite의 `_eval`과 C fixture만 구별하는 필터를 검토하고 계측이 원래 호출·조건·결과를 바꾸지 않는 diff 및 반례가 필요하다.

독립 oracle의 기준은 후보가 생산한 같은 JSON이나 같은 implementation의 재직렬화가 아니라 승인된 fixture/context, native state 원문 및 별도 계산이다. 요청/결과의 hash는 연결만 증명한다. producer가 동일 run에서 geometry와 상태를 함께 꾸미거나 실제 `_eval`을 빼고 순번을 채우는 반례, packet pos 외 변경, repeat 효과, alias 미분리, source/target cross-run 및 false return·log 손실을 필수 판정기로 거부해야 한다. 승인 pin은 candidate 바깥의 독립 기록에서 가져오고 source/engine/cache/overlay 전체 closure·immutable lane·OS-backed reparse/TOCTOU 경계를 확립한다. pre/post SHA는 중간 변경이 없음을 보장하지 않는다.

본 계획의 산출물은 실제 producer·최종 실행기가 아니라 설계다. 비제품 ABI의 기존 반려와 Job/FS 독립 심사·실측 요구는 그대로다. Sky 요청별 입력 귀속 미증명은 행 15/16 및 전체 K6 차단 사유다. P03 원본 +9와 worker +2 및 병행 작업을 보호하고 HEAD lane이 P03 결합을 검증하지 않음을 명시한다. K1~K5와 마지막 K6 한 회, 최초 제품 import/검증 spawn에서 소진 및 실패·부분 실행 재시도 금지, 175/320 한도를 유지한다. 실제 21행 manifest·사전 조건과 별도 5-b 전에는 제품 적용을 승인하지 않는다.
