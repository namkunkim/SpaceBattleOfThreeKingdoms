# 적벽 기술 효과 키와 호출 경로 전수 원장 계획

대상은 이 저장소에서 동결한 적벽 시나리오 하나와 고정 생산 GDScript 범위다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 계획 수용 전에는 원장 생성기나 fixture를 작성하거나 실행하지 않는다. 런타임 및 생산 코드 변경은 별도다.

## 분모와 원장

- data/scenarios/red_cliffs_208_realtime.json의 `realtime_rules.special_skills.skills` 배열 19개, 각 effect 사전의 top-level (skill_id,key) 33개, 고유 top-level key 24개. 각 기술을 파일상의 배열 순서로 기록한다. value의 JSON 타입과 값, 배열·사전의 하위 경로를 보존하고 하위 경로 분모는 top-level 33과 별도 집계한다. 최상위 효과가 빈 기술은 0개다. 기술 ID 중복과 JSON 중복 키는 원장 입력 실패다.
- 고정 GDScript는 `rg --files core scripts hud view input -g '*.gd'`에서 확인한 93개다. 시나리오 JSON 포함 94개 경로를 SKILL-EFFECT-SCOPE.sha256으로 동결했다. 소비 추적은 실제 호출, 조회, 생성, 노출, 명령, 통계·진단, 테스트/주석과의 경계를 각각 분류한다. 테스트 소스, 외부 앱, 반사 호출, 데이터 문자열로 만든 경로, 런타임 로드 전체는 분모 밖이다.
- lexical 후보 분모는 이 93개에서 `rg -n '\b(?:sim\.)?skills\.[A-Za-z_]\w*'`가 내는 31개 일치 행이다. 모든 일치 행에 실제 SkillCore 접근, 투영된 사전 접근, 주석 또는 기타 근거를 기록한다. 한 행에 여러 접근이 있으면 행 분모와 접근 분모를 따로 표시한다. lexical 행만으로 외부 경로를 확정하지 않는다.
- 별도 진입 trace는 `SkillCore.new` 생성, 조직화의 `special_skills` → 슬롯 입력, UI 선택 → skill 명령 → BattleSim.apply → SkillCore.use, AI think → ai_eval, tick → step, 투영 view/reveals → UI 표시, 사건 emit → FleetBattle3D 표시, fingerprint를 포함한다. 순서와 각 producer/consumer 소스 위치를 이어 적는다. 해시 범위 밖의 최종 사용자 경로가 드러나면 경계를 명시하며 조각 분모를 암묵적으로 늘리지 않는다.
- 24개 고유 키마다 초기 profile 입력, 즉시/기간/설정/주석 여부, 내부 직접 `e.*`·`has/get` 소비, 외부 `mul/mulf/add/flag` 등의 인수 호출, effect record의 ID/기한/stacking·참조를 묶는다. 실제 소비 근거가 없는 키는 UNCLASSIFIED이며 해당 기술이 동작한다고 추정하지 않는다. 별도 producer가 읽는 `requires/ai_when`은 effect key 24의 일부가 아니다. 기존 SkillCore 7/FleetState 3의 상태 원장에 교차 참조하고 이전 분모를 합산하지 않는다.

## 5a와 독립 심사

1. 독립 oracle은 심사자가 동결 JSON에서 (skill_id,key,value)의 순서 있는 목록을 수기로 확인하고, 파일 경로별 lexical 후보와 별도 진입 trace의 source anchor를 대조한다. 생산 GDScript의 전역 런타임 호출 증명은 요구하지 않는다.
2. 수용 후 전용 `skill-effect-ledger/`의 Python 읽기 검증기는 `--manifest-sha256 <sha> --out <attempt>`로 실행한다. PowerShell `$ErrorActionPreference='Stop'` 및 실제 `$LASTEXITCODE` 전달을 사용한다. 정규 경로·정확 집합·누락/중복과 SHA를 시작/종료에 검증한다. HEAD/Git status와 동시 P02/다른 P03의 변화는 따로 기록한다. 실행 직전 도구·oracle·실행기·의존 파일을 별도 manifest로 동결하고 manifest SHA를 기록한다.
3. 대조 분모는 정상 exit 0, 복사본의 고정 효과 키 `assault_bp`를 제거해 (SK-U-GUANYU,assault_bp) 하나를 검출하는 exit 1, 외부 소비 후보 목록에서 `core/battle/detection.gd:94`의 sensor_mul_bp 행만 삭제해 그 정확한 파일:행 차집합 1개를 검출하는 exit 1, 적벽 JSON 후보 경로를 존재하지 않는 전용 파일로 지정한 필수 입력 부재 exit 2다. 후보 제거의 원문 변형은 전용 폴더에서만 수행한다. 검증기는 각 child 실제 exit/차집합/stdout/stderr를 보존하고 모든 기대값 일치에만 suite exit 0을 낸다. 재시도 K=3, 사용량 제한 시 즉시 보고하고 반복 중단.
4. 사후 5b는 구현에 참여하지 않은 비-Astra 모델이 수기 oracle, 키·행 누락 대조, 호출 경로의 source anchor와 범위 밖 경계를 대조한다. 계획 수용과 실행 후 검증은 별개다.
