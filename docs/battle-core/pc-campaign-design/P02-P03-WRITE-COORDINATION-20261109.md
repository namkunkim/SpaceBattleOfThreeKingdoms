# P02 K6 상태와 P03 공유 쓰기 조율

2026-11-09 08:48 KST 읽기 관측. 이 문서는 쓰기 예약이나 상대 작업의 승인이 아니라 파일별 순서 제안이다. HEAD `0be09755b70378286105972f35ac5b7031715664`, 관측 시 C: 여유 약 2.56 GB. 공유 파일은 동시에 변할 수 있으므로 실제 쓰기 직전에 다시 확인한다.

## K6 실제 분모와 수용

- 여덟째 공통 native 초기화 조각의 한도는 K1~K6 총 6회다. K1·K2는 비정본, K3는 일부 native 비교 통과, K4는 제품 버튼 viewport 정상 완료·취소를 확인했으나 별도 오류 후 재시도에서 175초 제한 뒤 join 단언 실패(exit 1), K5는 실제 입력 주체 불명으로 정본 제외다. **K6 0/1 실행, 전체 이력 5/6**이다. [중단 인계](../../../tmp/p02-eighth-20261108/SESSION-HANDOFF-INCOMPLETE.md)
- V5의 **21행·58개 프로세스·20,270초는 실행 전 계획 분모**다. 독립 심사는 7종 suite 실제 분모, GUI 전경·입력 귀속, 실제 Godot 자손·Job 검증 등을 이유로 K6 실행을 반려했다. 독립 5-b와 최종 마감 수용은 없으며 후보는 원본 제품에 미적용이다. [재개 인계](../../../tmp/p02-eighth-resume-8d838216ccfc/SESSION-HANDOFF-INCOMPLETE.md) · [V5 독립 심사](../../../tmp/p02-eighth-resume-8d838216ccfc/REVIEW-PREPARED-V5-INDEPENDENT.md)
- 직접 난이도 수정은 **별도 조각**이다. 최초 격리 실행 세트는 28개 계획 프로세스 중 import와 D01 두 개를 시작했고 D01 파서 오류로 중단됐다. 난이도 단언·후보·GUI 실행은 0이다. 따라서 이 실패를 K6 시도 또는 기준선 예상 실패로 집계하지 않는다. [독립 결과](../../../tmp/p02-pc-next3-20261109/prepare-01/REVIEW-ATTEMPT-01-INDEPENDENT.md)
- 난이도 실행 계획의 기존 시작 바닥은 2.9 GB이고 현재 약 2.56 GB로 미달한다. 이 수치를 K6 자체의 별도 공간 기준으로 일반화하지 않는다. 추가 제품·증거 삭제는 수행하지 않는다. 난이도 재실행에는 공간 확보, 수정 probe 및 유한 실행 계획의 독립 심사가 필요하다. K6에는 위 미해결 항목을 포함한 전체 입력 동결과 독립 실행 심사, 결과 독립 5-b가 필요하다. K6은 첫 PC 플레이의 기술적 선행조건으로 취급하지 않는다.

## 파일별 쓰기 창 제안

| 파일 | 현재 상태와 P02 접점 | P03에 제안하는 순서 |
|---|---|---|
| `scripts/FleetBattle3D.gd` | 현재 SHA `029a11be7c08038f2ed4a482f0b2668bd924c842c33a2a671409cd486f0191c9`. 기존 미커밋 변경은 `_build_prepare_error` 안내와 `back_to_world` 복구다. P02의 미적용 K6 후보는 `_prepare_game`의 생성·초기 제어 부분이고 별도 난이도 후보도 같은 함수에 닿는다. 게시·프레임도 향후 양쪽의 공유 경계다. | **공유 원본 쓰기 창 미확정.** P03 복원 진입·게시 후보는 격리본에서 준비한다. 실제 원본 쓰기 전 함수와 hunk, 전후 SHA 및 회귀를 서로 확인한다. `_prepare_game`, `_publish_game`, `_process`, `update_sim`은 겹칠 수 있으므로 순차 적용과 재동결이 필요하다. 기존 미커밋 안내·복구 hunk를 보존한다. |
| `core/battle/operation_runtime_adapter.gd` | SHA `0c0cad3e6e4e15887dcd75f9d5b57dbbe2690bfdcafd1caac163909b5421173a`, 관측 시 변경 없음. P02 K6 격리 후보의 `create_product_native` 추가 위치다. | P02는 K6 결과와 독립 5-b 전 원본을 쓰지 않는다. P03이 별도 hunk를 제안하면 격리 준비 후 동일 파일·호출 계약과 SHA를 재동결해 순서를 정한다. P02 후보와 무관하다는 확인 없이 동시 적용하지 않는다. |
| `core/battle/operation_private_state.gd` | SHA `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`. 기존 작업 트리에 `_context_same` typed dictionary 비교와 `restore_completed` 활성 decisions 거부 hunk가 있다. P02 K6 후보 패치 자체의 직접 변경 파일은 아니다. | 기존 P03 hunk는 보존한다. P03의 후속 owner hunk는 P02 격리 실행이 열려 있지 않은 현재 시점부터 준비·검토할 수 있다. 원본 쓰기 직전 P03이 범위와 SHA를 확인하고, P02 K6에 포함할 owner는 실행 전 before/after에 동일 바이트로 동결한다. 동시 실행 중 변경은 새 기준선으로 기록하고 재심한다. |
| `scripts/world/auto_resolver.gd` | SHA `85ec124df59c0c50cee616565e88bcdd978588f28baf36180f8ec2c92eebd9eb`, 관측 시 변경 없음. P02 K6 후보가 native 생성·auto 제어 초기화를 교체한다. | P02는 독립 5-b 이전 원본을 쓰지 않는다. P03에서 이 경로를 변경해야 한다면 hunk와 동일 snapshot 사용을 사전 조율한다. |

위 SHA는 관측값이며 잠금이 아니다. 기존 독립 증거는 원래 동결 입력에만 귀속한다. 공유 원본이 변하면 기존 기록을 수정·삭제하지 않고 새 입력과 결과를 별도로 기록한다. P03의 제품 복원 진입, 첫 프레임 시계·사건·UI 및 오류 시 기존 상태 보존은 공동 검증이 남는다. [기존 조율](../../../tmp/p02-ninth-20261108/P02-P03-OWNERSHIP-20261109.md) · [P03 준비 계획](../../../tmp/p03-product-restore-readiness-20261109/PLAN.md)
