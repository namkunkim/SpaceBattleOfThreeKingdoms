# P03 보급 혼합 packet 관측 계획 독립 심사

2026-11-08. **제한 관측 계획 수용**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인이 아니다. 심사자는 구현에 참여하지 않는다.

실제 완료 전 A와 완료·사건 drain 후 B를 독립 raw twin 및 수기 재고/repair·누계·사건과 대조한다. C는 B의 손님 `sup_prog` 하나만 A의 실제 값으로 바꾼 사본이고 B 정상 후속 한 step을 별도 대조한다. 허용/거부와 다음 step의 실제 결과를 분류하며 단순 progress만 복원하면 중복 지출이 반드시 발생한다고 선결론내지 않는다. 손상 배열·AI 타이머 통제는 정상 플레이 재현이 아니다.

5-b에서는 각 fixture 전제·A/B/C exact 단일 변이, 완료 전후 자원 및 event drain, raw twin 독립성, 실제 sim 교체/거부 시 불변과 정상 진행, 분류별 다음 step을 확인한다. mismatch가 다른 필드에도 있다면 실패다. 엔진·class map·전이 입력 SHA/Job 및 보존 근거도 별도 검사한다. 이 관측은 외부 저장 commit 정책을 정하지 않고 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED를 유지한다.
