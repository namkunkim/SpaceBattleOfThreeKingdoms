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

### K6 17-before 재시도 독립 검토

`4dac0b8d` 17-before 재시도에서 승인된 Windows 자동화 입력 10건을 기록했다. 원시 상관과 의미 판정이 모두 PASS였고, 독립 검토에서 두 판정을 재생성해 보존 결과와 일치함을 확인했다. 레인 파일 지문과 검토·승인·nonce 영수증도 일치했다. 결산은 틱 11350, 1134950ms, 지문 `c0e18c8c758f6767e67761630cc68cd2a5aeb2e9a5e87d0bf5cd14da5d880acb`였다. 이전 실패 시도는 위에 남겼다. 이번 판정은 17-before 한 건이며, 17-after 및 18행 두 케이스의 정식 비교가 남아 있다.

| 재시도 근거 | SHA-256 |
| --- | --- |
| [원시 판정](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-before-retry-draft-20261113/formal-run-17-before-retry/17-before/raw-verification.json) | `d739446b574ad1dbd87940b97a3b392ff1484625cd0cc83a932e250f85774d00` |
| [의미 판정](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-before-retry-draft-20261113/formal-run-17-before-retry/17-before/semantic-verification.json) | `d1572487c85c6f4a4fe8bb990ec486cc7627bfd140d114238f17a02a564c47c0` |
| [원시 출력](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-before-retry-draft-20261113/formal-run-17-before-retry/17-before/stdout.raw) | `f5129f20e1b7f8a70a80c43b867d37eb7c266d1eceacd416287454b964d6ec5e` |

### K6 17행 전후 독립 대조

`4dac0b8d`의 원래 17-after 시도는 전경 관찰기 준비 시간 초과로 종료됐으며 입력은 0건이었다. [원래 관찰기 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-18-runner-20261113/formal-run-01/17-after/observer-arm-timing.json)

별도 출력 경로에서 재시도한 17-after는 승인된 Windows 자동화 입력 10건과 종료 코드 0을 기록했다. 독립 검토에서 원시·의미 판정을 재생성해 보존 판정과 일치함을 확인했고, 매니페스트·승인·검토 영수증 및 17-before와 구별되는 nonce를 대조했다. 두 재시도의 전체 `comparison_core`는 동일하다. 틱 11350, 1134950ms, 지문 `c0e18c8c758f6767e67761630cc68cd2a5aeb2e9a5e87d0bf5cd14da5d880acb`에서 같은 결산을 확인했다. 판정 범위는 17행 전후 한 쌍이다. 18행 두 케이스와 독립 검토를 마친 세 매니페스트 집계기의 전체 네 케이스 집계가 남아 있다. [집계기](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/runner-support-three-root-4dac0b8d/README.md)

| 17-after 재시도 근거 | SHA-256 |
| --- | --- |
| [원시 판정](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-after-retry-20261113/formal-run-17-after-retry/17-after/raw-verification.json) | `d739446b574ad1dbd87940b97a3b392ff1484625cd0cc83a932e250f85774d00` |
| [의미 판정](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-after-retry-20261113/formal-run-17-after-retry/17-after/semantic-verification.json) | `d1572487c85c6f4a4fe8bb990ec486cc7627bfd140d114238f17a02a564c47c0` |
| [원시 출력](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-after-retry-20261113/formal-run-17-after-retry/17-after/stdout.raw) | `643afbdead099c1520ec978855baa5b7986db8e44b38e77b22ab640686507cdf` |

### K6 17·18행 교차 경로 집계

Windows 1600×900, 후보 `4dac0b8d`에서 17-before와 17-after는 각 재시도 매니페스트, 18-before와 18-after는 원래 매니페스트의 완료 케이스를 사용했다. 두 원래 17행 실패는 근거와 nonce를 보존하고 집계에서 제외했다. 17행은 각 입력 10건과 결산 핵심값, 18행은 각 입력 14건과 중단 두 번·결산 없음의 전후 판정이 일치했다. 앞선 15·16행 전후 네 케이스의 기준은 별도 후보 `b9c322a0`이다.

