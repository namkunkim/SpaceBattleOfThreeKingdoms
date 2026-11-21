# Work coordination

- 이 프로젝트의 새 작업은 새 Codex 채팅에서 시작한다. 이미 진행 중인 같은 작업의 후속 검증과 마감은 해당 채팅에서 이어간다.
- 작업 채팅 제목은 진행 중에는 (ING), 마감이 확인되면 (DONE)으로 시작한다. 마감 표시는 채팅의 담당 범위에 대한 것이며, 프로젝트 전체 인수를 뜻하지 않는다.

## Orchestration

- 캠페인 적용의 진행 상태와 남은 작업은 [캠페인 적용 통합 체크리스트](docs/battle-core/pc-campaign-design/CAMPAIGN-APPLICATION-CHECKLIST.md)에서만 관리한다. P02·P03을 최우선으로 진행한다. 이전 캠페인 적용 체크리스트와 이관서는 검증 근거로 참조한다.

- 오케스트레이션 담당 채팅은 관련 하위 채팅과 서브에이전트의 진행을 확인하고 작업 순서, 입력 기준, 독립 검증, 반영을 조율한다.
- 진행 중인 작업은 완료 또는 구체적인 차단이 확인될 때까지 감시한다. 한 항목이 막혀도 체크리스트에서 독립적으로 진행할 수 있는 작업을 계속 배정하고 확인한다.
- 캠페인 적용의 검증 근거는 결과 문서에 기록하고 남은 조건은 통합 체크리스트에 반영한다. 각 작업 채팅의 (ING) 또는 (DONE)을 실제 담당 범위의 상태에 맞춰 갱신한다.

## Storage

- 2026-11-13 사용자 지시: 이후 작업의 기준 프로젝트는 `E:\WorkSpace\SpaceBattleOfThreeKingdoms`이다.
- C:에서 이전한 참고 자료는 `F:\WorkSpace\SpaceBattleOfThreeKingdoms-c-drive-cleanup-20261113`에서 확인한다. 보고서·이미지 등 마지막 잔여 자료는 그 아래 `remaining-project-files`에 있고, 앞서 이전한 임시 검증 폴더 3개는 보존 폴더 바로 아래에 있다. 삭제된 `C:\WorkSpace\SpaceBattleOfThreeKingdoms`를 작업 또는 참고 경로로 사용하지 않는다.

- 내부 스토리지 용량 문제가 발생하면 F:\WorkSpace 폴더를 사용한다. 빌드 중간물·검증용 사본·임시 산출물은 이 경로 아래에 둔다. 기존 제품 소스·실행본·사용자 저장은 별도 지시 없이 이동하거나 삭제하지 않는다.

- 2026-11-13 사용자 지시: 이후 Codex 워크트리는 `F:\WorkSpace\.codex\worktree` 아래에 둔다.
