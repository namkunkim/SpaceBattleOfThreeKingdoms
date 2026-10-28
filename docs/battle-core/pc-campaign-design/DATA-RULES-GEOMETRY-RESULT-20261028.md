# data_rules 원본 기하 기준선 해소 결과

2026-10-28 KST. **최소 변경·5-a 검사·독립 5-b 수용 완료.** 커밋·푸시하지 않았다. 전체 I01/I01b와 A04/A05/A06는 계속 NOT_READY다.

## 해결한 범위

원본에 이미 존재하던 `core/battle/bundle_layout.gd`의 숫자 리터럴11건 때문에 data_rules 첫 정적 검사가 실패했다. 기존 추격 fallback170 수정과 별도 문제다. 이번에는 배치도 번호별 모양·기하 계수를 `data/bundle-layout.json`으로 분리하고 `ProfileLoader` 단일 파일 읽기 경로와 정적 캐시를 사용했다. 기존 봉시/안행 ±0.9, 학익0.45, 사선0.7, 어린0.25 및 분기 매핑을 유지했다.

`offsets(n, kind, step)` API와 산술·배열 순서, `slots` 전체 함수는 보존했다. 알려진0~9 배치도의 누락·잘못된 형식은 명시 오류로 거부하고, 범위 밖 kind에만 기존 자동 격자 분기를 유지한다. data_rules의 숫자 allowlist/skip/UNIT_CONSTS와 기존 tests/data_rules.gd·tests/bundle_layout.gd를 수정하지 않았다. 상수 산술이나 기존 exempt 함수로 검사를 우회하지 않았다.

Android preset에는 새 JSON 경로만 포함하도록 include 한 줄을 추가했다. 그 한 줄을 역치환한 전체 파일 SHA가 동결본과 일치한다. PC preset의 기존 JSON 포함 설정을 재사용했다. 실제 Android export·패키징은 실행하지 않았다.

## 5-a 실제 실행

Godot `4.7.2.stable.official.ed1daf0bf`, 원본 `C:/WorkSpace/SpaceBattleOfThreeKingdoms`, HEAD `8292805143f4561a4f5258d40b7b94adf4ff5802`에서 실행했다. 수정 전에 data_rules의11건 실패와 실제 exit1을 다시 확보했다. 수정 후 아래9종은 각각 별도 프로세스로 순차 실행하여 **모두 실제 exit0**을 확보했다.

| 검사 | 실제 결과 |
|---|---|
| core_rules | CORE_RULES_PASS |
| i01b_logical_clock | 부분시계60사례 PASS, tick2/end150ms |
| i01_operation_config | I01A_OPERATION_CONFIG_PASS; 기존326 checks 검사 |
| data_rules | DATA_RULES_PASS keys=80 core=28 proposed=28 first_move=1814; 첫 gate 이후 전체 후속/기존 추격10사례 실행 |
| hold_distance | HOLD_DISTANCE_PASS |
| commander_ai | COMMANDER_AI_PASS |
| battle_flow | BATTLE_FLOW_PASS |
| bundle_layout | BUNDLE_LAYOUT_PASS |
| group_formation | GROUP_FORMATION_PASS |

추가 검사:

- `tests/bundle_layout_data.gd`: JSON0~9 완비·원래 매핑/계수·정확 타입·필수키·유한수·범위 밖 grid 등 **56 checks, exit0**.
- 동결전 구현을 별도 GDScript로 로드하고 현재 구현과 실제 Vector2/배열/Dictionary를 직접 비교했다. offsets는 n0~40/64/100 × kind-1~10 × step5종, slots는 빈/단일/다수 함대·회전·반전·form_t·경계축소·정렬을 포함했다. Dictionary 키/값 순서도 비교하여 **3588사례·차이0·exit0**. JSON 문자열 반올림 비교가 아니다. 원래 slots를 호출해 expected를 다시 만드는 group_formation의 한계를 이 독립 동결 비교로 보완했다.
- 격리된 잘못된 데이터3종(알려진kind 누락/잘못된pattern/계수타입 오류)을 실제 로더에 연결하여 명시오류와 빈 결과 반환을 확인했다. 정상 grid로 조용히 대체하지 않았다. **기대 거부3사례·exit0**. 이 임시 검사 harness는 첫 시도에 path 타입추론 parse 오류 exit1이 있었고, 명시 String으로 고친2차 시도가 통과했다. 첫 실패 로그도 보존했으며 생산 코드 재수정은 없었다.

