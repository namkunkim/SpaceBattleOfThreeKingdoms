# 직접 출격 장면 거절 · 원본 반영 검토 기록

격리 attempt-03의 독립 5-b 수용 이후, 원본의 두 제품 파일만 반영했다. HEAD는 0be09755b70378286105972f35ac5b7031715664, staged diff는 비어 있으며 index bytes는 변경하지 않았다. P03 전체 상태 관리 채팅은 적용 직전 idle/completed로 조회됐다. 이 조회는 장래 쓰기 잠금을 보장하지 않는다.

- scripts/world_link.gd와 view/world/world_map_screen.gd의 적용 전 SHA는 동결 closure 및 attempt-03 before 입력에 일치했다.
- 적용 후 SHA는 심사된 후보와 실제 after 격리 실행의 두 입력 파일 bytes에 일치했다.
- 원본 tests/world_link.gd에는 테스트 overlay를 반영하지 않았다. P03 private owner, worker 테스트, P02 진행표, project.godot의 기존 bytes와 실행 source 1,480개에서 두 소유 경로 외 파일의 SHA를 전후 대조했다. 양쪽 격리 class cache SHA도 다시 읽어 동결값과 대조했다.
- 두 파일 scoped git diff --check 실제 exit 0. Git은 이후 파일을 다룰 때 LF가 CRLF로 바뀔 수 있다는 기존 설정 경고를 출력했다. 현재 원본은 실제 검증 후보와 byte 동일하다.
- 원본 적용 이후 새 Godot 실행, stage/commit/push는 없다. 검증은 동일 bytes의 격리 attempt-03에 근거한다.
- 범위는 기존 직접 출격 장면 요청 거절의 원자적 복구다. 새 PC campaign operation, 자연 종료, OS 입력, P02 전체 완료는 미인수이며 PC0 2/2 및 여덟째 K6 미사용을 보존한다.

[result.json](result.json) · [실제 원본 diff](production-applied.diff) · [적용 직전 P03 상태](p03-apply-status.json) · [독립 5-b](../REVIEW-5B-INDEPENDENT.md)
