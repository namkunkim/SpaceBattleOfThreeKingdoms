# raw BattleSim 시각 증원 경계 결과

[attempt-01](attempt-01/suite.json) suite 실제 exit 0. 본시험 실제 exit 0, 명명 3개·31 확인 전부 일치. Variant int/float 의도 실패 실제 exit 1, 정확 실패 marker 1개. 두 Windows Job은 각 총 2/active 0, 오류·경고·누수 종료 진단 0이다.

| 명명 | 실제 관측 |
|---|---|
| threshold_is_strict | 100ms에서 reinf=false, 시각 -1, roster [1,2], by_id(3)=null, 초기 spawn 두 건만 유지 |
| timed_spawn_at_150ms | 두 번째 틱 종료 시계 200ms에서 reinf=true, 기록된 발동 시각 150ms. ID 3·side 1·form_id 2의 전대가 (2100,1400)에 추가됐고 warm 캐시가 기존 객체와 새 ID를 올바르게 반환. tick 2의 spawn(3)→reinforcements 순서 |
| no_second_spawn | 세 번째 틱 종료 300ms에도 같은 세 전대 객체, 발동 시각 150ms, 사건 4건 유지 |

fixture는 기존 POC 규칙의 reinf_ms를 100으로 바꿨으며 제한 owner를 거치지 않았다. debug 호출 없이 BattleSim.step() 세 번을 실행했다. 150ms는 둘째 step의 종료 시점이 아닌 st.reinf_ms에 기록된 실제 하위 걸음 시각으로 관측했다.

manifest SHA256 dfb23ec66dadea147a6a72275677268073620a5259e157ea509dbaa219471b88. 동결 47개와 HEAD는 전후 일치했다. [Git 상태 비교](attempt-01/git-comparison.json)의 변화 87행은 전용 8개, 동시 P03 cursor 전용 경로 79개이며 P02 상태 행 변화 0개다. 이 비교는 전체 dirty 파일 바이트 검증과 별개다. [실행 증거](attempt-01/fixture/run.json) · [실패 대조](attempt-01/forced_failure/run.json) · [동결 manifest](attempt-01/manifest.json)

전멸 증원, 기본 95초 전투, 제한 owner·운영 C0/Cn, 실제 P02는 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 사후 독립 5b 대기.
