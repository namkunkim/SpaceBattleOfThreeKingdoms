# 제한 owner 공개 복원 계획 독립 심사

2026-11-08. **수용: 계획된 제한 fixture 및 공개 복원 거부 검증.** 심사자는 구현에 참여하지 않는다. 이번 turn의 `CODEX_THREAD_ID`는 `01a1ba45-75d3-7dc3-980c-1d24d6111709`이며 해당 로컬 rollout 최신 `turn_context`의 2026-11-08T08:57:32Z 모델은 `gpt-6.1-terra`다. 작업자 모델은 부모가 확인한 `gpt-6.1-sol` 기록에 따른다.

계획과 `operation_private_state.gd`의 `_profile_error`, `_packet_error`, `prepare`, `restore_completed`, capture 및 `_fail`을 대조했다. 유효한 capture packet에 비어 있지 않은 scenario만 추가하면 공개 restore가 candidate 준비 단계에서 `{"ok":false,"error":"unsupported_scenario"}`를 반환하는 경로가 계획의 oracle과 부합한다. 이는 활성 DecisionBoard가 들어 있는 기존 owner의 restore 정책이나 정상 제품 연결을 검증하지 않는다.

진행 중 owner의 비어 있지 않은 pending·미소비 사건과 동등한 무개입 대조군을 먼저 확인하고, 거부 직후 drain이나 advance 전에 전체 capture 및 identity를 대조하는 조건은 원자성 관측에 적절하다. 후속 즉시 issue와 pending 적용의 실제 순서는 정본 동작에 맞게 명시하고, 각 명령의 고유 식별자·정확한 발생 횟수와 로그 순서를 두 owner 사이에 비교한다. 양성 복원 대조는 별도 owner에서 수행한다. 모든 전제가 충족되지 않으면 통과로 기록하지 않는다.

승인은 사전등록된 전용 경로 작업과 최대 3회 시도에 한정한다. 입력 및 HEAD 동결, 실제 종료·진단 원문, 독립 5-b와 closeout을 유지한다. 공유 파일은 읽기만 하며 status 차이로 전체 바이트 보존을 주장하지 않는다. 제품 호스트 연결, 강제 주입 반례의 정책, UI·외부 효과는 미해결이다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
