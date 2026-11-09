# P03 접촉 만료 시험 fixture 보완

2026-11-08 KST. attempt-01/03은 lost precondition의 좌표 고정이 실패했다. attempt-02는 실패 진단 추가 시 GDScript 타입 추론으로 parse exit1이었다. 모두 원문 보존, K6 사용 3. attempt-03에서 별도 raw 세 인스턴스 모두 `tick2410/clock241000`, 살아 있는 foe, seen1/last known (625,500), estimated11/lost1811을 충족했다. 다만 실제 좌표가 (2294.116,1499.064)로 이동했다.

`ai/poc_enemy_ai.gd:37–43`는 기함이 home에서 멀어지면 원래 home으로 되돌리는 명령을 낸다. 최초 실제 접촉 확인 이후 기존 통제 좌표 `pos=HIDDEN`과 함께 **fixture의 foe home도 같은 HIDDEN으로 옮겨** 이 왕복 기동을 제거한다. 이것은 플레이 동작이 아닌 테스트 상태 통제다. 양쪽 simulation에 같은 변경을 넣고, 추가로 clock/book/사건/평가 루틴을 바꾸지 않는다. 최초 관측·전이·만료 tick이나 실제 phase를 완화하지 않는다. 만료 직전과 직후 실제 foe.pos가 HIDDEN과 정확히 일치해야 하며, LAST와 다른 이를 raw/side0 이벤트의 실제 payload와 비교한다. 독립 계획 수용 후 다음 K6 실행만 진행한다.
