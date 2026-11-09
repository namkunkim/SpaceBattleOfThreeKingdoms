# P02 실제 검증으로 가는 최소 경계 — 독립 재평가

판정: **21행의 실제 의미·마지막 K6 및 실패 기록을 유지하면서, 전역 wire 완전성과 암호학적 입력 귀속을 제품 요구로 격상하지 않는 스펙 정리가 필요하다.** `SESSION-REQUIREMENTS-CHECKLIST-20261031.md` §0의 2026-11-09 승인 조건은 실제 PC 진입점의 시작·진행·종료, 초기 배치·명령·시계·표시·결과 및 실패 시 기존 상태 보존을 요구하고, 관련 회귀에 집중한다. 제품 replay 및 추가 소비자는 후속이다. P02 전체는 여전히 NOT_READY다. 이번 평가는 코드/제품/Godot/GUI/Job을 실행하지 않았다. 심사 모델 gpt-6.1-terra.

## 정본 요구와 검증 수단

- 실제 제품 경로, 기존 소비자와 독립 native의 초기화·controls·명령·사건·결과 및 실패 원자성은 실질 요구다. 21행을 유지하고 각 행의 원래 케이스와 필수 반례를 한 번에 수행한다. 7 suite 및 BattleFlow/AutoResolve/WorldLink은 실제 원본 test와 지정 fixture를 실행하고 해당 suite의 named cases, expected exit, failure marker·조기 종료·필수 산출물을 검증한다. 이 전용 범위의 source/fixture SHA와 full ordered checks가 이미 강제되는 부분은 지킨다. 동적 반복 수는 실제 fixture의 독립 case/ID·필수 경로와 반복식으로 검사한다. 총 횟수만 역산하거나 이전 PASS를 이번 누락에 합산하지 않는다. 전체 코드를 완전히 재구현한 추가 oracle이나 불필요한 계측 단언 수는 선결조건이 아니다.
- 초기 K6 실행 계약은 raw에 Variant 타입·정수 폭·순서·좌표/ID/키를 남기도록 요구한다. 이것은 행의 실질 비교에 적용되는 계약이다. 모든 가능한 Variant 값의 global canonical serialization/모든 scalar wire byte에 대한 별도 완전 증명은 상위 P02 인수 조건이 아니다. 실제 비교할 타입과 값·순서·identity를 Godot native typed observation과 원문 `var_to_bytes`를 사용해 비교하고, 의도된 raw byte 비교가 필요한 필드만 명시한다. decoder subset 밖의 자료는 누락/미완료로 처리하거나 Godot 자체의 typed 비교를 사용하며, 별도 ABI 일반 검증으로 무한 확장하지 않는다. C의 side 1은 기존 원문 source·target 양측 typed equality, container/record identity, mutation·suffix와 독립 고정 fixture/기존 수용값을 비교한다. 자연 관측하지 못한 상세 동적 값은 수집하되 사후 기대를 임의 생성하지 않고 미입증으로 구분한다.
- 기존 K6 GUI 계약은 별도 nonce/OS 송신 주체 및 연속 관측을 강하게 요구한다. 상위 첫 PC 플레이 요구의 본질은 실제 화면·입력·반응이다. 고유 Godot 창 제목·PID/creation time/HWND·전경/클라이언트 영역, 지정 action 전후 스크린샷, 단일 computer-use 요청의 시각·입력과 Godot 수신/화면 상태를 보존하고 외부 입력 또는 전경 변경이 관측되면 실패시키는 **운영 수준** 대안을 독립 스펙 리뷰할 수 있다. 이것은 타 프로세스가 동일 입력을 주입하지 않았다는 완전한 증명이 아니므로 그 한계를 결과에 명시한다. 현재 강한 K6 계약을 몰래 만족한 것처럼 보고하거나 K5 미확인을 통과로 바꾸지 않는다. 실제 사용자 지시와 변경된 수용 기준을 묶어 5-b 재심한다. 해당 수준마저 관측할 수 없으면 GUI 15/16은 미완료다.

## 현실적인 실행 경계

