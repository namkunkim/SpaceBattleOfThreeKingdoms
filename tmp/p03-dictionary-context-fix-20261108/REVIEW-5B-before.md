# P03 Dictionary context before 독립 5-b

2026-11-08. **관측 절차 수용, 계약 불일치 6/6**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인은 아니다. 심사자는 구현에 참여하지 않았다.

attempt-01 Godot actual exit0, 5명명/13 논리 입력/188 단언, 오류·경고·누수0, Job 총2/active0. engine console·본체, class map·정본 소스 포함 46 입력의 전후 및 현재 SHA 독립 재계산 차이0, runner snapshot 동일이다. exit0은 관측 절차 완결이며 계약 통과가 아니다.

동일 typed 양성은 교체 성공했다. Dictionary value builtin int↔Variant, 빈 객체 native class Node↔RefCounted, 빈 객체 script FleetState↔BattleState 각각 양방향 6/6에서 keys 배열과 실제 내용은 같고 metadata 축 하나만 다른 독립 준비 후보가 `ok:true`로 기존 handle의 sim을 교체했다. 최초 int→Variant 1은 앞선 반례 재현, 나머지 5는 이 관측의 추가 사례다. 기존 key metadata·실제 키 타입·순서와 Array builtin/class/script 6 대조는 정확히 거부하고 상태를 보존한 뒤 정상 진행했다. 값 객체 class/script 사례는 빈 Dictionary이며 객체 값 지원을 입증하지 않는다.

이는 공유 owner 수정의 승인이 아니다. P02 소유권 합의 및 현행 diff·별도 계획 수용 후에만 수정 후보를 다룬다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 유지. 보존·압축은 별도 closeout이다.
