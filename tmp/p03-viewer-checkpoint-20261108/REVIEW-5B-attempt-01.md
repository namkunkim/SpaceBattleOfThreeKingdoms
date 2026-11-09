# P03 viewer 사건 packet 독립 5-b

2026-11-08. **제한 fixture 수용**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인은 아니다. 심사자는 구현에 참여하지 않았다.

attempt-01 Godot actual exit0, 4명명/47 단언, 오류·경고·누수0, Job 총2/active0. engine console·본체, 정본 class map·source 및 P02 fixture를 포함한 입력47개의 전후 및 현재 SHA 독립 재계산 차이0, runner snapshot 동일을 확인했다. 정상 실행에서 timeout은 발생하지 않았다.

독립 raw/side0/side1 native 인스턴스 각 하나의 상태와 수기 전체 payload에서 raw spawn1/spawn2/say1/say2, side0의 1번 둘, side1의 2번 둘을 확인한다. owner A를 nonempty queue에서 캡처해 side0으로 숨김 사건까지 소진하고, 추가 advance 전 B를 캡처한다. 실제 추가 advance 이후 A 복원 시 raw에 숨긴 사건까지 순서대로 나타나고, 별도 A 복원 side1 결과는 다른 가시 둘을 반환한다. nonempty A에서 B 복원은 raw·양 필터가 비어 있으며 clock/contacts 및 A/B packet은 불변이다. sim 교체·binding 및 타입/순서 비교도 확인했다.

이 결과는 해당 far 서비스 fixture의 in-memory packet/파괴적 drain 접합에 한정한다. 외부 ack·dedup, P02 전체 filter matrix, 전체 Cn/저장/global cursor는 입증하지 않는다. Dictionary value metadata 격차는 별도 미해결이다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, save schema UNCLASSIFIED 유지. 보존·패키지는 별도 closeout이다.
