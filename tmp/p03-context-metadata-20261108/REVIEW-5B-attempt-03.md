# P03 typed context 독립 5-b — attempt-03

2026-11-08. **관측 절차 및 사전등록된 단방향 사례 수용**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인이 아니다. 심사자는 구현에 참여하지 않았다.

Godot actual exit0, 5명명/76 단언, 오류·경고·누수0, Job 총2/active0이다. 엔진 본체·console, class map 및 소스를 포함한 46 입력의 전후와 현재 SHA를 독립 재계산해 차이0, runner snapshot 동일을 확인했다. attempt-01 파싱 실패와 attempt-02 사전조건 실패를 보존한다.

같은 typed context는 교체됐고, Array builtin·native class·script identity 단일 변이는 각각 정확한 context mismatch와 기존 sim/상태/packet 보존 후 정상 advance를 보였다. 빈 객체 typed Array의 metadata만 검증했다. Dictionary[String,int] active → 같은 key/value untyped candidate는 입력·packet·prepare에서 metadata 차이를 유지했고 정확한 mismatch, 실패 원자성 및 후속 진행을 보여 **이 사례의 MATCH**다. 기록된 `keys()` 결과는 각각 typed String Array와 untyped Array라 현재 Array 분기가 그 차이를 간접 감지한다. 이 관측은 Dictionary value 타입만 다른 경우, 역방향 또는 모든 typed Dictionary context의 완전성을 입증하지 않는다. `MATCH`를 전체 계약 PASS로 확대하지 않는다.

전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED다. 제품 코드 수정·전체 운영 Cn 및 global cursor는 범위 밖이며 보존·압축은 별도 closeout이다.
