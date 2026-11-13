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

#### P09 루프백 배경음악 음원 대조

`4dac0b8d`의 설정 활성 기준·설정 닫기·월드맵 닫기 루프백 WAV에서 각각 `stars_stripes.ogg`와 일치하는 신호를 확인했다. FFmpeg로 1kHz 모노 PCM으로 변환한 뒤 1.5초 구간 7개를 대조했다. 파형 상관계수는 0.83035–0.96280이었고, 같은 캡처 안의 트랙 오프셋은 1ms 해상도에서 일관됐다. 후보 구간을 선별한 같은 검색에서 `mountain_king.ogg`는 최대 0.08984, 순서를 섞은 구간은 최대 0.31952였다. 이전의 조용한 설정 닫기 WAV는 변환 후 RMS 0이었다. 물리 장치 청취, UI 효과음 식별과 종료 인수는 남아 있다.

- [대조 스크립트](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-offline-source-fingerprint-01/match.py) SHA-256 `14dab5b3a02cddd4f067474740bd087358b6d5113fa7b3fa0df6af14697db891`
- [대조 결과와 입력 해시](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-offline-source-fingerprint-01/RESULT.json) SHA-256 `19ea22c9674284f1f52b6599e8a30efeefe396ba72f3078e8ed93d394b41d6a4`

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

### 공개 파일 선택기에서 리플레이 재생

Windows 후보 `4dac0b8d`에서 공개 리플레이 선택기로 고정 파일을 열었다. 시험 파일은 제한 호스트 기록을 바탕으로 같은 소스의 도구가 공개 capability 형식과 제품 코덱으로 생성했다. 전경에서 검증한 경로는 파일 선택과 재생이었다. [시험 파일 근거](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-foreground-trace-replay-fixture-01/RESULTS.md)

격리 프로필에서 실행 중 읽기 전용 측정으로 1600×900, DPI 96, PID 16556, HWND 9962202를 확인했다. 0틱 준비 화면에서 Play를 눌렀고 중간 1037·1778·2878·3578·4467틱을 관찰했다. 끝까지 재생해 5541틱·554.1초에 `site_captured`와 `operation_settled`, `objective_success`·`objective_conditions_met`을 확인했다. 결산 ID는 `red-cliffs-first-operation-dev-v1/0a34ee3ab95f69b13f7df455a69da57c/settlement`였다. 리플레이 닫기 후 WorldMap이 복원됐고 창의 X로 정상 종료했다. 종료 코드는 0이었다. 독립 확인에서 재생 중간과 종료 후 격리 프로필의 셰이더 캐시 경로 5개가 같았고, 보호 대상 저장·결산·보조 파일은 없었다. 시험 파일 해시도 동일했다. 물리 오디오, 트랙·UI 효과 식별과 전체 P09 인수는 남아 있다.

| 재생 근거 | SHA-256 |
| --- | --- |
| [고정 리플레이](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-foreground-trace-replay-fixture-01/red-cliffs-front-5541.pcopreplay) | `035dc2400bd0da3d9348254cf64e7aa5bfd7a9a2223f1b45b18e3e109fc447a5` |
| [실행 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-replay-playback-01/game-start.json) | `3435c10b2e4d179a5ac87fe21b762c11321903a85c8e040fa9b186bef8dd4cf3` |
| [종료 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-replay-playback-01/game-exit.json) | `c396954e9d9375828c2396e25eb3f9e301e0a0abe14ec0c9ef0b65921eb620af` |
| [엔진 로그](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-audio-4dac0b8d-replay-playback-01/engine.log) | `3ed90fd67a8b29656f4cc9903140aeae10ec6cfacf5b7e8ecf3afa3d21b4aeaf` |

### P08 일반 전투 디버그 FPS 관측

`bf4c134d` Windows 디버그 EXE를 격리 프로필에서 실행했다. 별도 검증 모드 없이 일반 UI에서 자동 편성을 선택해 1배속으로 전투 시계 00:29까지 진행한 뒤 창의 X로 닫았다. PID 18916, HWND 7933468의 실제 클라이언트는 1600×900, DPI 96이었다. 종료 뒤 PID가 사라졌고 종료 코드 파일은 확보하지 못했다. [실행 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-fps-01/game-start.json) · [클라이언트 실측](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-fps-01/client-rect.json)

| 엔진 디버그 구간 | 표본 수 | 최소 / 중앙값 / 최대 FPS |
| --- | ---: | ---: |
| 브리핑 | 13 | 59 / 60 / 60 |
| 전투 1배속 | 14 | 43 / 60 / 60 |

독립 검토에서 엔진의 디버그 FPS 집계와 창 실측을 확인했다. 전투 TRACE는 40행이며 마지막 스냅샷은 틱 290이었다. 이 실행은 수동 종료까지의 보조 관측이다. 전체 전투 결산, PresentMon/ETW 프레임 시간 측정 및 P08·P09 전체 인수는 남아 있다.

