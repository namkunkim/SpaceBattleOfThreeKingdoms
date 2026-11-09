# DecisionBoard 단독 복원 가드 5-a 결과

첫 suite 통과. 2026-11-08T10:21:53Z 로컬 rollout turn_context의 실제 실행 모델은 gpt-6.1-sol이다. 3회 상한 중 1회 사용했다. [승인 hunk](APPROVED-HUNK.diff)는 기존 busy→unprepared 가드 직후 DecisionBoard를 검사하고, 활성 상태면 prepare나 busy 변경 전에 `unsupported_active_decisions`를 반환하는 2행이다.

실제 제한 sim에 정본 DecisionBoard와 marker 47을 붙인 fixture에서 유효 C0 패킷과 잘못된 패킷이 모두 활성 오류로 거부됐다. 같은 owner·sim·모듈·역참조 및 marker, tick 1/clock 100ms, pending 명령 1개, 미소비 이벤트 3개, busy/ready 및 유효 패킷 바이트를 보존했다. busy와 unprepared가 활성 오류보다 우선했다. 기존 capture 거부와 기존 scenario 패킷의 원자 거부는 유지됐다. 정상 제한 복원은 tick 0을 재현했고, 강제 모듈을 fixture에서 정리한 후 제한 공개 명령·진행·이벤트는 무개입 대조군과 일치했다. 이전 owner 코드 지문을 넣은 내부 패킷은 기존 `code_mismatch` 경로로 거부됐다.

| 실행 | 실제 종료 | 결과 |
|---|---:|---|
| [가드 프로브](attempt-01/guard_probe/run.json) | 0 | 정확한 24개 단언 전부 true |
| [I01b active replacement](attempt-01/i01b_regression/run.json) | 0 | 20사례, 20,099 확인, 8개 거부 이름 및 9회 호출 |
| [P02 headless adapter](attempt-01/p02_regression/run.json) | 0 | 8사례, 13,417 확인, 32개 거부, 자연 종료 7 및 시뮬레이션 timeout 1 |

세 실행 모두 진단 0, 남은 job 프로세스 0, 각 입력 117개 전후 SHA 동일이다. 회귀 스크립트는 기존 정본에서 증거 출력 상수 한 줄을 전용 user://로 변경한 복제본이다. 기존 정본과 출력 경로는 보존했다. 앞선 세 fixture나 제품 호스트를 새로 실행하지 않았다.

공유 owner는 시작부터 Git 미추적이므로 변경 증거는 [기존 원문](operation_private_state.before.txt)과 바이트 대조한 [2행 diff](APPROVED-HUNK.diff)다. [보존 감사](PRESERVATION.json)의 시작 108개 입력은 이 승인 owner 변경만 차이가 난다. HEAD 동일, status의 추가 표시 17 및 제거 0은 공유 동시 상태 기록이며 변경자나 전체 트리 바이트 보존을 단정하지 않는다.

독립 Terra 5-b 대기. 운영 도달, B 모듈 복원 지원, 제품 게시와 외부 효과 원자성은 미해결이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
