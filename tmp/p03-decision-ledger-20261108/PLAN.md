# P03 다음 후보 — DecisionBoard 접수·만료·효과 원장

2026-11-08 KST. **읽기 조사 후보, 독립 심사 대기.** 최신 P02 revision10은 FleetBattle3D 준비/게시 경계의 독립 마감을 보고했다. 현재 chat idle이나 공통 owner 쓰기 권한이 P03으로 넘어갔다는 근거는 없다. owner SHA c5550999…9a6e 유지. 공유 파일에는 쓰지 않는다.

ChainOp 원장에서 발견한 card_id의 실제 소유자 `DecisionBoard`를 ST07/ST18 관점에서 좁혀 조사한다. 해당 모듈은 제한 private owner의 지원 밖이다. 정본 선언 8개와 동적 pending cards/done/retreat key의 타입·순서·ID, 실제 open/deadline/resolve/drop·권고 자동 적용·효과/이벤트, 시계와 ChainOp/사기/추격 참조를 경로와 함께 매핑한다. 카드 번호와 command/apply seq를 구별하고, 완료 기록을 외부 ack 원장으로 간주하지 않는다.

반례는 동일 tick deadline에서 외부 issue와 내부 자동처리 순서, ChainOp drop과 이미 적용된 효과의 구별, _crisis_armed/_seen_retreat를 초기화했을 때 중복 카드 발행이다. 제품 우선순위·복원 스키마를 결정하거나 실행 검증으로 집계하지 않는다. 8개 선언/3개 동적 상태/3개 반례, 원문 SHA·refs/index·링크를 검사하고 독립 문서 심사를 받는다. 문서 K3, 사용량 제한 즉시 보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
