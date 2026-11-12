# 캠페인 적용 체크리스트

## 0. 캠페인 적용 전체 체크리스트 — 2026-11-12

이번 세션 범위는 Windows 1600×900이다. 원격 `main` 확인 기준은 `7f138c2d`다.

### 완료

- [x] **K6 정식 실행** — `264f47b9`에서 21행·58작업·27비교 통과. [정식 집계](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-row21-05/run-once/aggregate.json)
- [x] **P02·P03 승인 적벽 v1** — 공개 시작·리플레이와 Windows 실제 입력으로 같은 작전 저장·새 프로세스 이어하기·결산 복구 검증. 설정과 작전 슬롯 분리 25/25. [Windows 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-ui-prep-01a1c838/run-67f9cb20-20261111-01/RESULTS.md) · [저장·리플레이 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/2) · [설정 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/6)
- [x] **P04·O07 격리 저장 복구** — 개발 호스트의 가져오기·내보내기 실패 후 재시도와 시험 프로세스 중단 뒤 확정 저장 복구. [가져오기](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P04-external-effective-authority-b2ba73ff-01/REVIEW-HANDOFF.json) · [내보내기](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P04-external-export-failure-7f138c2d-01/REVIEW-HANDOFF.json) · [O07 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/p03-store-child-cutpoint-b2ba73ff-02/RESULTS.md)
- [x] **P05·P06·P07 승인 적벽 검증** — Atlas 선택 15/15, 같은 작전의 시계·재개 36/36, 결산 잠금 재시도 22/22. 정면·우회와 보급·증원·철수도 개발 후보 v1에서 확인했다. [상세 검증](P02-PROGRESS-CHECKLIST.md) · [결산 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/3)
- [x] **P08 Windows 후보 플레이** — 실제 입력으로 정면 목표 달성과 우회 철수 확인. [정면·우회 로그](P02-PROGRESS-CHECKLIST.md#첫-pc-캠페인-플레이--1109-개발-후보-v1-이력)
- [x] **P09 한정 수정** — 화공 오디오와 `battle_flow` 종료 수정 병합. 수정 후보의 종료 잔류 진단 0건 확인. [화공 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/4) · [종료 수정 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/7)

### 남은 작업

- [ ] **K6 이후 main 변경분 15~18행** — 판정 기준·입력 동결, 1600×900 Windows 실제 입력과 독립 리뷰·일회 승인 결속.
- [ ] **P02·P03·P04 일반 운영** — 공통 입력·상태, 운영 Cn과 작전 간 명령 커서, 공개 외부 저장과 독립 다중 호스트 검증. 차단된 기존 다중 호스트 시험은 재실행하지 않는다. · [P02/P03 필드 사용처 준비](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-P03-field-consumer-inventory-7f138c2d-01/README.md) · [P04 공개 외부 저장 준비](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P04-public-external-save-preflight-7f138c2d-01/README.md)
- [ ] **P05·P06·P07 확장** — 일반 선체·진형, 추가 작전 규칙, 후속 작전 승계와 A05/A06 종합 검증. · [A05 FX-G 어댑터 바인딩 준비](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/A05-fxg-adapter-binding-preflight-7f138c2d-01/README.md)
- [ ] **P08·P09·O07 인수** — Windows 1600×900 대표 플레이·성능, 설정·지도 효과음과 배경음악의 전경 종료 및 전체 TRACE, 운영 전환·외부 지급·실제 전원 차단 복구. [Windows 후보 EXE 기동 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P08-windows-exe-startup-7f138c2d-01/REVIEW-HANDOFF.json) · [전경 오디오 범위](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-nonbattle-audio-scope-7f138c2d-01/REVIEW-HANDOFF.json) [P09 단발 효과 참조 해제 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-product-oneshot-drain-7f138c2d-01/REVIEW-HANDOFF.json) · [TRACE 작업 브랜치·헤드리스](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/681ecda17567979edfe693a7c9230ed6786f8c4f) · [P08/P09 Windows 전경 검증 준비](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P08-P09-windows-foreground-preflight-7f138c2d-01/README.md)
