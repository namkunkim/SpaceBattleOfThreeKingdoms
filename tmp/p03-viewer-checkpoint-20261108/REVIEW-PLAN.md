# P03 표시 사건 packet 계획 독립 심사

2026-11-08. **제한 계획 수용**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 모델 확인은 아니다. 심사자는 구현에 참여하지 않는다.

v2는 B를 side0 소비 직후·advance 전에 고정하고 raw/side0/side1 destructive oracle을 별도 native twin으로 분리했다. raw 네 사건 및 양쪽 가시 두 사건의 tick·순서·전체 payload를 사전등록했다. side0 소비 후 실제 advance 및 A 복원, A의 raw/side1 복원 분기, A nonempty에서 B 복원 후 빈 drain과 packet 불변이 각각 요구된다. 이는 외부 ack/dedup이나 모든 P02 필터 행렬의 승인이 아니다.

5-b에서 far fixture source와 독립 raw 상태·contacts, side별 숨김 사건 전제, 각 twin 독립성·events의 타입/순서/전체 값, B capture 경계 및 실제 advance·same handle/new sim/packet 불변을 확인한다. class map·actual engine 경로/두 바이너리·입력 SHA와 Job도 검사한다. 사전등록 전제 실패를 fixture 교체로 감추지 않는다. Dictionary value metadata 격차는 별도 미해결이며 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, save schema UNCLASSIFIED 유지.
