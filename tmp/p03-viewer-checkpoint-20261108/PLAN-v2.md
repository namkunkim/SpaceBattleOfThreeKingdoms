# P03 표시용 사건 packet 계획 보완 v2

2026-11-08 KST. [PLAN.md](PLAN.md)의 모호한 회수·advance 시점을 고정한다. 쓰기 범위와 명명 분모는 그대로다.

far 제한 fixture는 P02 viewer 원문 `typed_profile("far")`의 typed roster, seed0/hz10/direct 두 개, foe x1550을 사용한다. 두 stop은 side0/fleet1 다음 side1/fleet2이고 실제 advance 한 번 뒤 tick1에서 packet A를 capture한다. 당시 raw는 **spawn(1), spawn(2), say(stop,1), say(stop,2)** 순서 4개다. side0은 spawn(1), say(stop,1), side1은 spawn(2), say(stop,2) 순서 2개씩이며 반대쪽 두 사건은 숨겨진다. 네 사건의 발생 tick0, stop payload와 Vector2 위치, typed event Array 및 key 순서를 전체 대조한다. counts/visibility가 다르면 실패이며 이후 다른 사례로 대체하지 않는다.

독립 native raw/side0/side1 기대는 각각 **별개로 생성한 raw BattleSim 인스턴스**에서 동일 초기 profile/controls와 stop/advance를 수행한 뒤 단 하나의 해당 destructive drain으로 얻는다. 한 twin을 회수 순서대로 재사용해 빈 기대값을 만들지 않는다. 같은 fixture의 lookup/contacts 및 상태는 drain 전 따로 관측한다.

실제 owner에서 A를 capture한 뒤 side0 drain 성공 **직후, 추가 advance 전에** B를 capture한다. B의 tick/clock·contacts는 A와 같고 raw events는 비어야 한다. 이어 raw/side1 빈값을 확인한 뒤 추가 실제 advance로 tick 증가를 증명하고 A를 복원한다. 각 A 소비 분기는 A를 복원한 새 sim으로 시작한다. 04는 A의 nonempty 상태를 먼저 복원한 직후 B를 적용해 빈 raw/양쪽 필터를 확인한다. A와 B는 전 과정에서 exact 불변이어야 한다. 외부 이벤트 ack는 별도다.
