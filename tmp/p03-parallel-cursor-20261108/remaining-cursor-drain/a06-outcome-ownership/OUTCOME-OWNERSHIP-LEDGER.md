# A06 전장 결과 전달과 효과 완료 경계

코드 범위는 현재 수동 WorldLink 및 지도 legacy 자동결산 경로다. 결과 DTO가 게시·표시 경로에 들어가는 지점과 A06의 운영 효과 완료를 구별한다.

| ID | 입력·소유자·원문 | 반환 및 변이 | 이 경계에서 확인 가능한 완료 신호 |
|---|---|---|---|
| O01 | 전장 _pump 및 수동 종료, scripts/FleetBattle3D.gd:562–567,728–729,432–436 | _pump가 side0 사건을 소진하고 trace와 _on_event를 호출한다. battle_end는 end_game을 호출한다. 별도 back_to_world는 link 존재와 sim.st.over를 확인해 BattleOutcome 또는 null을 넘긴다. | 전장 로컬 사건 처리와 반환 시점의 종료 상태가 각 근거다. 종료 사건 자체가 지도 슬롯의 생성 또는 표시 완료 신호는 아니다. |
| O02 | 결과 데이터 변환, scripts/world/battle_outcome.gd:26–64 | from_sim은 facts_from_sim으로 승패·이유·논리 시간·복사된 결과·fingerprint를 받고 from_facts가 brief와 합쳐 DTO를 반환한다. 결산 유무에 따라 등급·손실·지휘관 정보를 계산한다. | 결과 객체가 완성되는 경계다. 계산된 결산 필드의 존재는 월드에서 지급하거나 표시했다는 확인이 아니다. |
| O03 | WorldLink 전환 및 슬롯, scripts/world_link.gd:18–35 | go_battle은 brief를 설정하고 이전 outcome을 null로 비운 뒤 전환을 요청한다. back_to_world는 outcome을 넣고 brief를 비운 뒤 지도 전환을 요청한다. take_outcome은 스냅샷을 지역 변수에 담아 슬롯을 비운 후 반환한다. | 슬롯 설정과 전환 요청, 단일 메모리 take가 각각 관측된다. 해당 코드가 scene 전환 반환값을 분기하거나 성공 ACK를 저장하지 않는다. |
| O04 | 지도 소비와 표현, view/world/world_map_screen.gd:60,97–106,622–657 | 초기 프레임 대기 뒤 take를 호출한다. 값이 있으면 _show_result에서 지도 로컬 outcome과 화면 상태를 정하고 결과를 표시하며, 지역 소유 표시 변경은 0.6초 타이머 및 state 조건을 거친다. 값이 없으면 탐색 화면으로 간다. | 슬롯 take, UI 상태·결과 패널 설정, 후속 지도 시각화는 서로 다른 시점이다. 이 경로의 canvas 업데이트를 지급 또는 durable 커밋 완료로 집계할 근거는 없다. |
| O05 | legacy 자동결산, scripts/world/auto_resolver.gd:72–102,133 및 view/world/world_map_screen.gd:600–620,672–685 | 지도는 resolver.start 성공 뒤 resolve 상태를 표시한다. poll은 worker 완료 후 join하고, 취소면 false로 끝나며, 유효 facts 또는 join 뒤 sim에서 DTO를 만든다. 지도는 poll true에 resolver.outcome을 _show_result로 직접 넘기고 취소는 resolver를 비워 탐색으로 간다. | join, 결과 DTO, poll true, 지도 표시가 별개다. 이 legacy 지도 경로는 WorldLink take 없이 직접 표시하며 별도 start_operation 계열의 계약을 이 관측으로 확정하지 않는다. |

## 교차 반례

1. **take 뒤 표시 실패 가정**. 지도 _ready의 take 전에 WorldLink가 슬롯을 비우는 것이 아니라 take 내부에서 반환 전에 비운다. _show_result는 이후 호출된다. 이 두 경로에 표시 실패를 받아 슬롯을 다시 채우는 분기는 없다. 실제 scene 실패·예외·복구는 실행하지 않았다.
2. **결과 없음 및 새 전투**. take의 null 결과는 지도에서 탐색 분기를 선택한다. 새 go_battle도 이전 outcome을 지운다. 이 코드에는 null의 원인이 소비·취소·새 전투 중 무엇인지 판별하는 효과 키나 지급 ACK 반환이 없다. 세 경우의 제품 정책을 합치지 않는다.
3. **legacy 취소 대 poll 완료**. worker가 취소를 보면 null을 반환하고 poll도 join 뒤 취소 상태를 검사한다. 지도 취소는 resolver를 제거한다. 정상 poll true는 DTO의 존재와 지도 표시 분기로 이어진다. WorldLink의 슬롯 소거 호출을 경유하지 않으므로 같은 보존/중복 정책을 제공한다고 추론하지 않는다.

## 역사 근거와 미결

P03 기존 HOST-STATE-LEDGER의 host 준비·trace·WorldLink 분리와 P02 호스트 준비/게시, legacy 자동결산 결과 문서를 역사 범위로만 인용한다. 독립 수용 cursor/drain의 시험 외부 Array 재수신은 지도 지급 실행 증거가 아니다. 이 원장은 Godot 없이 소스 경로와 결과 문서만 대조했다.

H2-02는 상태+후속 명령과 초기 동일 규칙 지원 방향이다. D04 ST02/ST18과 I01 A06은 적용 순서·효과 완료·owner 경계·활성 보존을 각각 요구한다. 정책 후보로 효과 표식과 실제 효과의 부분 실패를 별도 가상 수신기로 대조할 수 있다. 키·epoch 발급, 커밋 및 복구, 외부 ACK와 지속성은 미결이다. P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
