# P03 종료 하위걸음 체크포인트 결과

2026-11-08 KST. 제한 POC owner에서 마지막 적을 테스트 피해 훅으로 격침한 뒤, **실제 코어의 다음 step 첫 하위걸음**이 tick2/clock150에서 전투를 끝냈다. 종료 함수·flag를 주입하지 않았다. raw BattleSim과 수기 기대값으로 over/win, end_tick2/end_ms150, sub_ms50, dt0.1 및 단일 `battle_end/annihilation` 사건을 비교했다. 전투 직전 packet으로 복원한 뒤 피해 재주입 없이 같은 advance를 실행해 결과를 재현했다. 미소비 terminal packet도 같은 owner handle에 복원했고, 해당 타임라인에서 종료 사건을 한 번 drain한 뒤 빈 값을 확인했다. [독립 5-b](REVIEW-5B-attempt-01.md)

새 attempt-01/K6 actual Godot exit0, 4명명·31 단언, 실패/오류/경고/누수 진단0이다. console과 실제 Godot 본체를 구분했고 전용 Job은 프로세스 2개, 종료 시 active 0이었다. 정본 class map·실제 Script binding을 포함한 입력 45개 전후 SHA가 일치했다. timeout probe를 이 조각에서 다시 실행하지 않았다. job helper 바이트는 선행 suffix에서 probe를 통과한 버전과 같다. [실제 실행](attempt-01/run.json)

시작 dirty/untracked 9869개 재해시는 누락0·SHA 변경0, 실행 입력 45개 현재 drift0이다. P02의 새 계획 심사 한 경로가 별도 관측됐다. 기존 전체 diff-check actual exit2는 P2c 행의 후행 공백이며 새 경로의 whitespace 확인과 분리했다. [보존 감사](preservation.json)

전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 자연 플레이 경로에서 같은 피해를 냈다는 증거, host 배속/정지, 실제 운영 Cn·전체 모듈, 전역 커서, 외부 사건 ack/dedup 및 terminal 뒤 호출 정책은 별도다.
