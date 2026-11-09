# P02 첫 PC 작전 요청과 fresh 준비 경계

검토용 제안. 첫 범위는 지도 직접 출전, fresh 준비, 초기 표시와 실패 보존까지다.

## 확정 가능한 경계

- 현재 WorldMapScreen.make_brief는 seed·난이도·mode 및 표시 anchor/edge_labels를 전달한다. BattleBrief.scenario_id 기본값은 RED-CLIFFS-208-RT다. 기존 ID, 직렬화, 직접 적벽·자동 해결·standalone의 의미를 유지한다. 표시 필드를 규칙이나 편성 입력으로 사용하지 않는다.
- P02는 지도 선택·장면 이동·표시를, P03은 fresh 후보와 권위 시계·투영·사건을, P05는 source 및 공간·외곽을, P07은 작전 규칙과 결산 의미를 소유한다. 첫 작전은 명시적으로 식별된 직접 출전만 받는다. 기존 제한 adapter의 허용값을 넓히거나 raw sim에 직접 대입할 근거는 없다.
- 현재 호출은 make_brief → sortie → _finish_sortie → WorldLink.go_battle → FleetBattle3D._ready → init_game → _prepare_game → 성공 시 _publish_game이다. 정상 복귀는 FleetBattle3D.back_to_world → WorldLink.back_to_world → 새 WorldMapScreen._ready의 take_outcome이다.

## 제안할 최소 입력과 결과

| 경계 | 제안 |
|---|---|
| BattleBrief | 기존 seed·difficulty·mode를 재사용한다. 선택적 작전 요청에는 지원 표식, 불변 정의 ID와 버전, 승인 roster ID만 둔다. roster 출처는 정의가 고정한 버전 붙은 카탈로그에서 ID로 해석한다. 별도 roster 버전은 정의가 참조 버전을 고정할 수 없을 때만 필요하다. 원시 지도·편성 사본 또는 effective는 Brief에 넣지 않는다. |
| P03 준비 입력 | 지원 표식·정의 ID/버전·roster ID·seed·난이도·direct를 검증하고 승인 정의에서 P05 source 및 P07 규칙을 찾는다. P03이 P05 source를 별도 effective로 한 번 변환한다. 유효한 E 초기 아군, C 수비 및 R 진입 정의를 확인하고 독립 fresh 후보를 만든다. |
| P03 성공/실패 | 성공은 후보 owner와 준비된 초기 tick/clock·phase·side 투영, 필요한 source/effective 식별 정보다. 실패는 안정 reason과 field path로 제안한다. 지원 표식/버전, 선택 조합, source/effective 혼용, 배치 오류를 구분한다. 세부 필드명과 코드값은 소유자가 동결한다. 실패 후보만 닫으며 기존 owner·시계·큐를 보존한다. |
| P02 게시와 실패 | 지도에서 선택을 한 번 고정하고 WorldLink는 해당 전환에 귀속된 메모리 UI 복귀 정보를 보관한다. 즉시 장면 거절이면 기존 지도와 Brief·Outcome·선택을 복구하고 P03 준비를 호출하지 않는다. 장면 승인 후 FleetBattle3D가 fresh 후보를 준비한다. 초기 투영까지 성공한 뒤에만 owner·첫 화면·시계 연결을 함께 게시한다. 최초 실패는 플레이나 새 결과를 게시하지 않고 기존 지도 UI로 안전 복귀한다. 복귀 호출이 거절되면 실패 화면과 복귀 정보를 유지한다. 명시 작전 요청의 준비 실패를 legacy 적벽 성공으로 바꾸지 않는다. |
| 후속 결산 인계 | P03 owner가 P07 계약의 결산 ID·유형·사유·논리시각을 한 번 확정한다. 전장과 지도는 동일 결산 DTO를 읽는다. 지도 scene 요청 거절은 대기 결산을 소비하지 않고, 성공한 새 지도에서만 한 번 소비한다. 최초 준비 실패 복원에서 이미 본 결과는 UI 사본으로 복원하며 신규 결산 큐나 효과 경로에 넣지 않는다. |

## 사용자 결정 및 후속 동결

사용자 결정은 P05 검증 후보 지도·배치와 측정 편성을 첫 제품 정의 v1의 출발점으로 채택할지, 다른 정본 지도·편성 및 난이도 적용 출처를 지정할지다. 정의와 roster의 관계, 난이도별 유효 조합은 그 선택에 따라 P02/P03/P05가 동결한다. P07의 증원·가동·유한 장부·시한·결산 세부값은 P07/P03의 후속 채택 사항이다.

독립 준비 검증은 동일 입력의 분리된 fresh 후보 두 개와 같은 초기 결과, 잘못된 표식·버전·roster·난이도 거절, 실패 전후 보존, 즉시 장면 거절 및 최초 실패 복귀 재시도를 확인한다. 제품 실행은 이 문서의 범위 밖이다.

근거는 [공통 계약](../pc-first-operation-contract-20261109/CONTRACT.md), [P02 인계 조사](../p02-pc-next3-20261109/P02-FIRST-OPERATION-HANDOFF-READINESS.md), [기존 UI 복원 계획](../p02-pc-next3-20261109/P02-LEGACY-INITIAL-FAIL-UI-RESTORE-PLAN.md)이다.
