# P03 후속 비충돌 후보 — fresh replay와 운영 suffix의 책임표

2026-11-08 KST. **조사·독립 계획 심사 후보. 코드/Godot 미착수.** 지금 가장 직접적인 결함 수정은 [Dictionary metadata after](../p03-dictionary-context-fix-20261108/PLAN.md)지만 공통 owner의 P02 소유·계약을 먼저 명시적으로 정리해야 한다. P02 최신 revision4는 제품 자동결산 변환의 후속 검증과 독립 심사 중이다. 공유 owner의 쓰기 소유가 이전됐다는 근거는 없다. P02에 직접 연락하지 않았다.

병행 가능한 작은 조각은 **P02가 실제 구현한 fresh replay 소비 책임을 기존 P03 명령 원장에 대조한 읽기 전용 책임표**다. `core/battle/operation_replay.gd:32,72,98–141`은 tick 순서대로 명령을 normalize하고 fresh owner의 현재 tick에 queue→advance→drain을 호출하며 `consumed`는 그 루프의 지역 변수다. 기존 `BattleSim.issue`와 `step`이 즉시·대기 입력을 현재 tick에 log하는 시점, `OperationPrivateState.capture_completed`가 log/pending/events를 내부 packet에 넣는 시점, P02 CLI가 외부에서 받는 tick row를 각각 구분한다. 현재 fresh replay의 `commands_consumed`를 복원 가능한 global cursor로 해석할 수 없다. [P02 replay 결과](../../docs/battle-core/pc-campaign-design/P02-REPLAY-RESULT-20261108.md)

사전등록한 5-a는 문서 한 개에 ① 정본 source:line·타입·소유·변경/소비 근거, ② 동일 틱 issue/queue, 입력 tick 순서와 적용 순서, 종료 이후 미소비, 사건 raw/filtered/drain 각각 반례 하나, ③ 기존 suffix 및 viewer 결과의 재사용 경계, ④ 미결 운영 cursor/commit/ack·외부 schema 및 P02 공동 인수 항목을 표시하는 것이다. 새 runtime 테스트나 저장/replay API는 작성하지 않는다. 최신 source SHA와 적용 계획을 먼저 고정하고 별도 독립 검토 뒤 기록한다. 신규 쓰기는 P03 전용 근거 파일뿐이며 공유 코드는 읽기 전용이다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
