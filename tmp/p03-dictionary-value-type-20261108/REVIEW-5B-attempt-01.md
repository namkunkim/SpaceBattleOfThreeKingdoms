# P03 Dictionary 값 metadata 독립 5-b

2026-11-08. **관측 절차 수용, 계약 불일치 MISMATCH 확인**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인이 아니다. 심사자는 구현에 참여하지 않았다.

attempt-01 actual Godot exit0은 관측 절차의 성공이다. 3명명/48 단언, 오류·경고·누수0, 전용 Job 총2/active0. 실제 engine/console·정본 class map/소스 포함 45개 입력의 전후 및 현재 SHA 독립 재계산 차이0, runner snapshot 동일을 확인했다.

실제 active `Dictionary[String,int]`와 후보 `Dictionary[String,Variant]`는 key metadata 및 keys() typed Array가 같고 실제 key/value는 String `k`와 int7로 같다. 입력·capture·별도 prepare까지 value builtin만 int에서 Variant로 다름을 유지했다. 그런데 active restore는 `ok:true`로 동일 handle의 sim을 새 후보 상태로 교체했고 원 owner의 int value metadata는 유지됐다. 이는 exact typed context 요구에 대한 **실제 단방향 반례**다. 동일 typed 양성은 성공했고 plain 후보의 key metadata 차이는 정확히 거부됐다. 절차 통과를 계약 PASS로 해석하지 않는다.

이 관측만으로 역방향, object class/script value metadata 또는 전체 Cn·외부 schema를 판정하지 않는다. 공유 production 수정은 이 심사 범위에 없다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 유지. 보존·패키지는 별도 closeout이다.