검토된 세 매니페스트 집계기로 레인·도구 해시, 증거 파일, 승인 및 nonce 원장을 대조하고 네 원시·의미 판정을 재생성했다. 한글 의미 판정을 읽기 위해 `PYTHONUTF8=1`로 실행했다. 결과는 종료 코드 0, `17:true`, `18:true`다. 독립 최종 검토에서 동일 인덱스와 집계 출력 해시, 두 원래 실패의 제외 및 재실행 종료 코드 0을 확인해 이 동결 범위의 17·18행을 PASS로 판정했다. 보존 출력의 머신 필드(aggregate_credit=false, independent_postrun_review=pending)는 생성 시점 그대로 보존했다.

| 집계 근거 | SHA-256 |
| --- | --- |
| [고정 인덱스](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-18-three-root-evidence-20261113/INDEX.json) | `8a0ae23585878f09e95e33b6b832dfd1b24c0b8b9caaa4a6e2ddc69181d775cc` |
| [UTF-8 집계 출력](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/K6/main-4dac0b8d-row17-18-three-root-evidence-20261113/aggregate-utf8.json) | `f36709cb6f7c25ce0d2f0cf07e2a896f79f74fcac9ae6ca1cfa1e30555dd04b5` |

### P09 설정·지도 전경 루프백

동일한 `4dac0b8d` Windows EXE를 별도의 새 설정·지도 프로필에서 실행했다. CLI로 1600×900을 요청했다. 기존 마스터 음량은 약 78%였고, 시험 프로필에서 UI·음악을 약 78%로 조정했다. 설정에서 복귀 후 닫았고, 지도에서 복귀·재진입 후 닫았다. 두 프로세스 모두 종료 코드 0이며 캡처 도구의 표준 오류는 비어 있었다. 독립 클라이언트 크기 실측과 물리 청취는 남아 있다.

| 프로세스 루프백 구간 | 캡처 길이 | 최대 절대 PCM | 마지막 절대 PCM ≥ 20 | 꼬리 최대 절대 PCM |
| --- | ---: | ---: | ---: | ---: |
| 설정 탭 | 9.97초 | 1 | — | 1 이하 |
| 설정 복귀 | 9.98초 | 12380 | 3.404014초 | 16(3.5초 이후 1 이하) |
| 설정 닫기 | 9.83초 | 1 | — | 1 이하 |
| 지도 복귀 | 9.90초 | 14579 | 3.860612초 | 13 |
| 지도 닫기 | 9.87초 | 14223 | 3.758050초 | 17 |

표의 시간 원점은 각 캡처 시작이다. 설정 닫기 구간에서는 활성 신호가 관측되지 않았다. 지도 복귀·닫기 구간에서는 활성 신호와 이후 낮은 꼬리를 관측했다. 구간별 파형은 트랙을 구분하지 않으며, 동작 기준의 종료 지연과 P09 전체 인수는 남아 있다.

| 루프백 파일 | SHA-256 |
| --- | --- |
| [설정 탭](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-01/audio-settings-tab-01.wav) | `2e1b7e01b97454350850fb503e160e8484f7d07ea6dd6e7dbdce0b9acc9c3537` |
| [설정 복귀](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-01/audio-settings-return-01.wav) | `5305cfa5d086d49d6f78aa90720ee7dc2a6325b3e5f72faebb7bb9c404e4a221` |
| [설정 닫기](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-01/audio-settings-close-01.wav) | `52eba4bbcfb05e2ec4f19eef9257394ea168711d855ab7d8f98a6c7656274ab8` |
| [지도 복귀](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-map-close-01/audio-map-return-01.wav) | `b44d5e1bea7654fef0855273f8de85125b300af26b0bfdda9857094d8fa79401` |
| [지도 닫기](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-map-close-01/audio-map-close-01.wav) | `7c08fee3f4ac4eb1fc91c3d4cc895e2368382d873cbac546d52c0d54298952d4` |

[설정 종료 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-01/game-exit.json) · [지도 종료 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-map-close-01/game-exit.json)

#### 활성 신호가 있는 설정 닫기 재시험

`4dac0b8d`의 별도 프로필에서 PID 28736, HWND 7471250의 클라이언트를 1600×900, DPI 96으로 확인했다. 설정 오버레이에서 마스터·UI·음악을 0.8, SFX를 0으로 저장한 뒤 다시 열었다. 같은 오버레이에서 기준 파형을 확보한 후 창의 X로 닫았다. 프로세스 종료 코드 0을 확인했다. [클라이언트 실측](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-02/client-rect.json) · [종료 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-02/game-exit.json)

