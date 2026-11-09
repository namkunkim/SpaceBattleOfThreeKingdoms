# P03 제품 호스트 운영 복원 인수 준비

## 현재 증거와 착수 조건

2026-11-09 기준 HEAD `0be09755b70378286105972f35ac5b7031715664`. 현재 작업 트리의 FleetBattle3D SHA-256은 `604b79308d9b3dbab84dced32456a4f41b28686c8eec748073d3816892cffc5c`, private owner는 `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`이다. owner 및 P02 진행표에는 기존 변경이 있다. 이는 준비 시점의 읽기 증거이며 실행 시 입력을 새로 동결한다.

생산 경로 `core scripts view hud input scenes`에서 `rg -n 'capture_completed\(|restore_completed\(|start_operation\(|suspend_requested|resume_requested' ... -g '*.gd' -g '*.tscn'`로 대조했다. private owner의 캡처·복원과 제한 worker 시작은 정의가 확인됐고, 조사 범위에서 제품 복원 호출은 발견하지 못했다. `SessionGuard`에는 suspend 신호가 있으나 그 신호가 저장 또는 복원으로 이어지는 호출자는 이 범위에서 확인되지 않았다. 간접·동적 경로에는 이 결론을 확대하지 않는다. 실제 3D 호스트는 `FleetBattle3D.gd:270`에서 새 전투를 준비하고 306행에서 raw BattleSim을 만든다. 316행의 게시가 sim과 시계를 교체하며 478행과 530행에 프레임·외부 update 경로가 별도로 존재한다.

[P02 진행표](../../docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md)의 legacy 후보 준비·오류 안내는 한정 수용이다. 공통 native 초기화 후보는 격리본만 준비됐고 제품 원본 미적용, K6 계획 재심 대기다. 제품 FleetBattle3D operation 연결, WorldMap 결산, 제품 replay는 열린 상태다. 제한 owner가 적벽 전체 모듈을 지원한다는 근거도 없다. [기존 호스트 시계](../p03-product-resume-20261108/HOST-CLOCK.md)와 C1/강제 busy의 통과는 제품 복원 호출을 입증하지 않는다.

## 소유자와 최소 조율 범위

| 경계 | P02와 맞출 hunk와 역할 | 승인 전에 확정할 사항 |
|---|---|---|
| 제품 진입 | P02가 FleetBattle3D의 기존 공개 시작 흐름(177~183행)과 준비(270~311행)에서 운영 복원 후보를 어디서 받는지 지정 | 현재 제품 호출 부재. restore를 플레이 흐름에 추가할 권한과 지원 프로필 필요 |
| 시계·게시 | P02가 316~343행 게시, 478행 프레임 및 530행 update의 쓰기 창을 지정. P03은 논리 tick/clock과 검증 자료 제공 | 첫 프레임 동등성 요구 또는 새 프레임 주기 시작 정책. 두 호스트 시계와 속도·pause, 선택·카메라·투영·사건 소비의 보존 책임 |
| owner 검증 | P03이 `OperationPrivateState.prepare` 및 `restore_completed`의 기존 거부·코드 지문을 검토. 생산 owner 변경이 필요할 때만 해당 hunk 별도 조율 | private owner 반환을 제품 게시로 인정할 수 없다. 지원 밖 모듈 오류와 기존 sim/UI 보존을 공개 경로에서 확인 |
| 제품 lifecycle | 실제 저장/재개가 제품 범위로 승인될 때만 SessionGuard 호출부와 저장 소비자 소유자를 지정 | O07 포맷, 커서, 외부 효과 ACK·재시도는 별도 인수. 이번 최소 시험에 durable 기능을 가정하지 않는다 |

공유 변경 전 현재 P02 진행·소유·실행 창을 다시 확인하고 해당 hunk와 파일을 새로 동결한다. 승인 없는 쓰기와 P02 조각의 실행 변경은 없다.

## 검증 분해와 인수

| 이름 | 최소 독립 비교 기준 |
|---|---|
| prepare_failure_preserves_live_host | 실제 제품 진입점으로 비지원 또는 오류 후보를 보낸 뒤, 이전 sim identity, tick/clock, 두 프레임 누산기, speed/pause, 선택·표시, pending·미소비 사건을 비교하고 정상 후속 프레임을 확인한다 |
| publish_uses_one_candidate | 지원 프로필의 준비된 후보로 공개 복원하고 첫 게시 프레임에서 sim/시계/표시가 같은 복원 시점인지, 이전 owner에 새 명령이 전달되지 않는지 확인한다 |
| first_frame_matches_selected_phase_contract | 저장 없이 진행한 기준과 동일 delta·속도에서 첫 프레임 진행 tick 수, 논리 시각, 정렬된 사건을 대조한다. phase 초기화가 채택되면 그 계약의 기대값을 따로 명시한다 |
| support_guard_preserves_existing_owner | 지원 밖 활성 모듈/잘못된 입력의 정확한 거부와 이후 기존 전투의 정상 동작을 검증한다 |

격리 시험은 직접 구성한 host/후보 또는 입력 주입을 표시하고, 제품 결과로 집계하지 않는다. 제품 실행은 실제 진입점과 지원 프로필, P02 소유권, 별도 계획 독립 수용이 선행한다. 실행 전 명명 사례의 정확한 단언 분모·예상 오류·오라클과 실제 engine/class map·코드·fixture SHA를 확정한다. 실제 exit·진단·프로세스 정리·입력 전후 SHA 및 출력 경로를 보존하며 K3 이내로 수행한다. GPT-6 Sol의 구현 미참여 독립 심사에서 현재 제품 경로와 격리 범위, 실패와 게시 비교, P02 간섭 및 결과를 각각 확인한다. 계획 단계에서는 제품 실행이나 공유 파일 수정을 하지 않는다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
