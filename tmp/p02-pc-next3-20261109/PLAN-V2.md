# 직접 출격 난이도 정합 실행 명세 초안

독립 재심 대기. PLAN.md와 첫 심사 기록을 보존한다. 아래 명령은 인수 명세다. 후보, probe, 실행 manifest, 런처의 실제 바이트 및 SHA가 독립 검토되기 전에는 실행하지 않는다.

## 후보와 경계

- FleetBattle3D._prepare_game에서 routed 시나리오만 선택 난이도를 결정한다. 지역 변수 하나를 첫 자동 편성, 수동 편성 기본 프로필, Organization.apply 거부 후 자동 편성, 빈 자동 편성 뒤 기본 프로필 재로드에 일관되게 전달한다. 기존 profile_patch는 최종 후보에 같은 순서로 적용한다. 기존 후보 사전에 추가하고 _publish_game에서만 host difficulty에 반영한다. publish 진단에는 게시된 난이도가 들어간다. 초기 seed와 기존 restart 호출 구조를 유지한다.
- POC는 profile_def가 빈 때만 명시 진입하며 정본 장면 기본값은 적벽이다. 기존 PocSetup.profile, host difficulty와 빈 RuleSet.scenario 동작을 보존한다. 기존 데이터 장애에 따른 자동 편성→기본 시나리오→POC fallback과 오류 메시지도 유지하고 POC fallback에 난이도 적용 성공 판정을 부여하지 않는다.
- WorldMap은 승인 목록의 버튼만 실제 입력으로 열고 WorldLink는 brief를 재검증하지 않는다. AutoResolver.start는 BattleBrief.validate를 사용해 거절한다. 따라서 비정상 직접 brief는 기존 코드에서 seed만 적용되고 invalid difficulty가 무시될 수 있다. 후보 정책은 routed 적벽 profile 준비에만 알 수 없는 난이도의 명시 준비 거절을 제안한다. invalid difficulty를 표준 또는 POC 성공으로 변환하지 않는다. standalone 임의 difficulty와 다른 모드/카드/시나리오 ID 계약은 이번에 바꾸지 않는다. 기존 안내에 '난이도가 올바르지 않습니다' 분기 한 줄이 필요하며, invalid 정책은 독립 재심의 명시 승인 항목이다.
- 원본 제품 변경 후보는 FleetBattle3D 한 파일이다. P03 restore/owner/P05/P07/WorldMap 및 미적용 여덟째 후보를 병합하지 않는다. 상대 쓰기 창과 이 파일의 원본 SHA, index 및 여덟째 패치 위치를 구현·격리 실행·원본 적용 단계마다 다시 대조한다. 충돌 또는 드리프트 시 중단한다.

## 원본 독립 기대값

동결 JSON 두 개를 Python 표준 json으로만 읽는다. 원본 프로필 side_by_control과 시나리오 factions를 결합해 진영을 결정하고 원문 squadrons 순서를 유지한다. morale_group 키가 있는 전대의 누적 ordinal이 cao_fleets를 넘으면 제외한다. 나머지 side 1의 sq.id·deploy_delay_s를 순서 그대로 기대 배열에 쓴다. side 0의 ID와 유비/손권 구분도 같은 원문에서 기록한다. Organization과 ScenarioProfile을 호출하지 않는다. 생성 JSON 및 두 원본 SHA를 독립 심사에 제공한다.

| 난이도 | side 1 기대 전체 ID 접미사 RC-CAO-SQ-* | 대기 0초 | 180초 | 360초 | AI suspicion/s |
|---|---|---|---|---|---|
| 입문 | 01–09 | 02, 04 | 01, 03, 05 | 06–09 | 0.4 |
| 표준 | 01–10 | 02, 04 | 01, 03, 05 | 06–10 | 0.8 |
| 상급 | 01–14 | 02, 04 | 01, 03, 05 | 06–14 | 1.5 |
| 극한 | 01–14 | 02, 04 | 01, 03, 05 | 06–14 | 2.0 |

cap 9/10/14/14는 JSON 입력이며 위 전체 ID는 별도 추출 결과다. BattleSim 생성자는 지연 전대도 즉시 st.fleets에 할당하며 _spawn에서 f.wait를 BattleRules.ticks로 저장한다. 10Hz 기준 0/1800/3600을 actual sq_id와 짝지어 대조한다. 초기 브리핑 FOE_DEF에는 delay=0만 들어간다. spawn 수를 '전투 개시'로 해석하지 않는다. CommanderAI는 기다리는 전대라도 적이 교전 반경에 들어오면 반응할 수 있으므로 시간 도래까지 비활성이라는 단언도 하지 않는다. _publish_game이 초기 사건을 drain하므로 사건이 남았다고 가정하지 않고 초기 배정 roster와 wait를 실제 증거로 쓴다. BattleSim.rs → RuleSet.difficulty_ai() → Stratagem의 suspicion 계산이 같은 값을 읽는다. 실제 rs의 ai dict 전체와 start_morale_bp를 원본에서 독립 생성한 기대값과 대조한다. 탐지 거리·공간과 결합한 시간 플레이 시험은 이번 설정 인수에 집계하지 않는다.