현재 `exec_command`의 yield/session 및 출력 제한은 자체적으로 자손 종료를 보장하지 않는다. 관리 sandbox는 명령/자손의 현재 권한을 적용하지만 이 workspace에는 broad read와 workspace write가 있다. 제품 read-deny나 완전 read-only source가 상위 요구라는 근거는 없다. 독립된 복제 project, lane별 user://·cache·temp·로그, 동결된 엔진/소스/fixture·P03 snapshot 및 전후 경로별 hash로 충돌을 줄이고, 감시 사이 변조 부재나 모든 외부 쓰기 부재는 주장하지 않는다.

Windows에서는 생성 전에 만든 **해당 실행 전용 Job**에 직접 child를 suspended 생성 후 해당 process HANDLE 할당·membership을 확인하고 resume하는 단일 launcher가 현실적인 선택이다. 실패 시 resume하지 않고 생성한 정확 HANDLE/Job만 정리하며, 종료·timeout에 Job active 0과 보유 HANDLE signal을 기록한다. 원래 broker의 Python-only 이미지 허용 목록으로 Job의 모든 OS helper를 코드 신뢰 대상으로 분류하는 것과, 이미 전용 Job에 소속된 프로세스의 정리 소유는 별개다. 엔진 시작 executable의 SHA/경로는 고정하고 예상 밖 helper의 관측 사실은 기록한다. 제3자의 프로세스를 탐색·종료하지 않는다. 외부 watcher와 raw output cap 및 launcher 전체 deadline을 실제 구현해 독립 정적 검토한다. Job create/assign 실패, 무한 join, output/receipt 누락·cleanup 미확인은 즉시 실패다. 현재 이 launcher는 구현·실측되지 않았으므로 이미 보장된 것처럼 말할 수 없다.

기존 Python K3의 세 실패는 끝났으며 동일 broker qualification을 다시 시도하거나 `K=1`로 이름을 바꾸지 않는다. 소유·정리가 요구되는 최종 K6 실행기에 대안 구현을 준비하는 것은 정적 작업이다. 실제 최초 제품 import/검증 spawn부터 K6 한 회가 소진되고, 어떤 행의 실패·중단·누락도 재실행하지 않는다. 한 회만 있으므로 보수적으로 preflight에서 21행 실행 파일·정확 argv/env·fixture·expectations·시간·cleanup 및 전체 6시간 예산을 동결·독립 심사한다. 175/320 기록과 K4 실패를 덮지 않는다. 사전 비제품 실험을 또 필수로 요구하지 않고, 필요한 경우라 해도 기존 K3를 우회하는지 먼저 판정한다.

## 현재 남은 실제 전진 작업

1. 위 운영 수준 GUI 기준과 한정 typed semantic 판정으로 기존 21행과의 대응표를 작성해 독립 스펙 심사를 받는다. 실제 행·기존 실패·위험을 축소하지 않고, 과도한 수단만 대체한다.
2. 후보 세 제품 파일과 P03 현재 snapshot의 양 lane 입력을 결정·동결하고, 실제 suite 명령·case/exit/필수 negative 및 C producer/출력과 GUI 실제 행동을 포함한 완결 manifest와 direct owned launcher를 만든다. 이 작업은 원본 제품에 적용하거나 K6을 실행하지 않는 준비다. 출력량 및 timeout이 예산에 들어가는지 불명이라면 성공을 약속하지 않고 상한과 실패를 명시한다.
3. 독립 재심이 수용한 경우 21행을 단일 K6에서 수행하고 결과를 독립 5-b로 판정한다. 실제 최초 PC 플레이 경로가 이 초기화 조각 이후에도 남는다는 사실을 유지한다. K6 실패면 그대로 중단·보고한다.

**지금 입증된 단 하나의 외부 환경 차단을 단정할 근거는 없다.** GUI API의 강한 송신 주체 표식과 실제 Job 경계는 현재 미입증이지만, 전자는 상위 제품 요구와 구분 가능한 선택된 검증 수단이고, 후자는 구현·심사해야 할 미완성 작업이다. 다만 독립 스펙 심사에서 강한 귀속이 필수라고 유지되거나 현재 환경에서 실제 UI 입력/관측이 불가능한 것으로 확인되면 그 GUI 항목은 외부 실행 환경의 구체적 차단으로 남긴다. 이 문서는 실행 승인 또는 P02 완료 판정이 아니다.
