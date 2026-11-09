# P03 다음 후보 — Dictionary 값 metadata 단일 변이

2026-11-08 KST. **독립 계획 심사 대기, 구현/실행 미착수, K6=0.** Sol 실행 / Terra 독립 심사 명시 배정, Astra 제외.

[직전 typed→untyped 관측](../p03-context-metadata-20261108/RESULT.md)은 양쪽 key 배열의 typed metadata 차이까지 포함했다. 실제 owner는 typed Array를 비교해 그 방향을 거부했다. 현재 Dictionary의 값 컨테이너 metadata 직접 비교는 읽기 조사에서 발견하지 못했다. 이번 후보는 key 타입이 같고 **value 타입만 다를 때** 실제 활성 교체가 어떻게 동작하는지 판정한다.

직전 제한 POC fixture를 사용해 active owner를 실제 한 step 진행한다. issue stop/queue stop으로 log·pending·event를 만든 뒤 별도로 준비한 후보 packet을 복원한다. 입력→capture→독립 prepare를 통과한 metadata 차이가 오직 값 builtin뿐인지 확인한다. Dictionary 요소는 양쪽 모두 String 키 `"k"`와 정수 7 한 쌍이다. key builtin/StringName class/script metadata와 파생 `keys()` Array metadata 및 원소 타입/삽입순서는 exact 동일해야 한다. 컨테이너 value metadata는 int와 Variant(NIL tag)로 달라야 한다. native class/script 값은 동일한 빈 metadata만 사용한다.

| 검사 이름 | 입·출력 계약 |
|---|---|
| value_type_01_same_context_control | active와 후보 각각 별도 `Dictionary[String,int]`. metadata와 값 동일, 동일 handle에 새 sim 복원, 새 runtime은 독립 prepare snapshot과 exact 일치 |
| value_type_02_key_derived_control | typed active `Dictionary[String,int]`와 plain 후보. 파생 keys Array typed 차이가 있으며 정확한 `replacement_context_mismatch`, active 및 packet 불변, 정상 advance 후 pending 한 번 소비 |
| value_type_03_only_value_metadata | typed active `Dictionary[String,int]`→typed 후보 `Dictionary[String,Variant]`. key/keys 배열 metadata는 exact 동일, value builtin만 int→Variant, 실제 값은 int7 유지. 후보 정상 prepare와 이 차이의 전 경로 보존을 확인한 뒤 실제 restore 응답과 상태를 분류 |

`MATCH`는 value-only 전제가 입증되고 정확한 `replacement_context_mismatch`와 active handle/sim, private context, log/pending/events, packet, busy 무변이 및 후속 정상 advance를 모두 확인한 경우다. `MISMATCH`는 같은 전제가 입증되고 restore가 성공해 동일 handle의 sim이 실제 교체됐고 새 runtime이 독립 prepare 상태와 exact 일치한 경우다. 성공에서도 active owner에 원 metadata가 남는지, packet 불변, ready/busy, 참조와 ID cache 새 binding을 비교한다. 허용되지 않은 이유의 거부·metadata 유실·파생 keys 차이·준비 실패는 관측 절차 실패다. 절차가 끝나면 actual exit0과 별도 `value_metadata_contract`를 기록한다. `MISMATCH`는 결함 관측이며 제품 계약 통과로 표기하지 않는다. 역방향·Dictionary object class/script metadata 및 비어 있지 않은 typed object 값은 범위 밖이다.

작성/테스트/증거는 이 신규 전용 폴더만 사용한다. P02 최신 소유 경로를 읽기 확인하고 OperationPrivateState/Service, adapter/host/replay 및 공통 체크리스트는 변경하지 않는다. P02 자동결산 변환은 별도 조각이며 fixture 입력에 포함하지 않는다. 기존 증거는 보존한다. branch/HEAD/index와 새 dirty 분모, 전이 소스·데이터·실제 class map/resource_path/identity, console/본체 SHA와 runtime PID·경로, 독립 Job, actual exit와 raw 로그/오류/경고/누수, 입력 전후 SHA는 선행 metadata gate와 같이 별도 동결한다. 새 명명 K6, 사용량 제한 즉시 보고·반복 금지. 독립 계획 수용 후에만 구현한다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
