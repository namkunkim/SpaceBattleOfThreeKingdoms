# P03 지원 밖 활성 DecisionBoard 독립 5-b

2026-11-08. **제한 관측 수용: ACCEPTED_DROPS_ACTIVE_MODULE**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인이 아니다. 심사자는 구현에 참여하지 않았다.

attempt-02 Godot actual exit0, 3명명/15 checks, 오류·경고·누수0, Job 총2/active0. console/본체·class map·source 포함 45 입력의 전후 및 현재 SHA 독립 재계산 차이0, runner snapshot 동일이다. attempt-01 파싱 실패는 보존한다.

정상 owner의 C0 복원과 같은 suffix를 대조했다. 별도 live owner에 실제 한 tick 후 테스트가 DecisionBoard와 `_seq=47`을 강제로 붙이자 capture는 `unsupported_active_decisions`로 거부했고 marker·참조·활성 상태와 packet은 보존됐다. 같은 context의 독립 준비 가능한 C0 packet을 restore하자 `ok:true`, 같은 handle의 새 sim으로 교체됐으며 활성 sim의 DecisionBoard는 없었다. marker는 별도로 보유한 이전 sim/모듈에만 남아 있다가 fixture가 참조를 정리했다. 교체된 새 상태와 정상 C0 suffix는 독립 후보와 같았다.

이는 의도적으로 지원 밖 모듈을 삽입한 fixture에서의 실제 동작이다. 정상 제품 경로에서 해당 상태가 도달 가능한지, 운영 정책 위반인지, 일반 스레드/host 원자성을 입증하지 않는다. 이 관측을 정상 운영 지원으로 승격하거나 수정 소유권을 추정하지 않는다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 및 기존 미해결 계약 유지. 보존·패키지는 별도 closeout이다.
