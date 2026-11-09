# 제한 논리 시계·RNG 주소 복원 결과

attempt-01 suite 실제 exit 0. 본시험 Godot 실제 exit 0, 명명 3개·57 확인. 독립 강제 실패 Godot 실제 exit 1, 실패 marker 1·성공 marker 0. 대조는 값이 같아도 Variant int 0과 float 0.0이 일치하지 않는다는 비교기를 사용했다. 두 Windows Job은 총 2/active 0, SCRIPT ERROR/ERROR/WARNING/ObjectDB/리소스 종료 진단 0이다.

| 명명 | 관측 |
|---|---|
| clock_boundary | 생성 tick/clock/sub/AI/next ID 0/0/0/0/1, 첫 전진 1/100/50/450/2, 다섯 번째 5/500/50/50/2. 두 spawn은 tick 0 순서대로 유지 |
| restored_rng_address | 같은 context 복원 직후 새 RNG 객체, tick 5 전체 packet exact. 원본과 복원에서 sub=0 u32/bp 3600336925/6925, sub=1 2671758521/8521. 함수 호출은 next ID를 소비하지 않음 |
| next_ai_evaluation | 각 한 번 advance 후 6/600/50/500/3. u32/bp 3339876617/6617. 미소비 사건 순서와 전체 packet exact 일치 |

[실제 suite](attempt-01/suite.json) · [본시험](attempt-01/fixture/run.json) · [실패 대조](attempt-01/forced_failure/run.json). 입력 SHA 47개와 HEAD 전후 일치. manifest SHA256 3f1d3ea751035daa8761e5a99baf28ab9b7279e401895080367fcd022ee698f3. [manifest](attempt-01/manifest.json) · [Git 상태 비교](attempt-01/git-comparison.json). Git 상태 변화 433행 중 이 조각 8행, 동시 P02 eighth 임시 경로 415행, P03 cursor 임시 경로 10행이다. 동시 경로는 미추적 산출물이며 이 검증 결과에 귀속하지 않았다. 상태 행 비교는 전체 작업 트리 바이트 검증과 별개다.

host TickClock, 가변 hz, 실제 확률 무기, terminal 하위 걸음, 운영 복원과 외부 cursor는 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 검증 대기.
