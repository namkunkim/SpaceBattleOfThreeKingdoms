# P03 다음 후보 — typed Dictionary context 경계

2026-11-08 KST. **독립 계획 심사 대기, 구현/실행 미착수, K6=0.** Sol 실행 / Terra 독립 심사 명시 배정, Astra 제외. [전체 작업표](../p03-command-suffix-20261107/P03-CHECKLIST-20261108.md)

`operation_private_state.gd`의 `_context_same`은 Dictionary 키 타입·삽입순서·값을 검사하지만 Dictionary 자체 typed metadata getter를 호출하지 않는다. Array는 builtin/class/script identity를 검사한다. `operation_service_state.gd`의 `_data`는 허용 key와 재귀 값을 검사한다. 따라서 실제 packet 경로가 typed metadata를 보존하는 경우에도 다른 typed Dictionary가 활성 교체에 수용될 가능성이 있다. 이는 미실행 가설이다. 기존 suffix는 int/string 키 차이·순서와 Array[int] 차이를 검사했으며 같은 내용의 Dictionary 컨테이너 타입만 바꾸지는 않았다.

제한 POC fixture의 `profile.note`에 넣은 컨테이너로 실제 create→capture→prepare→active restore를 검증한다. 생산 검사자, 스키마, 전체 상태/동적 키 원장, 운영 Cn, P02 소비자와 글로벌 cursor의 변경은 범위 밖이다. 모든 쓰기는 이 전용 폴더로 제한한다. P02 viewer-events의 현 owner SHA 및 다음 자동결산 변환 소유를 재확인하고 공통 private owner, 서비스, adapter, host/worker/replay 및 공유 체크리스트는 읽기만 한다.

## 사전등록

active owner는 매 사례 새로 생성한다. seed7/hz10/reinf=[]·명시 direct POC에서 실제 한 step 진행하고 issue stop/queue stop으로 log·pending·events를 만든다. 후보 packet은 별도 정상 owner의 capture로 만들며 payload를 수정하지 않는다. 입력→packet→별도 prepare의 metadata, 값, 순서 및 유일 변경점을 독립 오라클로 확인한다. Array class/script는 metadata만 있고 값은 없는 빈 Array로 만든다.

| 이름 | 유일 변경 및 성공 기준 |
|---|---|
| metadata_01_same_typed_context | 동등한 별도 typed Dictionary와 typed Array의 metadata·값·키/순서. 동일 handle에 새 sim 복원 |
| metadata_02_array_builtin_control | 같은 값 [7]인 Array[int]와 untyped Array. builtin 차이 확인 후 mismatch 및 active 불변 |
| metadata_03_array_class_control | 빈 Array[Node]와 Array[RefCounted]. builtin/object와 null script가 같고 native class만 다름을 확인 후 mismatch 및 불변 |
| metadata_04_array_script_control | 빈 Array[FleetState]와 Array[BattleState]. builtin 및 native class가 같고 canonical script identity만 다름을 확인 후 mismatch 및 불변 |
| metadata_05_dictionary_metadata_boundary | 같은 key/value·삽입순서인 Dictionary[String,int]와 untyped {"k":7}. 컨테이너 builtin metadata 차이를 확인하고 실제 복원 수용·거부를 별도 기록 |

독립 오라클은 Dictionary/Array builtin/class/script, Variant 타입·값·키 타입/순서·Array 순서와 owner/active sim·독립 script property snapshot·log/pending/events·ready/busy·원 packet을 비교한다. context 거부에서는 활성 상태 및 packet 보존과 정상 advance 후 pending 소비를 확인한다. 마지막 사례에서 실제 수용되면 active sim 교체 여부, packet 불변, 이전 owner context 및 준비된 후보 metadata를 각각 기록한다. 이를 exact context 보장으로 집계하지 않고 **계약 격차**로 보고한다. 거부되면 이유와 실패 원자성을 기록한다. 유일 변이 사전조건 실패나 정해진 두 결과와 다른 상태는 실패다.

실제 Godot exit0은 명명 5개와 positive/Array controls, Dictionary 결과 분류 및 보존 검사가 끝난 **관측 절차**의 성공이다. 별도 `dictionary_contract`에 `MATCH` 또는 `MISMATCH`를 남긴다. 격차를 제품 계약 PASS로 바꾸거나 기대값을 사후 변경하지 않는다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.

새 실행 전에 branch/HEAD/index 및 새 dirty 분모를 확인한다. 정본 class map·실제 Script 경로/identity, console/본체 각각 SHA와 runtime PID/경로, 전용 Job/timeout, 전이 소스·데이터·runner·입력 전후 SHA, 실제 exit·stdout/stderr·오류/경고/누수는 선행 gate의 요구를 따른다. 전용 .gdignore 및 명시 headless script 경로를 사용한다. editor import 없음. 새 K6 범위이며 사용량 제한 발생 즉시 보고하고 반복하지 않는다. 독립 계획 수용 전 코드·Godot 실행 금지.
