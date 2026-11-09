# 제한 owner 공개 복원 집계 수정 5-a

2026-11-08. **새 cycle의 첫 시도 5-a 통과.** 실행 모델은 이 세션의 로컬 rollout 2026-11-08T09:04:39Z turn_context에서 직접 확인한 gpt-6.1-sol이다. [실행 기록](attempt-01/run.json)은 실제 exit 0, 정확한 단언 17개 모두 true, 오류·경고·누수 진단 0, 남은 job 프로세스 0을 기록한다.

제한 owner가 비어 있지 않은 scenario를 포함한 패킷을 공개 `restore_completed`에서 `unsupported_scenario`로 거부했다. 호출 전 tick 1, clock 100ms, pending move 1개 및 미소비 이벤트 3개를 확인했다. 거부 후 후보 입력 바이트, 기존 owner와 sim 식별자, ready 및 idle, 전체 공개 캡처가 보존됐다. 이어 즉시 def와 pending move가 로그에 차례로 각각 한 번 기록됐고 tick 2의 전체 캡처와 순서 있는 이벤트 5개가 무개입 대조군과 일치했다. 두 번째 drain은 비었다. 별도 owner의 정상 복원은 tick 0으로 돌아갔다.

정적 라벨 비교에서 정확한 17개 이름이 일치한다. `fixture_public_actions`의 두 호출부는 실패 후 즉시 반환하는 분기와 성공 분기다. 실행 중 동일 라벨이 중복되면 프로브가 실패하며, 게이트는 이름 집합과 모든 true를 별도로 검사한다. probe의 행동 조건은 앞선 attempt-03과 같다.

[보존 기록](PRESERVATION.json)의 기존 세 시도 파일 27개는 전후 SHA 동일, 새 시도 입력 86개도 전후 동일, 계획 SHA 차이 0 및 HEAD 동일이다. 전용 입력의 끝 공백은 0건이다. 동일 옵션 status의 추가 표시 1,687개, 제거 0은 동시 작업 분모다. 앞선 세 시도의 실패 판정은 해당 [결과](../RESULT.md)에 남아 있다.

독립 5-b 대기. 제품 호스트 연결, 운영 복원 정책, 활성 DecisionBoard 강제 주입 반례, UI 및 외부 효과 원자성은 미해결이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
