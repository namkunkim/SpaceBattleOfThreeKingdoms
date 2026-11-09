# 제품 호스트 운영 복원 준비 독립 계획 심사 — GPT-6 Sol

판정: **준비·소유 경계 계획으로 조건부 수용**. `PLAN.md` SHA-256 `7d7dbb01b0ce63063ace13f2d135d988d77a3c8247742f6247027af8b7d813ae` 기준이다. 이 심사는 제품 복원 구현 또는 5a 실행을 승인하지 않는다.

지정한 `core scripts view hud input scenes`의 현재 `.gd`/`.tscn`에서 계획의 검색어를 재확인했다. `capture_completed`와 `restore_completed`의 정의는 `core/battle/operation_private_state.gd`, `start_operation`의 정의는 `scripts/world/auto_resolver.gd`, `suspend_requested` 선언·emit은 `hud/ui_kit/session_guard.gd`에 있다. 이 검색 결과에는 제품의 owner 복원 호출자가 없다. 이는 지정 파일 형식·검색어에 한정된 정적 미발견이며 동적 호출, 다른 이름의 래퍼 및 범위 밖 소비자를 배제하지 않는다. `FleetBattle3D.init_game`은 현재 `_prepare_game`에서 raw `BattleSim.new`를 만들고 `_publish_game`에서 sim과 두 시계를 새로 게시한다. `_process`와 `update_sim`은 별도 진행 경로다. 따라서 owner API의 시험 통과를 제품 운영 복원으로 승격하지 않는 계획 판단은 맞다.

공유 변경 역할은 계획의 표대로 조율하되, 실제 쓰기 소유자는 P02 담당자와 조율자가 파일·hunk·시간 창으로 명시해야 한다. `scripts/FleetBattle3D.gd`의 진입·시계·게시와 `core/battle/operation_private_state.gd`의 owner guard는 서로 다른 수명 경계다. owner의 `prepare`/`restore_completed` 성공만으로 호스트 sim·clock·UI·사건 커서가 함께 게시된 것이 아니다. 제품 lifecycle의 `SessionGuard` 신호에도 저장 소비자가 현재 확인되지 않는다. O07 포맷·커서 및 외부 ACK는 별도 열린 인수로 유지한다.

네 검증 이름은 후속 구현의 목표로 적절하지만 아직 실행 사전등록은 아니다. 실제 제품 시험 전에 (1) 공개 진입점과 지원 프로필·저장 입력의 형식, (2) 실패 및 성공별 정확한 객체·값·사건 비교 oracle, (3) 첫 프레임 phase 정책과 기준 delta·speed·pause, (4) 정상 게시에서 이전 owner/명령의 폐기 및 미소비 사건 처리, (5) 명명 사례별 단언 수·예상 오류·timeout, (6) Godot/클래스 맵·fixture·정본 바이트 SHA, 시도별 actual exit·진단·Job 종료·전후 입력 manifest를 별도 계획으로 동결하고 독립 심사를 받아야 한다. 직접 주입한 격리 host 시험은 제품 호출 증거와 구별한다. K3은 해당 후속 실행의 총 시도 상한으로 유지한다.

현재 HEAD는 `0be09755b70378286105972f35ac5b7031715664`, 현재 `FleetBattle3D.gd` SHA-256은 `604b79308d9b3dbab84dced32456a4f41b28686c8eec748073d3816892cffc5c`, private owner는 `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`으로 계획의 읽기 값과 일치한다. owner와 P02 진행표는 기존 Git 수정 상태다. 이는 계획 시점 상태이고 후속 실행은 새 manifest를 동결해야 한다. 검토 중 공유 파일은 수정하지 않았다. 사용자 요청에 따른 GPT-6 Sol 검토 배정이며 별도 모델 실행 메타데이터는 없다.
