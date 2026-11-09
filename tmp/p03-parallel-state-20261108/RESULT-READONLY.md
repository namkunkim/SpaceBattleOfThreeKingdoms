# P03 읽기 전용 선언 누락 검증 결과

실제 suite exit 0, 7/7 일치. 대상은 동결한 GDScript 네 파일의 고유 선언 튜플 172개다. [계획 수용](REVIEW-PLAN-READONLY-v2.md)과 실행 후 독립 심사는 별도다.

| 사례 | 실제 exit | 누락 / 추가 또는 진단 |
|---|---:|---|
| baseline | 0 | 0 / 0 |
| omission | 1 | 1 / 0, BattleState/_idx_n |
| rename | 1 | 1 / 1, FleetState/target_id → target_id_probe |
| missing | 2 | absent.gd 입력 오류, 비교 결과 없음 |
| nested | 1 | 10 / 10, Missile → MissileProbe. Swarm/최상위 차이 0 |
| ignored | 0 | 0 / 0, 주석과 함수 지역 변수 배제 |
| duplicate | 2 | FleetState/target_id 중복 21·22행, 비교 결과 없음 |

[실제 자식 명령·exit](runs/attempt-01/suite.json), 같은 폴더의 사례별 stdout/stderr, [suite exit](attempt-01.exit), [동결 manifest](readonly-manifest.json), [manifest SHA](READONLY-MANIFEST.sha256). SHA는 e7b6399d8225932cea77244117949e15938cf38c7cd3ea6026603bba35e423b4다. runner는 실행 전후에 manifest, 정규 경로 집합, 13개 파일·Python 실행 파일 해시 및 HEAD를 확인했다. 준비 시 수기 S1 목록과 원문 4개를 사전 동결 목록과 먼저 대조했다.

첫 셸 설정은 Get-Command가 Python 애플리케이션 경로를 세 개 돌려줘 exit 1이었다. 첫 경로 C:\Python314\python.exe를 명시적으로 골라 준비 exit 0, suite 최초 실행 exit 0을 얻었다. [설정 실패 기록](setup-attempt-01.txt). 후보는 내용 비교를 위해 줄 끝을 정규화했다. LF 정규화 후 승인된 줄만 달라지는 후보를 비교했으며 바이트 기준 복사본과의 차집합을 의미하지 않는다.

HEAD는 시작과 종료 모두 fb660cea69207fd332e26128643007694910a253. [실행 시작 Git 상태](EXEC-START-GIT.txt)와 [종료 Git 상태](EXEC-END-GIT.txt)는 같은 옵션을 사용했다. [비교](EXEC-GIT-DIFF.txt)의 30개 신규 상태 행은 전부 전용 폴더다. 이는 status 행 비교와 동결 입력 검증이며 전체 dirty 파일의 바이트 불변 검증은 아니다. 시작부터 보인 P02 관련 world/auto_resolver, world/battle_outcome, tests/autoresolve 및 UI/프로젝트 변경은 이번 조각 산출물에서 제외했다. 조율자 시작 스냅샷은 별도 보존했고 status 옵션 차이로 발생하는 미추적 표시 범위는 바이트 drift로 해석하지 않았다.

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 런타임 및 동적 키의 완전성, 활성 모듈 복원, P02 경로의 동작은 미실행이다.