| 캡처 | 길이 | 최대 절대 PCM | 관측 |
| --- | ---: | ---: | --- |
| 설정 활성 기준 | 9.92초 | 5015 | 1–7초 RMS 635 |
| 설정 활성 상태에서 닫기 | 9.81초 | 5567 | 마지막 절대 PCM ≥20은 4.072857초, 이후 꼬리 최대 18, 뒤 구간 RMS 0.479·최대 1 |

시간 원점은 WAV 표본 시작이다. 캡처 준비에서 프로세스 종료까지의 QPC 간격은 4.81899초였다. 두 시계의 표본 정렬이 없어 닫기 입력부터 무음까지의 지연은 미산정이다. 독립 검토는 설정 닫기의 활성 기준 신호, 닫기 구간의 낮은 꼬리 및 정상 종료를 확인했다. 물리 출력 장치 청취, 트랙과 UI 효과별 식별, 전체 TRACE 및 P09 전체 인수는 남아 있다.

| 루프백 파일 | SHA-256 |
| --- | --- |
| [활성 기준](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-02/audio-settings-active-baseline-01.wav) | `13deb8e1bc0be2ff0670bf547fc0fb9353c90a5c39e1ca156da5c001eb07c4cc` |
| [활성 상태에서 닫기](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-settings-close-02/audio-settings-active-close-01.wav) | `47d5dbae3204cf06c632e51799de9c188e7da6eca95dc04b9bd93c69746a49da` |

### P09 제한 검증 호스트 TRACE 재실행

격리 작업본 `4dac0b8d`에서 Godot 4.7.2와 같은 작전 어댑터·TRACE 기록기를 사용했다. 앞서 Windows 전경에서 실행한 제한 검증 호스트의 정면 경로에 기록된 명령 세 건을 틱 44·400·954에 재실행했다. 원본과 재실행에서 기록된 644행 전체를 비교했다. 시각 필드 `wall_time`, `mono_ms`와 실행별 `id`·`operation_id`의 작전 식별자 부분을 정규화한 뒤 644/644가 일치했다. 시각 필드만 제외하면 작전 식별자를 포함한 여섯 행의 차이가 남았다.

스냅샷 555개, 사건 79개, 명령 요청·처리 세 쌍이 일치했다. 틱 5541·554100ms의 `objective_success`와 결산 뒤 세션 닫기도 일치했다. 검증 범위는 기존 Windows 전경 제한 호스트 TRACE와 같은 소스의 헤드리스 재실행이다. 독립 검토는 이 기록 행 비교를 통과로 판정했다. 실시간 시계와 미기록 틱은 비교 범위 밖이다. 공개 리플레이 선택기를 통한 재생, 일반 전투, 실제 출력 장치와 트랙별 오디오 및 P09 전체 인수는 남아 있다.

| TRACE 근거 | SHA-256 |
| --- | --- |
| Windows 전경 원본(위 전경 TRACE 링크) | `b73d3bb853992d0b06270e59aa776b244612c545ccd25dbaa183acdeb0d31d46` |
| [헤드리스 재실행](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-foreground-trace-replay-03/profile/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/first_operation_traces/operation-2026-11-13T21-32-59-3372-1030530.jsonl) | `9ea076774f58b3ddc08b9557a84b2d853b7c3fd71eb28f49a7555b58f27d5af1` |
| [정규화 비교 결과](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-foreground-trace-replay-03/RESULT-NORMALIZED.json) | `6d956b2274f1764d39af5b32988aa50e5b72fd1e074487c74e697cfcef1e3225` |
| [재현 설명](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-foreground-trace-replay-03/RESULTS.md) | `752359effe006cb87a67a066fa3da4c803886811c649ff944f59a2dc7f4b615d` |
| [재실행 스크립트](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-foreground-trace-replay-03/replay.gd) | `71bbf024ef7db48e037e4ccaf625f0e98626d2e5cc95a7e11d30a402e6910366` |
| [정규화 스크립트](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-foreground-trace-replay-03/compare-normalized.py) | `cb708fc0be442924058ba9b45d6ba44c40acdd7c006375992c0ec7189ef4107c` |