## 고정 실행 명령과 판정

격리 경로 `attempt-01/project` 하나에 before→after 순차 적용한다. 고정 입력 seed는 777이다. PowerShell supervisor는 기존 P02DirectJob.cs와 launch.ps1의 동결된 사본을 기반으로 root suspended create→Job 등록→resume한다. 명령별 독립 APPDATA/LOCALAPPDATA/XDG_DATA_HOME/TEMP/TMP, log, expected path를 쓴다. Godot 4.7.2 본체와 supervisor 바이트를 고정한다.

- Import 2개. 각 phase `Godot --headless --path PROJECT --log-file LOG --editor --import`, timeout 240초, exit 0. 전환 시 승인 후보 1개만 덮고 재임포트한다.
- Headless 각 phase 13개. `Godot --headless --path PROJECT --log-file LOG --script res://tests/p02_difficulty_probe.gd -- CASE PHASE`. 실제 canonical scene/autoload와 UI 버튼을 사용한다. 시작 전 독립 fixture만 seed·고장 seam을 연결하고 정상 dispatch에서 고장 seam은 비어 있어야 한다.
- Windows 1개. after `Godot --windowed --path PROJECT --log-file LOG --resolution 1600x900 --position 80,80 --script res://tests/p02_difficulty_probe.gd -- D03 after-physical`, timeout 180초. 이 프로브의 허용 동작은 seed 777 고정과 수동 입력 단계 관측이다. P02 후보의 준비 경로와 실제 버튼 입력을 대행하지 않는다.
- 합계 29 프로세스. 각 phase 13행, 별도 실제 OS 입력 1행, 별도 import 2개다. D03 headless와 물리 입력은 같은 시나리오의 서로 다른 증거 행이다. 첫 계획의 11행에 D12/D13 두 정책 경계와 D03 물리입력을 별도 증거로 확장했다.

| CASE | fixture와 필수 판정 ID | timeout |
|---|---|---|
| D01/D02/D03/D04 | 입문/표준/상급/극한. 카드 버튼→직접 출격→건너뛰기→브리핑→시작→배치 확정. `route.seed`, `route.difficulty`, `profile.host`, `profile.rules`, `roster.full`, `roster.wait`, `roster.brief`, `start.controls`, `placement.tick`, `result.seed`, `result.difficulty`, `result.once`. D03 clean 서막, 나머지는 동결 returning cfg. 결과는 기존 tests/world_link.gd와 같은 종료 fixture의 synthetic 표기를 붙인다. | 각 120초 |
| D05 | 상급, 기존 편성 UI에서 자동 편성 생성 후 유비군 비기함 1개 출전 해제, 같은 편성 확정 후 시작. `org.open.rules`, `org.apply.excluded`, `profile.rules`, `roster.full`. 제외가 기존 validator를 통과하는 ID인지 실행 전 독립 검토한다. | 120초 |
| D06 | 상급 결과 재출격 실제 버튼. `retry.same.brief`, `retry.new.sim`, `retry.same.seed`, `retry.same.rules`, `retry.same.roster`. 첫/후속 모두 독립 기대값과 대조한다. | 120초 |
| D07 | 상급 초기 준비 직전 profile_patch가 foe를 잘못된 타입으로 바꾼다. `prepare.no.sim`, `prepare.no.deck`, `prepare.notice`, `return.map`, `return.no.result`, `return.last.difficulty`. | 90초 |
| D08 | 활성 상급에서 profile_patch가 후보 사전을 clear한다. `fail.same.sim`, `fail.same.seed`, `fail.same.difficulty`, `fail.same.g`, `fail.same.clocks`, `fail.same.selection`, `fail.same.trace`, `fail.same.link`, `fail.notice`, `retry.valid`. 같은 프레임에서 실패 전후를 읽어 정상 프레임 변동을 제외하고 양 시계 인스턴스·phase·speed, G 깊은 사본, sim identity/fingerprint, UI/카메라·trace 크기와 hash를 비교한다. | 90초 |
| D09 | standalone 적벽 장면, 타이틀→시작→재시작. 동일 원본 fixture를 양쪽에 적용하여 RNG 시드를 고정한다. `legacy.title`, `legacy.default.rules`, `legacy.roster`, `legacy.restart`. 무작위 seed 자체를 제품 회귀로 보지 않는다. | 120초 |
| D10 | 상급 WorldMap 자동 해결, 고정 777. `auto.validate`, `auto.worker.started`, `auto.completed`, `auto.joined`, `auto.outcome.seed`, `auto.outcome.difficulty`. worker profile 관측이 필요하면 테스트 전용 계측 별도 SHA를 사용하며 thread 동작을 바꾸지 않는다. | 240초 |
| D11 | 상급 수동 편성 사본에 잘못된 전대 ID를 넣어 apply 거절 유도. `fallback.org.errors`, `fallback.start.blocked`, `fallback.rules`, `fallback.roster`. 같은 규칙의 자동 편성 대체가 기대다. | 90초 |
| D12 | standalone profile_def 빈 격리 fixture. `poc.rs.empty`, `poc.no.scenario`, `poc.legacy.difficulty`, `poc.no.link`. | 90초 |
| D13 | 실제 카드가 만들 수 없는 invalid 직접 brief를 격리에서 WorldLink로 넘긴다. `invalid.no.sim`, `invalid.notice`, `invalid.return.no.result`. 첫 장면 준비만 바꾸고 auto invalid 검증은 별도 기준선을 유지한다. | 90초 |

