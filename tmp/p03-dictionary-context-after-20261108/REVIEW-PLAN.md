# P03 Dictionary context 수정 계획 독립 심사

2026-11-08. **승인된 한 hunk 구현 계획 수용**. 사용자가 OperationPrivateState의 Dictionary context 비교 수정·검증을 명시 승인했다. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인은 아니다. 심사자는 구현에 참여하지 않는다.

허용 변경은 `_context_same`의 Dictionary 분기에서 key/value builtin·class·script 6 metadata를 정확 비교하는 삽입뿐이다. script는 identity, 기존 keys 순서/값 재귀 및 Array 분기는 보존한다. 대상은 untracked이므로 기존 c555… 바이트와 단일 prefix/suffix 삽입을 직접 대조하고 동시 P02 변경은 되돌리지 않는다.

before 13개는 동일 입력·방향·prepare와 불변 단언으로 행별 대조해 6 MISMATCH만 정확 원자 거부로 바뀌고 나머지7 결과는 유지해야 한다. key builtin/class/script 양방향·같은 metadata/빈 Dictionary, 완전 typed/untyped 양방향, 명시 controls 및 이후 pending 정상 소비도 별도 검사한다. P2c fresh, active replace, viewer 접점, same-tick suffix를 각각 지정 runner·실제 exit/마커/분모와 독립 입력/engine SHA로 회귀한다. 각 source 변경 또는 오라클 전제 실패는 성공으로 간주하지 않는다.

5-b에서 단일 hunk의 실제 전후 바이트, 6 metadata 비교와 identity, 독립 fixture의 단일 변이 및 거부 시 sim/context/packet/busy·정상 후속, 정본 class map/engine body·console 및 4 회귀 원문을 검증한다. 공유 파일의 다른 P02 변화는 보존·분리한다. 수정 범위는 활성 unsupported·host/저장 schema/global cursor를 포함하지 않으며 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 유지.
