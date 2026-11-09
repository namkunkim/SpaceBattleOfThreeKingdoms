# P03 종료 하위걸음 독립 5-b

2026-11-08. **제한 fixture 수용**. 구현 gpt-6.1-sol과 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델의 확인은 아니다. 심사자는 구현에 참여하지 않았다.

attempt-01의 Godot actual exit0, 4명명/31 단언, 오류·경고·누수 진단0과 전용 Job 총2/active0을 확인했다. 콘솔과 실제 본체, class map, 정본 소스 및 runner 등을 포함한 입력45개는 전후 동일했고 현재 SHA 독립 재계산 및 runner snapshot 대조도 차이0이다. runtime 본체 경로/PID 및 정본 script/binding guard가 기록됐다. Job helper는 선행 timeout probe에서 사용한 helper와 동일 바이트이며 이 정상 실행에서 새 timeout은 발생하지 않았다.

원문 및 검사에서 피해량은 현재 ships 밀리척+1000이며 foe id2에 debug_damage를 양쪽 동일하게 적용한다. tick1/clock100·over=false, 마지막 적 격침 및 피해 사건 선소비 후 capture한다. 실제 core 첫 하위걸음으로 tick2/clock150·end2/150·sub50·복원 dt0.1·annihilation과 단일 battle_end 전체 payload를 raw twin과 수기 값으로 대조한다. 종료 상태에서 pre-terminal packet을 같은 handle/new sim으로 복원해 피해 재주입 없이 한 번 전진한 상태·사건을 대조하고, terminal packet 복원 뒤 사건 drain과 빈 재호출 및 packet 불변을 확인한다. 정밀 비교는 Variant 타입/값과 Dictionary 키 타입·삽입순서, Array 순서·typed metadata 및 script/binding을 포함한다.

수용은 테스트 전용 피해 훅을 이용한 제한 POC owner 사례다. 정상 플레이의 피해 흐름, 모든 활성 모듈·host/worker, 비어 있지 않은 typed class/script 컨테이너 및 terminal 이후 호출 정책은 입증하지 않는다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED를 유지한다. 보존·패키지는 별도 closeout이다.
