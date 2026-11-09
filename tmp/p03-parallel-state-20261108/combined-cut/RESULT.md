# 제한 owner 적용 로그·대기·미사일 결합 절단점 결과

[attempt-01](attempt-01/suite.json) suite 실제 exit 0. 본시험 실제 Godot exit 0, 명명 3개·53 확인 전부 일치. Variant 타입 불일치 대조는 실제 exit 1, 확인 1, 정확 실패 marker. 두 Windows Job은 각 총 2/active 0, SCRIPT ERROR/ERROR/WARNING/ObjectDB/리소스 종료 진단 0이다.

- combined_cut. 공개 issue의 stop@0, move@0 두 항목, 아직 적용하지 않은 stop@-1 한 항목, 실제 시뮬레이션의 미사일 ID 2–7가 동일 capture에 공존했다. 앞선 이동 지시의 목적지는 (600,500)이고 전대 위치는 (500,500)이었다. 두 spawn, 두 say, missile_launch 사건이 tick 0에 순서대로 있었다. 발사는 실제 sim의 테스트 훅을 썼으며 명령 log에는 없다.
- restore_active_pending. 공개 same-context restore가 성공했다. 별개 sim/state와 두 roster 객체 및 여섯 미사일이 생성됐다. 논리 src=1과 target=2는 새 roster에서 해석됐다. 두 capture는 P와 Variant 타입·메타데이터·키/배열 순서까지 exact였다. 실제 nested raw path는 빈 문자열이며 canonical outer BattleState의 Missile 상수와 Script identity를 확인했다.
- advance_once_in_order. 원본과 복원본이 각각 한 틱 진행했다. log는 stop@0→move@0→stop@0, queue는 비었다. 이전 다섯 사건 뒤에 say(stop) 한 건만 추가됐다. 전대는 (500,500)에서 움직이지 않았고 미사일은 age 100, 속도 +6.0 두 번, 같은 ID·참조로 전진했다. tick/clock/sub/next ID 1/100/50/9 및 두 전체 capture exact를 확인했다. 수기 위치 수치 대신 두 전체 capture를 대조했다.

manifest SHA256 2de89bb98b942abad03ae74f46e681c3fc784dd61120f025f7e94944c9109e10. 49개 동결 입력과 HEAD 전후 동일. Git 상태 차이 8행은 모두 전용 폴더이며 P02·동시 외부 경로 차이 0이다. 이 비교는 전체 dirty 파일의 바이트 감사와 별개다. [실행 로그](attempt-01/fixture/stdout.bin) · [manifest](manifest.json) · [Git 시작](attempt-01/git-before.z) · [Git 종료](attempt-01/git-after.z) · [Git 비교](attempt-01/git-comparison.json)

운영 A06의 외부 처리 키·seq/ack/idempotency 및 스키마는 미실행이다. 제품 발사, host/UI, 전체 운영 복원은 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 5b 대기.
