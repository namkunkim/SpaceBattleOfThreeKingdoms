# 독립 5-b 변경 요청 반영 및 재실행 인계

`REVIEW-5B-20261108.md` 원문 대조. 이전 실행 원문과 그 심사 판정은 유지하고, 수정본의 독립 재심사를 요청한다. 승인 v2 계획 SHA는 그대로다. 검사 의도 및 분모는 바꾸지 않았다.

1. probe.gd는 네 시나리오마다 `CASE_START <이름>`, 1~8의 `CHECK <이름>:<번호> PASS`, `CASE_END <이름>`을 순서대로 출력한다. launch.py는 정확한 네 이름 순서, 정확한 32개 ID 순서 및 각 PASS 행·시작/종료 마커의 정확한 전체 순서를 직접 비교한다. 누락·중복·순서 변경·오류는 게이트 실패다.
2. project.godot의 `scripts/world_link.gd`, BattleBrief 및 BattleOutcome을 포함하고, class cache에 열거된 모든 GDScript와 core/battle 소스, data의 JSON, 관련 정본 H2·D04·I01 및 책임표를 실행 전후 SHA·크기로 기록한다. autoload와 두 타입의 canonical resource_path guard를 oracle/probe에 추가했다. BattleBrief의 ProfileLoader·Organization, BattleOutcome의 EpilogueText 등 클래스 참조는 class cache의 전체 script 경로 동결로 포함한다. 경로 기반 동결은 임의 동적 로드나 Godot 엔진의 내부 자원 전부의 실행 추적은 아니며 이를 입증했다고 주장하지 않는다.

oracle-attempt-03: 입력 123개 전후 일치, exit0, terminal tick/end_tick 1221, clock/end_ms 122050, terminal event와 no_selection, 엔진 본체 확인, Job active0/total2, 오류·경고·누수 진단 0. oracle 원문은 같은 `oracle-a.native` 경로에 재생성됐다. 이는 과거 파일을 별도 경로로 보존하지 못한 점이다. 이전 probe-attempt-01/input-before.json의 SHA와 현재 SHA는 둘 다 B9EC4B9C2E5AC1C3D9CBA60D4211384A3B0594B1A7885380FBD419E8CB2AA49B로 byte 내용 일치하며 기존 attempt 로그는 보존했다.

probe-attempt-02: 입력 125개 전후 일치, actual exit0, 4명명×8=32 PASS, 보강된 정확 마커·순서 게이트 PASS, 엔진 본체 확인, Job active0/total2, timeout 없음, 오류·경고·누수 진단 0. oracle 실행 3회(첫 타입 오류 1회 보존), probe 실행 2회. K=6 이내다. 이전 attempt-01의 `gate_passed=true`는 승인 게이트 표식 조건 불충족임을 이전 심사에 따라 유지하며 새 실행과 구분한다.

`REVIEW-MANIFEST-V2.json`, 각 새 attempt의 input-before/after, run.json 및 stdout/stderr를 대조한다. 종료 HEAD·status는 END-V2-*이고 기존처럼 P02 긴 경로 2건 경고가 있어 전체 트리 불변 증거로 취급하지 않는다. 동시 작업 경로는 보존한다. P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED. 이번 기록은 독립 5-b 수용이 아니다.
