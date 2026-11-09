# P03 Dictionary context metadata 수정 계획

2026-11-08 KST. **독립 심사 대기. 테스트·생산 코드·Godot 미착수, 새 K6=0.** Sol 실행 / Terra 독립 심사 명시 배정, Astra 제외. 이 계획의 수용은 공유 경로 쓰기 승인이 아니다. [독립 재현](../p03-dictionary-value-type-20261108/REVIEW-5B-attempt-01.md)

같은 String 키와 int 값 7에서 Dictionary value metadata만 int→Variant로 바꾼 후보를 `restore_completed`가 수용해 활성 sim을 교체했다. `operation_private_state.gd:337`의 Dictionary 비교는 실제 key list와 재귀 값만 확인한다. Godot의 `keys()`가 typed Array여서 key 차이는 간접 검사되지만, value 컨테이너 metadata는 원소 Variant 타입과 별개다.

## 권한과 단계

P02 읽기 revision2에서 자동결산 변환 후보의 clean/returning 실행을 검증 중이다. [현재 P02 계획](../p02-fifth-20261108/PLAN-V3.md). 이 후보는 공통 owner의 이전 viewer-events 변경과 별개다. P03는 이 전용 폴더만 쓰며 P02에 직접 메시지를 보내지 않는다. 현재 owner SHA `c5550999…9a6e`는 관측값이며 적용 시점까지 정본 승인이 아니다.

1. **비충돌 fixture.** 이 전용 폴더에 신규 테스트와 증거만 작성한다. 현재 공통 소스를 읽는 재현 실험으로, 이미 확인된 순방향을 중복 성과로 집계하지 않고 아래 양방향·builtin/class/script 새 분모를 관측한다. 각 사례는 실제 capture/prepare/restore와 raw 독립 오라클을 사용한다. 정확한 거부 또는 실제 수용을 보존하며 절차 PASS와 conformance를 분리한다.
2. **공통 owner 최소 수정 후보.** 별도 소유권 합의·현재 diff 확인·계약 재검토 뒤에만 기존 `_context_same`의 Dictionary branch에서 `get_typed_key_builtin/class_name/script` 및 `get_typed_value_builtin/class_name/script` 6개를 대조한다. script는 `is_same`, 나머지는 정확 비교한다. 기존 keys 배열/삽입순서 및 값 재귀 검사와 Array branch를 유지한다. 이 helper 외 다른 생산 경로, Service._same/_data, 검증 순서·상태 교체·serialization/API/packet version은 이 계획에 포함하지 않는다. 실패 시 기존 `replacement_context_mismatch`와 active/packet 무변이가 요구된다.
3. **검증.** 변경 후 동일 fixture의 기대를 conformance로 실행한다. 사전에 양쪽 입력 소스·실행 명령·실제 class path와 engine SHA를 각각 고정한다. 기존 P2c/활성교체 및 P02 viewer-events의 최소 관련 회귀를 원래 결과 경로에 쓰지 않는 방식으로 독립 계획한다. before/after 본체 diff와 사용된 원문 로그를 검토한다. 격리 수정본을 검증하더라도 원작업트리에 적용됐다고 표현할 수 없다.

## 독립 오라클과 인수 분모

사례별 seed7/hz10 제한 POC, 같은 profile/controls 외 note의 단일 변수만 다르다. 양쪽 candidate 모두 정상 create/capture 및 독립 prepare를 통과하고, active는 실제 step/issue/queue 뒤 pending/log/events가 있다. 성공 대조군에는 초기 서로 다른 객체를 쓰고 새 sim의 Script identity와 by_id 재결합을 검증한다. 거부 시 원 packet 및 입력, active handle/sim, tick/clock/state, log·pending·events와 ready/busy 보존 뒤 실제 정상 advance를 확인한다.

| 명명 | 입력과 기대 |
|---|---|
| metadata_fix_01_same_dictionary | 별개 typed Dictionary에 동일 metadata·순서·값. 두 유효 context의 성공과 준비 상태 exact |
| metadata_fix_02_value_builtin_both_directions | `Dictionary[String,int]` ↔ `Dictionary[String,Variant]`, key 및 keys metadata 동일·실제 int7 동일. 두 방향의 정확한 mismatch 거부 |
| metadata_fix_03_value_class_both_directions | 빈 `Dictionary[String,Node]` ↔ `Dictionary[String,RefCounted]`. 동일 OBJECT builtin·null script, native class만 다름. 두 방향 mismatch |
| metadata_fix_04_value_script_both_directions | 빈 `Dictionary[String,FleetState]` ↔ `Dictionary[String,BattleState]`. 동일 OBJECT builtin·native class, canonical script identity만 다름. 두 방향 mismatch |
| metadata_fix_05_existing_context_controls | key Array metadata 차이 1, 실제 int/String 키 타입 차이 1, 키 삽입순서 차이 1, Array typed builtin/class/script 대조 3. 정확한 mismatch 유지 |

명명5, 대조군·방향은 별도 실제 분모로 기록한다. empty typed OBJECT는 metadata 차이만 사용하며 비어 있지 않은 객체 값이나 객체 키 허용은 새로 주장하지 않는다. 어느 후보에서든 metadata가 입력→packet→prepare를 지나는 동안 없어지거나 고유 변이 전제가 성립하지 않으면 미해결/절차 실패다. 이전 raw comparator의 Dictionary type/keys/값, Array type/order 및 Script identity를 재사용하되 production helper를 oracle로 호출하지 않는다.

engine console/본체, runtime PID·경로, 정본 class map 및 실제 Script identity, 입력·runner SHA 전후 불변, 실제 exit/raw logs, diagnostics, Windows 전용 Job, 저장소 branch/HEAD/index 및 신규 dirty SHA를 각각 고정한다. 새 K6, 실패 기록 보존, 변경된 계획은 독립 재심사, 사용량 제한 시 즉시 보고·재시도 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