예상 baseline 적색 행은 D01/D03/D04/D05/D06/D11/D13의 7개다. D08은 활성 상급이라고 표시된 기존 표준 sim의 원자성과 정상 재준비 가능 여부만 비교하며 그 행에서 난이도 정합을 이중 집계하지 않는다. 구체 red ID만 허용한다. D01/D03/D04는 profile.host/rules/roster.full/wait, D05는 org.open.rules/profile.rules/roster.full, D06은 retry.same.rules/roster의 독립 기대 대조, D11은 fallback.rules/roster, D13은 invalid.*이다. before에서도 잘못된 로직의 사실 측정을 끝까지 진행하고 D13의 결손만 구조적으로 분리한다. 정상/예상 적색 모두 완결된 raw JSON + sentinel을 쓴다. 예상 적색 프로세스는 1, 정상은 0, 감독 timeout은 125, 다른 종료는 실패로 기록한다. D07/D08은 기존 `invalid_candidate_profile at profile.foe/profile` 각각 한 건, after D13은 명시 invalid 준비 진단 한 건을 예상한다. 그 외 parser/resource/scene/노드/스레드 오류는 신규 실패다. 기존 ObjectDB/resource 종료 진단은 과거 결과를 그대로 allowlist하지 않고 동일 before→after 원문과 개수를 비교한다. 실행 승인 전 실제 probe의 단언 ID와 fixture를 이 표에 일대일 대응시킨다.

## 실제 Windows 입력

UI 드라이버 계획은 user32 EnumWindows/GetWindowThreadProcessId로 Job root PID와 HWND를 확인하고 GetForegroundWindow 및 client rect가 일치하는 경우에만 SendInput을 실행하는 것이다. 정확한 exe 경로·프로세스 시작 시각·Job membership·HWND를 먼저 저장한다. CUA의 이전 foreground 실패를 원인 확정으로 다루지 않는다. 별도 앱을 강제로 닫거나 사용자 참여를 가정하지 않는다. 전경을 확보하지 못하면 실제 입력은 0건으로 남긴다.

입력은 형주 카드→상급→직접 지휘→출격→출격 연출 건너뛰기→서막 건너뛰기→브리핑의 시작 버튼→배치 확정 순서다. Windows 화면과 실제 제품 viewport를 각각 캡처한다. 읽기 전용 probe에서 발견한 실제 버튼 rect와 DPI에 따른 client-to-screen 변환으로 좌표를 정하고, 소유 HWND·전경·화면 내용 및 단계별 실제 mouse down/up 수신을 다시 기록한다. OS 입력 직전과 직후 QPC 타임스탬프, raw 이벤트 및 전환 PNG를 저장한다. 이벤트 주체나 다음 화면이 불명확하면 이후 입력을 금지하고 Job을 닫는다. 증거 도구 또는 Windows 입력 정책이 허용하지 않으면 미검증으로 남긴다. 합성 이벤트는 이 행에 포함하지 않는다.

## 동결과 자원 한도

이전 승인된 freeze.py의 실제 closure 목록과 이번 프로젝트의 tracked/runtime 경로 차이를 읽기 전용으로 대조하고, 프로젝트 설정·정본 장면·스크립트·설정 fixture·data/assets·사용 리소스를 SHA/바이트 크기 포함 manifest로 확정한다. 운영 로그와 tmp/output 이전 산출물, 원본 .godot, 미동의 공유 변경은 새 격리물의 입력으로 무심코 복사하지 않는다. before/after 같은 P03 동결본과 동일 scene/resource closure를 쓴다.

이전 유사 실행의 closure 약 670 MB, import cache 실제 334,714,454 B를 기준으로 새 피크 예산은 closure 700 MB + cache 400 MB + import 중간물 200 MB + 29행 로그·PNG·userdata 100 MB = 1.40 GB다. 독립 승인 전 실제 closure 크기와 신규 assets/import 증가량을 읽기 전용으로 산출한다. 시작 최소 2.90 GB 및 각 명령 사이 최소 1.50 GB를 확인하고, 비용이 예산을 넘으면 복사를 시작하지 않는다. 원본·과거 산출물을 삭제하지 않는다. 시도 상한 제안은 이번 29개 프로세스 단일 실행 세트 1회이며 새로운 실행 승인으로만 확정한다. PC0 2/2 및 여덟째 K6 미사용 기록을 유지한다.