기능 PASS와 종료코드0은 깨끗한 종료를 뜻하지 않는다. data/hold/AI/flow/bundle/group에서 ObjectDB/resources-in-use 종료 진단이 남고, flow/group에는 TRACE 파일 열기 경고가 남는다. trace 성공·누수 회귀 부재·깨끗한 종료를 보장하지 않는다. 잘못된 기하 데이터에서 offsets는 명시 오류와 빈 배열을 내며, 이를 slots가 정상 배치로 복구하는 기능은 이번 범위가 아니다.

## 보존·독립 심사

작업 시작 시 현재 변경/미추적1008경로 SHA를 동결했다. 이전 이관 전960경로는 전부 같은 SHA였다. 구현4파일은 기존 bundle_layout·export_presets 2개와 신규 JSON·검사2개다. 독립 리뷰어가1008경로를 직접 재해시하여 허용2개 외1006경로 동일·누락0, 구현4파일 및 로그 SHA 일치, 동결 clone이 class_name 주석 외 동일함을 확인했다. slots 함수 전체가 문자 단위로 동일하고 Android include 역치환 SHA도 동결과 일치한다. 6기록 단계의 CHECKLIST 한 행 및 이 결과문서는 구현 뒤 문서 변경으로 분리한다.

독립 5-b는 변경 전후 출력·원본diff·JSON 소유권·정확비교·9종 종료코드·보존감사를 대조하고 수용했다. 독립 raw 심사는 [기하 기준선 독립 검토](REVIEW-DATA-RULES-GEOMETRY-20261028.md)에 기록했다.

증거 정본은 `tmp/i01b-followup-20261028/`다. `PLAN.md`, `before.json`, `prior-comparison.json`, `baseline/`, `before-test-result.json`, `gate-results.json`, `test-results.json`(전체로그SHA·종료진단), `initial-geometry-results.json`, `invalid-loader-results.json`, `exact_compare.gd`, `invalid_loader.gd`, `bundle-only.diff`, `export-one-line-proof.json`, `preservation-audit.json`, `verify-preservation.ps1`, `logs/`에 입력·원문·실제 종료코드·대조 결과를 보존한다.

## 6 기록과 다음 경계

CHECKLIST의 원본 data_rules 기준선 한 항목만 완료로 기록했다. 이전 원본 이관 당시 첫 gate 실패·후속 미실행 기록과 관리 작업트리 PASS 이력을 새 결과로 덮어쓰지 않는다.

이번 기하 동일성은 논리 선체 외곽·충돌/중첩 부재·제품 공간 완료가 아니다. 선언 재고는 저장 스키마가 아니고 P1시계 검사는 실제 host/replay/save 완성이 아니다. 다음 I01b 조각은 기존 K/S/ST 계약을 따라 실제 어댑터 접점/런타임 동적 컨테이너·참조를 읽기 전용으로 좁혀 조사하고 작은 검증 계획을 작성한다. 저장 포맷·commit_seq/command_seq·미확정 수치/동일틱 정책을 임의 확정하지 않는다.

되먹임: 공유 dirty의 독립 기하 수정도 정적 core 검사에 영향을 줄 수 있다. 기준선을 실제 원본에서 다시 실행하고, 검사 완화 대신 데이터 소유권을 분명히 하며, 동결전 구현의 실제 출력과 기존 변경 SHA를 함께 대조한다. PASS 표식·프로세스 종료코드·종료진단·실제 패키징 여부를 구분해 기록한다.
