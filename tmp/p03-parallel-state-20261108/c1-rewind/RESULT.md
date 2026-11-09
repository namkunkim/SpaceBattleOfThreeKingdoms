# 제한 owner 비초기 완료 경계 복원 결과

[attempt-01](attempt-01/suite.json) 실제 suite exit 0. 본시험 Godot 실제 exit 0, 명명 3개·87 확인. 별도 Variant int/float 비교 고장 대조 실제 exit 1, 확인 1개 및 정확 실패 marker. 두 Windows Job은 각 총 2/active 0, SCRIPT ERROR/ERROR/WARNING/ObjectDB 및 리소스 종료 진단 0.

| 명명 | 관측 |
|---|---|
| capture_noninitial_issue_boundary | 실제 발사 후 한 틱 진행한 1/100ms에서 미사일 age 100, 속도 +6.0 두 번과 이동 위치. 즉시 move@1 이후 같은 clock·미사일 값을 가진 P에 이동 의도, 적용 log 한 건, raw 사건 네 건. |
| restore_earlier_on_same_owner | 공개 stop과 advance를 통해 같은 owner가 실제 2/200ms·age 200의 Q에 도달. 그 owner에 공개 restore(P)가 성공하고 sim/state/fleet/missile 객체가 교체됐다. 참조 ID는 새 roster로 연결. 되감긴 전체 capture는 P와 exact이며 Q와 달랐다. |
| replay_suffix_after_rewind | 같은 stop/advance를 재실행했다. 2/200ms, age 200, AI timer 350, next_event_id 9, 적용 move@1→stop@1와 다섯 사건, 빈 pending이 독립 기대와 일치했다. 재실행 capture는 Q와 exact였고 P/Q 입력 사본도 유지됐다. |

발사는 테스트 훅을 사용했다. 실제 Missile nested resource_path는 빈 문자열로 기록했으며 canonical enclosing BattleState의 Missile 상수와 Script 객체 identity를 확인했다. 독립 개별 위치 수치는 설정하지 않았고 전체 capture에서 exact 비교했다. [본시험 stdout](attempt-01/fixture/stdout.bin)

manifest SHA256 5c609e8c4f4522ead8d2da22ddac67cbf102fe13b282183f7527b5eacbc6fbbe. 동결 입력 49개 및 HEAD 전후 동일. Git 상태 차이 8행 모두 전용 경로이며 P02·동시 외부 경로 차이 0이다. 이 상태 비교는 전체 dirty 파일의 바이트 감사와 별개다. [manifest](manifest.json) · [Git 시작](attempt-01/git-before.z) · [Git 종료](attempt-01/git-after.z) · [Git 비교](attempt-01/git-comparison.json)

제품 rewind 정책, 과거 packet·오염 허용 정책, 외부 seq/ack/저장, P02 host/UI 및 전체 운영 A06은 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 5b 대기.
