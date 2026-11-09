# P03 종료 하위걸음 계획 독립 심사

2026-11-08. 판정: **계획 수용**, 제한 POC fixture에 한정한다. 실행 gpt-6.1-sol과 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델을 확인한 주장은 아니다. 심사자는 구현에 참여하지 않는다.

원문 `debug_damage`는 실제 damage/격침 경로를 호출하고 `_substep`은 적 생존 수 0과 증원 없음에서 `_end(true,"annihilation")`을 호출한다. `_tick`은 하위걸음 중 over에서 중단하며 dt를 복구한다. 계획은 피해 전제와 그 후 over=false를 검사하고, 1/100에서 실제 한 번 전진한 2/150과 종료 필드·사건을 수기/raw twin과 비교한다. 종료 전 packet 복원 뒤 피해 재주입 없이 같은 step을 재실행하고, 미소비 terminal packet 복원 및 drain을 별도로 검사한다. 이 조각은 기존 주입 종료나 suffix 검사와 구분된다.

5-b에서는 debug hook의 실제 피해 단위·대상 ID 및 원본 사건 소비, terminal 사건의 전체 payload, raw twin의 별도 초기화, 복원 전 실제 상태 변화와 같은 handle/new sim, exact 상태·타입·순서·packet 불변 및 빈 재-drain을 반증한다. 엔진 console/본체·실제 PID·정본 class map/Script identity·전이 입력 SHA와 bounded Job timeout을 확인한다. fixture precondition 불성립이나 oracle 변경은 사후 완화하지 않고 재심사한다. 선행 suffix는 변경 전 owner에서의 역사 실행이다.

제품 정상 피해 경로, host/worker, 모든 활성 모듈·typed 객체 컨테이너 및 terminal 이후 호출 정책은 범위 밖이다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 유지. global cursor나 외부 효과 exactly-once는 결정하지 않는다.
