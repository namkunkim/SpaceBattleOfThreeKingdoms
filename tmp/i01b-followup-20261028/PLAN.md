# 원본 bundle_layout 리터럴 기준선 최소 수정 계획 (0~3)

2026-10-28 KST. 실행 담당 계획이며 구현 미착수. 코드 재시도 K=6, 5-b 반려는 스펙으로 복귀한다.

## 0. 현재 관측과 보존

- 원본 main HEAD `8292805143f4561a4f5258d40b7b94adf4ff5802`.
- `before.json`: git 개별 추적 변경/미추적 1008경로의 SHA256/크기와 상태. 본 evidence prefix만 제외. SHA256 `dbde6a45bb7a336a11afee8a56f64155c4e5460cd4f1395f061e558344c6f6bc`.
- 이전 primary-before의 960경로 전부 현재 SHA 일치(누락/차이0), `prior-comparison.json`.
- bundle_layout SHA `52fde94aa9d2cca411ee038856643934990aac7de26ad7141ce3f9e61e379101`. 인계 이후 해결되지 않았다. baseline/ 아래 실제 현재 bundle 구현과 테스트, data_rules 원문 사본을 보존했다.
- 기존 DATA-RULES-BASELINE-FIX는 추격170의 데이터 정본화다. 이미 반영됐으며 중복하지 않는다. data_rules는 첫 리터럴 단계11건 실패하여 뒤의 추격10/키/편성 등은 원본에서 미실행이라는 기존 기록을 유지한다.
- CLAUDE/워크플로우-플레이북과 SESSION-HANDOFF를 읽었다. 현재/상위 루트 및 저장소 검색에서 적용 AGENTS.md 없음. 오래된 SESSION-HANDOFF의 문서전용 역할보다 이번 실행 담당 명시 지시가 우선한다.

## 1. 의도와 범위

기존 다른 작업이 작성한 임의 함대수 전체 진형·전환중 범위·경계 비율 축소를 보존한 채, 모양 식별자와 기하 계수의 데이터 소유권을 분명히 해 data_rules 전체 검사가 실행되게 한다. 숫자 식별자6/7/8/9와 계수0.9/0.45/0.7/0.25를 구분한다. 값을 바꾸지 않는다. 기존 skip/allowlist/UNIT_CONSTS 확대, 산술로 리터럴 숨기기, exempt 함수 안으로 코드 옮기기는 금지한다.

## 2. 제안 스펙 (독립 계획 검토 대상)

전용 `data/bundle-layout.json`에 10개 배치도 번호별 `{pattern, ...}`를 둔다. 종류는 문자열 `wedge/ring/arc/grid`, 선택적 `columns_mode`, `forward_scale`, `shear`, `stagger`다. 번호키0~9는 기존 ID이며 신규 게임 규칙이 아니다. 원본의 봉시 -0.9/안행 +0.9, 학익0.45, 사선0.7, 어린0.25를 그대로 저장한다. grid 종류의 자동 제곱근/횡진2열/종진·장사진2열 정책을 각 레코드에 구분한다.

`BundleLayout.offsets(n, kind, step)`는 기존 API와 연산 순서, n=0 반환, unknown-kind 기본 grid를 유지한다. 원래 kind 분기만 데이터 레코드/문자열 분기로 치환한다. 파일 열기는 기존 단일 창구 `ProfileLoader.read_json`을 재사용하고 정적 캐시로 반복 I/O를 막는다. 기존 offsets 함수의 산술, 중심 합산, 순서, slots 경계축소/정렬/양자화는 유지한다. 데이터 손실/형식 오류는 오류를 명시하며 임의 계수 기본값으로 정상 결과인 척하지 않는다. 유효 파일의 정확 타입/필수키/유한수 검사는 새 작은 검사에서 다룬다.

배포 의존성: PC preset은 이미 `data/*.json` 포함한다. Android preset은 include가 md뿐이므로 기존 dirty `export_presets.cfg`의 해당 include 줄에 `data/bundle-layout.json`만 추가하는 최소 hunk를 허용한다. 기존 export 변경의 다른 줄은 보존한다. 이 배포 의존성을 독립 검토로 판단한다.