| 근거 | SHA-256 |
| --- | --- |
| [엔진 FPS 로그](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-fps-01/engine.log) | `0d02cc282af72243d60c2027d7bff254fcb81620bbeae621dc5cc575c82eabd1` |
| [전투 TRACE](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-fps-01/profile/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces/battle-2026-11-13T21-55-14-18916-60174951.jsonl) | `3f5da6fe40ee9b9ed3775bde2c212916178410994bcc4ed50262a7ea9ee63c14` |
| [전투 준비 TRACE](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-fps-01/profile/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces/battle-2026-11-13T21-54-45-18916-31615512.jsonl) | `a6d7ea7965c0aa98bfe88fae1892fbc7990c60330b960efb29bdc02e478d8a26` |
| [클라이언트 실측](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-fps-01/client-rect.json) | `1bb95df25f01daf4fc9570ed690712669bc40a2e7c75151f357682c7b95508ce` |

### P09 일반 전투 종료 TRACE

별도 격리 프로필의 `bf4c134d` Windows 디버그 EXE에서 일반 전투를 4배속으로 진행했다. PID 28392, HWND 1180336의 실제 클라이언트는 1600×900, DPI 96이었다. TRACE에 전술 명령 기록은 없었다. 앞선 1배속 디버그 FPS 관측과는 별도 실행이다.

종료 TRACE 순번 1–236이 연속이며 스냅샷 203개를 포함한다. 틱 2020·201950ms의 `battle_end`에서 `alliance_morale_collapse`·패배를 기록했고, 마지막 UI 상태는 `end`였다. 독립 검토에서 TRACE와 종료 기록을 확인했다. 전경에서 패배 화면 03:21과 손실 64/116, 생존 전대 4/6을 관찰했다. 이후 창의 X로 닫아 종료 코드 0을 확인했다. 전체 P09 인수, 물리 오디오 및 릴리스 프레임 시간 검증은 남아 있다.

| 근거 | SHA-256 |
| --- | --- |
| [종료 TRACE](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-terminal-01/profile/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces/battle-2026-11-13T22-03-03-28392-35168162.jsonl) | `d5b653056eeecedcc61362171655e26eb95e0db14a567b757935e71396bdf899` |
| [준비 TRACE](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-terminal-01/profile/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces/battle-2026-11-13T22-02-56-28392-28223433.jsonl) | `82714057df8b869ca84079f4d745954857c80577518b8c685b4ebaf54626bbbd` |
| [엔진 로그](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-terminal-01/engine.log) | `3854d6053abac47a532fee6b7c7e0d6ac3134e8687fb20399e140d3c773869d2` |
| [클라이언트 실측](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-terminal-01/client-rect.json) | `0f9e9c9428fc142b440cd30aa2250e338e6552d4f1a641e46d063fbbd1074fc9` |
| [종료 기록](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-windows-debug-bf4c134d-ordinary-terminal-01/game-exit.json) | `4d4084f6737b8d5bef01e9bb3dc981ad5f57466b1d9ab0587b989e7ea4f473b1` |

#### P09 월드맵 복귀 효과음 대조

Windows에서 1600×900을 요청한 `4dac0b8d` 월드맵의 타이틀 복귀 루프백에서 `button.wav` 파형을 확인했다. 600Hz 고역 통과 필터와 4kHz 모노 변환을 거친 60ms 원본을 3.1–4.1초 구간에 대조했다. 정규화 상관계수는 WAV 시작 기준 3.809초에서 0.95583이었다. 다른 보존 구간에서 같은 음원의 최고값은 0.21266이었으며, 배경음악 기준 구간은 0.19498, 조용한 설정 탭은 0이었다. 배경음악 기준 구간에 원본을 35% 진폭으로 삽입한 양성 대조군은 알려진 위치에서 0.99000이었다. 소스의 월드맵 `타이틀로` 버튼은 `button` 효과음을 호출한다. WAV 오프셋과 클릭 시각의 정밀 정렬, 물리 장치 청취와 내부 재생 객체의 해제는 미확인이다. 독립 검토에서 이 대조 결과를 확인했다. 설정 복귀·탭 캡처에서는 특정 효과음을 식별하지 못했다.

- [효과음 대조 스크립트](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-offline-ui-oneshot-01/scan.py) SHA-256 `8f548d378de1602e29019407d07914b954238bc5607699f9eb0066be4f6f1716`
- [입력 해시·대조 결과](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-4dac0b8d-offline-ui-oneshot-01/RESULT.json) SHA-256 `c3b31d1d533d8c797bee4a133c646b52ce9b5c34fc565c3dc7dad546fc0b6180`
