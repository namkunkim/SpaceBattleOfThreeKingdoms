# 캠페인 백그라운드 검증 — 2026-11-13

검증 기준은 원격 main의 cabc4de3이다. Windows 전경 입력은 수행하지 않았다.

| 항목 | 확인한 범위 | 남은 조건 |
| --- | --- | --- |
| K6 17·18행 | 현재 Git 소스에 비교용 변형 4개와 공통 QA 오버레이 1개를 준비했다. Git 원본 바이트와 LF 정규화 해시를 구분해 기록했고, 기존 실행·판정 도구와 입력 근거 13개의 해시를 대조했다. | 최종 실행 매니페스트 동결 및 실제 입력 전후 비교. |
| P08·P09·O07 | 소스 1d13fdad의 Windows 후보에서 격리 헤드리스 기동 3/3. 고의로 무효인 시험 슬롯이 있는 프로필은 WorldMap, 빈 프로필은 NewEntry, 명시적 O07 모드는 RestrictedOperationHost를 로드했다. 모두 종료 코드 0, 엔진 오류·경고 0건이었다. 시험 슬롯 바이트는 동일했고 다른 프로필에 슬롯이 생기지 않았다. | 실제 1600×900 전경 플레이·성능, 오디오와 전체 TRACE, 운영 슬롯·지급·물리 전원 차단 인수. |

K6 소스 준비 기록 SHA-256은 c3cb459930e3d53695f128489da4d98b26cc4e379b672af7ec75622d3ba3df67이다. 정식 실행에는 [K6 재개 절차](K6-ROW17-18-WINDOWS-RETRY.md)를 따른다.

이전 Windows 후보(1d13fdad)의 EXE SHA-256은 875ca9d67f7b110b02a2906458c0a247f36552239bb3671648203b63b5a8b3ce다. 프로필 시험은 슬롯 존재에 따른 화면 분기와 저장 경로 격리를 확인했다. 정식 인수 조건은 [Windows 인수 준비](../../entry/windows-acceptance-preparation-20261113-ko.md)에 있다.

P08 PresentMon 오프라인 예행 검증은 보존 ETL의 56행에서 PID·스왑체인, 인접 QPC 구간 및 DisplayedTime 결측값을 확인했다. 실제 플레이 성능 검증은 남아 있다. [P08 오프라인 결과](evidence/20261113/p08-presentmon-phase-dryrun/RESULTS.md)

K6 비교 전후 프로젝트를 격리된 Windows 작업본에 생성했다. 전후 차이는 기존 비교용 파일 4개이며 공통 QA 관찰 오버레이는 동일하다. 두 프로젝트에서 관찰기 파싱 및 EntryBoot 로딩이 각각 통과했다. [검토용 매니페스트](evidence/20261113/k6-rows17-18-headless/REVIEW-MANIFEST.json) · [헤드리스 결과](evidence/20261113/k6-rows17-18-headless/SMOKE.json)

## Windows 후보 `4dac0b8d` 후속 검증

- 격리 헤드리스 기동 3/3. WorldMap·NewEntry·RestrictedOperationHost 분기에서 종료 코드 0, 엔진 진단 0건, 시험 슬롯 바이트와 프로필 격리를 확인했다. [결과 JSON](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/Windows-candidate-4dac0b8d-20261113/smoke/RESULT.json) SHA-256 `dc1d6e54c694f697d15cde53bb61a4bfe6173a97c2f7c46e0fea9834401e757f`.
- Windows 1600×900 전경에서는 `--first-operation-trace`로 제한 검증 호스트의 정면 경로를 실행했다. TRACE 순번 1–644가 연속이며 틱 5541·554.1초에 A 활성, C 점령 및 `objective_success` 결산 후 세션이 닫혔다. 전체 화면에서 **연합 승리**를 확인했고 리플레이 파일 선택기를 열어 취소한 뒤 종료 코드 0을 관찰했다. 리플레이 재생, 공개 제품 일반 전투, 성능 및 오디오는 검증 범위에 남아 있다. [전경 TRACE](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/Windows-candidate-4dac0b8d-20261113/foreground-route-smoke-01/APPDATA/Godot/app_userdata/SpaceBattleOfThreeKingdoms/first_operation_traces/operation-2026-11-13T20-01-28-14004-68647881.jsonl) SHA-256 `b73d3bb853992d0b06270e59aa776b244612c545ccd25dbaa183acdeb0d31d46`.

| 배포 파일 | SHA-256 |
| --- | --- |
| `SpaceBattleOfThreeKingdoms.exe` | `baef695f4b5a60ba9fbeb5b3aa8e11800b99f0e47220e79085ba2b1149a472b8` |
| `o07_win32.dll` | `e84a35135a5902a86db44fe033ec878dcf8eab03958827495afa1b933c00659c` |
| `_build/fingerprint.json` | `517027d6ceeaebba808bcddc38965f7ef411b9e94888e9192c1e16f6b76dcc62` |
| `_build/replay-fingerprint.json` | `98e0767ad293b23338285dde9751a53f4db6c254f14b6d07eb6663290186ab54` |
| `_build/verify-final.log` | `4ecf7cf06fc3acff1301bef42e3e7417c7fb35945e9412807a647d60843d204c` |

## K6 17-before 후속 시도

`4dac0b8d`에서 17·18행 전후 네 케이스의 고정 매니페스트와 두 QA 레인 파일 6,522개의 해시를 검증했다. 첫 17-before는 실제 클릭 9/10건을 기록했다. 출격 해제 후 6.658초에 자연 진행했고, 필수 건너뛰기 클릭이 누락되어 기록기가 시간 초과했다. 자연 결산은 기대값과 일치했다(틱 11350, 1134950ms, 지문 `c0e18c8c758f6767e67761630cc68cd2a5aeb2e9a5e87d0bf5cd14da5d880acb`). 이 시도의 정식 PASS는 0건이며 17·18행 전후 비교가 남아 있다. [고정 매니페스트](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-18-runner-20261113/MANIFEST-FROZEN-CANDIDATE.json) SHA-256 `212de24d4ab404e30717945b8c88466a3cf892098a3f60772653590b3ddabc31`. [원시 출력](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-18-runner-20261113/formal-run-01/17-before/stdout.raw) SHA-256 `61b8da2002404f3782e69d7d1d855fd45cd614adc0555ad613a39152f571ec44`. [재시도 분석](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-18-retry-analysis-20261113/ROW17-RETRY.md)

- P08 PresentMon 2.6.0 격리 사전 검사에서 라이브 ETW 권한이 거부되어 종료 코드 6을 기록했다. 제품 성능 측정은 남아 있다. [ETW 사전 검사](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/sbtk-p08-etw-82fbc41037ed/RESULT.json)
