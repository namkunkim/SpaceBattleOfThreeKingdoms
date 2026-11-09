# 제품 복원 bridge 정적 범위 마감 — GPT-6 Sol

**정적 설계 경계만 마감 수용.** 현재 제품 `init_game`은 raw BattleSim 새 전투 준비·게시이며 제한 owner packet의 제품 복원 호출은 지정 정적 검색에서 발견되지 않았다. adapter는 checkpoint를 거부하고 owner `prepare`/`restore_completed`는 호스트 게시·명령·사건 소비를 연결하지 않는다. raw 호스트의 초기 `drain_events`, 두 clock 초기화 및 표시 경로가 복원 인수의 충돌 지점이라는 계획 판단을 원문과 대조했다. 세부 조건은 `REVIEW-PLAN-6SOL.md`에 있다.

현재 P02 공유 쓰기 창이 없고 복원 API·지원 프로필·첫 프레임 정책이 미정이다. 따라서 이 마감은 제품 restore 구현, Godot 실행, lifecycle 저장·운영 커서·외부 ACK 또는 P03 준비 완료를 뜻하지 않는다. 공유 hunk 소유와 별도 실행 계획의 독립 수용이 다음 단계다.
