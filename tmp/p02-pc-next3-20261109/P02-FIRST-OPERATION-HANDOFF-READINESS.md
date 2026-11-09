# 첫 PC 직접 작전 입력 인계 준비

상태는 정적 준비다. 실제 작전 데이터와 fresh owner의 제품 계약을 기다린다.

## 확인한 경로

- WorldMapScreen.make_brief는 seed, 난이도, 모드, 표시 anchor/edge_labels를 작성한다. sortie는 현재 지도 표시 일부를 _sortie_origin에 두지만 _finish_sortie가 이를 비운다. 즉시 장면 호출 거절이면 살아 있는 지도에 복구할 수 있다. 장면 변경이 성공하면 해당 지도 인스턴스가 사라진다.
- BattleBrief는 기존 적벽 scenario_id를 기본값으로 가지며 작전 지원 표식·정의 식별자·승인 편성 선택이 없다. 현재 직렬화는 legacy 용도이며 operation 판정에 필요한 계약을 제공하지 않는다.
- WorldLink.go_battle은 이전 Brief, 대기 Outcome, 난이도 및 모드를 지역 변수에 보관한 후 scene 호출이 즉시 거절될 때 복원한다. 전장 준비 실패는 이 시점 이후다. WorldLink.back_to_world(null)은 안전 복귀를 제공하지만 이후 새 지도는 last_difficulty/last_mode와 비어 있는 Outcome으로 기본 browse를 열기 때문에, 출격 전 카드나 결과 상태·대기 결과를 복구할 수 없다.
- FleetBattle3D.init_game은 실패한 후보를 게시하지 않는다. 준비 단계는 현재 raw BattleSim을 만들고, P02 난이도는 승인된 기존 적벽 경로에서만 선택한다. 첫 작전용 owner 또는 결산 DTO 연결은 없다. 제한 P03 adapter에 현재 적벽/작전 지원을 억지로 넣으면 scenario·AI·증원·정책 모듈 가드와 충돌한다.

## 선행 계약

- P02/P03: 작업 정의의 지원 표식·ID·버전, schema 필드/자료형과 검증 오류, 난이도 및 편성의 정확한 출처와 선택 시점, 지원 밖 표식의 거부 위치, fresh prepare 결과 및 최초 게시/close 조건, 장면 변경 완료·준비 실패 복귀의 승인 시점.
- P05/P03: source/effective 분리와 입력 공급 경계, 공간 버전·원점·field identity, 승인 자세·경계 포함/이동·정지·그룹 편차 계약, candidate 반폭·서비스/배치/철수·R/C 수치의 채택 여부. P02는 이 값을 중복 검증하거나 데모 guard를 복제할 이유가 없다.
- P07/P03: 준비에 필요한 정책 정의 버전 및 필드, 점령·가동 자격/시간, 유한 장부·주기·비용, 증원·봉쇄 해제, 시한·생환 및 terminal 동시 우선순위. 결과 화면 연결에서는 immutable settlement ID, 종류, 사유, 논리시각 및 비용 계약을 별도로 확정한다.
- P03의 최신 bridge 자료는 restore 정적 준비에 관한 것으로 fresh first-operation capability의 증거가 아니다. 운영 저장·복원이나 외부 schema를 이 출격 요청의 필수 입력으로 사용하지 않는다.

## 구현 가능한 첫 조각

공통 계약이 동결되면 P02의 첫 조각은 **작전 요청과 지도 복원 표식의 일회 인계**다. WorldMapScreen에서 기존 선택을 새 Brief에 동결하고 WorldLink에 별도의 메모리 전용 지도 복귀 상태를 둔다. FleetBattle3D는 지원 표식을 보고 P03 준비 경계로 한 번 전달하며, 후보 준비 성공 때만 준비를 확정한다. 최초 준비가 실패하면 P03 후보를 폐기하고 기존 오류 안내에서 안전 복귀를 시도한다. WorldLink가 최초 지도 선택·화면 상태와 대기 결과를 해당 scene 왕복에만 복원한다. 즉시 scene 거절에서는 기존 rollback 경로를 사용한다. 지원 표시 실패는 기존 적벽 fallback으로 이어지지 않는다. legacy 경로는 기존 계약을 보존한다.

공통 스키마 없이 이 코드 조각을 제품에 추가하지 않는다. 독립적으로 가능한 준비는 기존 증거에서 즉시 출격 거절·전장 초기 준비 실패·복귀 거절의 기준선 행을 재사용하고, 다음 검증을 fixture 입력·기대 관측으로 분해하는 것이다.

| 경계 | 최소 검증 |
|---|---|
| M1 준비 입력 | 고정 seed/난이도/편성/정의 식별자가 지도→Brief→WorldLink→검증된 준비 경계까지 동일. 독립 fixture의 값과 대조. |
| M2 즉시 거절 | 원래 지도 인스턴스, 기존 Brief/대기 Outcome, 선택·입력 잠금 및 결과 표시가 복원. owner prepare 호출 0. |
| M3 장면 성공 뒤 준비 거절 | 전장 활성 owner/두 시계/진행 및 결산 게시 0. 복귀 첫 시도 거절이면 후보와 인계 상태를 소비하지 않는다. 성공한 복귀에서 원래 카드/결과 상태 및 대기 결과를 승인 규칙대로 한 번 복원. 정상 출격 재시도 가능. |
| M4 기존 작전 재준비 실패 | 같은 프레임에 owner ID, 시계·phase, UI·카메라·선택, trace·사건 큐, Brief/Outcome 상태 보존. |
| M5 호환성 | 표식 없는 기존 직접·자동·standalone이 기존 경로를 사용. 지원 밖 표식은 구조화 오류와 결과 없는 안전 복귀. |

기준선 관측은 기존 direct-scene-reject, world-return-reject/notice 및 focused-normalized/edges 결과를 읽어 사용한다. 가짜 owner는 차후 계약 단위 검증에서만 허용하며 실제 첫 작전 결과로 세지 않는다. P05의 기하와 P07 정책은 각 소유자의 오라클을 그대로 참조한다. 물리 GUI 검증은 별도이며 PC0는 재실행하지 않는다.