이번 코드 후보 변경은 `core/battle/bundle_layout.gd`, 신규 `data/bundle-layout.json`, 필요한 경우 export 한 줄, 신규 `tests/bundle_layout_data.gd`만이다. 기존 tests/data_rules.gd와 tests/bundle_layout.gd를 수정하지 않는다. 체크리스트의 원본 gate 한 항목과 별도 결과 문서에 이후 실제 판정만 기록한다.

## 3. 순서·성공 기준

1. 독립 계획 수용 후 원본 수정 전에 frozen bundle을 임시 GDScript로 로드해 기준 oracle 생성. n=0..40 및64/100, kind=-1..10, step=0/0.001/1/100/173.25의 offsets 전체 좌표/배열순서와 deterministic fleet fixtures의 slots 결과를 저장한다. slots는 경계/회전/반전/form_t/동률정렬을 포함한다. expected를 현행 slots로 다시 계산하는 group_formation만으로 동일성을 주장하지 않는다.
2. 위 데이터 분리 최소 구현. 동일 입력에서 before/after 출력이 정확히 일치해야 한다(최종 양자화뿐 아니라 offsets 포함). 차이가 있으면 이유 조사 후 K6 범위 수정; 의도적 동작 변경으로 합리화하지 않는다.
3. data_rules 실행으로 11건 재현 후 수정 뒤 전체 후속 검사/추격10까지 PASS와 실제 exit0 확인. 기존 검사 파일의 SHA가 동결과 같아야 한다.
4. 수정 뒤 원본7종 `core_rules`, `i01b_logical_clock`, `i01_operation_config`, `data_rules`, `hold_distance`, `commander_ai`, `battle_flow`를 각각 독립 프로세스로 순차 실행, 각 exit/표식/원문로그 기록. 여기에 `bundle_layout`, `group_formation`, 신규 data/동등성 검사를 실행한다. 기존 ObjectDB/resource 진단·TRACE open 경고는 기능 PASS/exit0과 분리해 기록한다.
5. 허용 변경 외 기존1008경로 SHA 불변/누락0 확인. 허용 파일도 frozen-before diff로 기존 hunk 보존 확인. HEAD/branch 불변, no commit/push. 생성 .uid/.import도 신규 생성 목록에 숨기지 않는다.
6. 별도 독립 리뷰어가 데이터 소유권/원본diff/동등 출력/전체 gate/보존감사 심사. 수용 후 결과 문서+CHECKLIST의 해당 gate만 갱신. 과거 결과 문서를 새 PASS로 덮어쓰지 않는다.

모든 실행은 `C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path C:/WorkSpace/SpaceBattleOfThreeKingdoms --script tests/<test>.gd --log-file <원본tmp 경로>` 형식. 테스트별 실제 종료코드와 출력 저장. 네트워크/브랜치/워크트리 불필요.

## 이후 I01b 다음 조각 (이번에는 계획까지만)

baseline fix 5-b 수용 뒤 기존 K/S/ST 계약과 P0 선언 재고를 따라, BattleSim의 실제 host/headless/replay 입력·출력 어댑터 접점과 runtime 동적 Dictionary/참조 의존성을 읽기 전용으로 더 좁혀 조사한다. snapshot 필드정책·commit_seq/command_seq·전체동시순서가 미정인 상태에서 저장 포맷/복원기를 임의 구현하지 않는다. 다음 조각의 검증 가능한 체크리스트/fixture와 독립 계획을 작성하고, 구현 확장은 별도 작은 루프로 둔다.

I01/I01b 및 A04/A05/A06는 계속 NOT_READY. slots 일치는 논리 선체외곽·충돌/중첩부재·제품 공간 완료가 아니다. 선언 재고는 저장 스키마가 아니며 시계60사례도 실제 host/replay/save 완성이 아니다. PC 화면/사람플레이·태블릿/수치확정은 이 수정의 성공 근거로 추가하지 않는다.
