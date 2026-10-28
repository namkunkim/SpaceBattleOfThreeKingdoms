# 원본 data_rules 기하 분리 독립 5-b

2026-10-28 / 독립 심사 담당 / **수용**.

검토자는 구현·검사 실행에 참여하지 않았으며 생산코드를 수정하지 않았다. 원본 main HEAD 8292805143f4561a4f5258d40b7b94adf4ff5802의 계획·최종 diff·로그·SHA를 직접 대조했다. 증거 루트는 tmp/i01b-followup-20261028/다.

## 직접 확인

- 동결1008경로를 전량 재해시: 허용한 core/battle/bundle_layout.gd와 export_presets.cfg만 변경, 나머지1006 일치, 누락0.
- test-results.json의 전체 로그와 변경4파일 SHA를 직접 재계산: 불일치0.
- frozen Before는 class_name 한 줄을 주석으로 치환한 것 외 동결 원문과 정확동일. 동결 bundle SHA는 52fde94aa9d2cca411ee038856643934990aac7de26ad7141ce3f9e61e379101.
- _less부터 파일 끝(slots 포함)까지 동결본과 문자정확동일. tests/data_rules.gd와 tests/bundle_layout.gd도 동결 SHA 유지. 숫자 allowlist/skip/UNIT_CONSTS 완화 없음.
- JSON의 0~9 분기·열 정책·기하 계수는 기존 구현과 일치. ProfileLoader 단일창구·캐시를 사용하고 unknown kind는 기존 auto grid. 알려진 kind 누락/잘못된 데이터는 명시 거부.
- Android include 한 변경을 역치환한 바이트 SHA가 동결 export SHA 7ba4a2556b4b6fab394f14de74ede901e1d5bed0029d48a7c2da3657b909050f와 일치. 기존 아이콘/PC preset 변경 보존. 실제 export는 미실행.

## 검사 증거

실행 담당의 실제 종료 기록과 로그 원문을 대조했으며 검토자가 Godot를 재실행한 것은 아니다.

- 수정 전 data_rules: exit1, 리터럴11건 재현.
- 수정 후 core/clock/config/data/hold/AI/flow/bundle/group 9종: 모두 exit0 및 PASS.
- data_rules: keys80/core28/proposed28/first_move1814. 기존 추격10사례와 후속 검사까지 실행.
- 신규 기하56검사 exit0. frozen exact3588사례 failures0/exit0. 실제 Vector2 배열과 Dictionary/keys/values를 직접 비교하여 반올림 및 순서 누락을 피했다.
- invalid loader3종: 명시 오류+빈 offsets의 예상 거부 exit0. 최초 임시 harness path 타입추론 parse 오류 exit1은 보존됐으며 String 명시 후 통과. 생산코드 오류로 혼동하지 않는다.

종료 ObjectDB/resources-in-use 진단이 data/hold/AI/flow/bundle/group에 남고 flow/group의 TRACE log-open 경고도 남는다. 기능 PASS/exit0과 별개이며 깨끗한 종료·trace 기록 성공·누수 회귀 부재를 보장하지 않는다. invalid loader3개의 ERROR는 손상 fixture의 예상 오류다.

반대 증거: group_formation의 동일 생산함수 기대값 한계는 frozen-before 대조가 보완한다. 손상 데이터에서 slots까지의 정상 종료는 검증되지 않았고 추가 인덱스 오류 가능성이 있으나 정상 데이터 동작 보존 판정의 비차단 제한이다. 테스트 입력에서의 slots 동일성은 선체 외곽·충돌/중첩 부재 증거가 아니다.

**원본 data_rules 전체 gate의 기하 리터럴 기준선 실패 해소를 수용한다.** 추가 코드 수정은 필요하지 않다. HEAD/branch 불변, 커밋·병합·푸시 없음. 기존 실패 이력은 보존하고 최신 결과를 별도 연결한다. I01/I01b 및 A04/A05/A06는 NOT_READY이며 host/replay/save·제품 공간·화면·기기·사람 플레이 완료가 아니다.

## 별도 P2a 계획 판정

baseline 수용 이후 별도 1~3단계로 **착수 가능**. 생산불변, 신규 tests/i01b_runtime_inventory.gd와 증거/기록만 허용한다. B0는 생성자 반환 직후이며 host direct 배정·projection/drain 이후 C0와 구분한다. POC/적벽 표준 × seed10 × fresh2=40관측, 정순/역순, 명시 필드의 실제 타입·단위·키/배열 순서·참조 identity 및 추출 전후 불변을 검사한다.

저장 분류 UNCLASSIFIED 유지. deep-copy 변이 probe는 관측 사본 격리 증거이며 fresh sim 전체 alias 부재로 확대하지 않는다. 직접 identity 확인한 컨테이너 목록을 명시한다. null은 생성자 sourcebranch 기반 observed_absent로 기록한다. 빈 contacts는 초기 관측이며 비초기 스키마 완성이 아니다. 실제 검사·보존 감사·독립 최종5-b는 별도로 필요하다. 이번 판정은 P2a 구현 결과나 전체 저장 계약의 수용이 아니다.
