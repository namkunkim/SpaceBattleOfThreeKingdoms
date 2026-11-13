# Windows 1600×900 인수 준비

기준은 `main`의 `1d13fdad1eef20cb44ce8736919bd4359074a064`이다. 2026-11-13에 원격 `main`과 일치함을 확인했다. 기존 실행 카드의 빌드 `681ecda1` 이후 EntryBoot·CommandDeck(`d44e9708`)과 O07 저장 복원(`dcc26f88`)이 바뀌었다. 해당 EXE의 헤드리스 기동 9/9 및 수집 도구의 오프라인 검증은 이전 후보 증거로 보존한다. [이전 실행 카드](../battle-core/pc-campaign-design/evidence/20261113/validation/P08-P09-windows-foreground-681ecda1-01/EXECUTION-CARD.md)

## Windows 빌드와 계측 준비

1. Windows 빌드 담당자는 위 커밋의 깨끗한 격리 작업본에서 공식 지문 빌더와 테스트 훅 없는 Win32 x64 DLL 빌드를 실행한다. 이 호스트에서 Godot 4.7.2 콘솔 실행 파일, Windows x64 디버그·릴리스 템플릿, `vswhere.exe`가 존재함을 확인했다. 실제 MSVC x64 컴파일·패키징 및 시작 검증은 새 빌드에서 확인한다. 커밋, EXE·DLL의 SHA-256, O07·리플레이 지문 및 내보내기 로그를 같은 후보 기록에 묶는다. [빌드 절차](o07-windows-release-and-operations-ko.md#windows-패키지-빌드)
2. 계측 담당자는 보존 폴더 `F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation` 아래 두 도구의 SHA-256을 실제 실행 경로에서 대조한다. 아래 값은 2026-11-13 보존 사본에서 재확인했다.
3. 전경 입력 담당자와 시간 창이 정해지면 새 후보의 EXE·DLL로 실행 카드의 대표 플레이를 진행한다. 실행별 격리 프로필에서 실제 1600×900 클라이언트 크기와 PID를 기록한다. 현재 화면의 버튼·작전 상태를 확인하며 목표 달성과 지도 복귀까지 진행한다. 같은 PID의 PresentMon CSV와 전체 TRACE를 초기 전장·교전·결산 타임라인에 맞춰 검토한다. 실제 디스플레이 배율·주사율과 GPU·드라이버를 기록한다. [수집 절차](../battle-core/pc-campaign-design/evidence/20261113/validation/P08-P09-windows-foreground-681ecda1-01/EXECUTION-CARD.md#대표-플레이와-수집)
4. 오디오 담당자는 실제 출력 장치·볼륨을 기록하고 설정·지도에서 효과음과 배경음악의 전환·정상 종료를 관찰한다. 프로세스 트리 루프백 WAV, 장치 관찰, 제품 종료 코드·엔진 진단을 실행별로 보존한다. 합성 루프백으로 검증한 범위는 수집 도구의 PCM 출력이다. 현재 제품의 실장치 청취와 전체 종료 판정에는 이번 전경 증거가 필요하다. [합성 루프백 증거](../battle-core/pc-campaign-design/evidence/20261113/validation/P09-synthetic-loopback-native-20261113-8b451a/offline-verification.json)

| 도구 경로 | SHA-256 |
| --- | --- |
| `P08-presentmon-preflight-7f138c2d-01/PresentMon-2.6.0-x64.exe` | `b2a706bc6ad475749e3b7e3409263aa1e6906d45bdcf993f6dbc0f660188f1af` |
| `P09-application-loopback-434f6002-01/build/bin/ApplicationLoopback.exe` | `8234b65763c85047b49164070fed5f9e78a1b0c641deaba58d3ddfab12384b40` |

## O07 재개 조건

- **운영 전환** — 운영 담당자가 승인된 최종 EXE·DLL, 대상 볼륨·파일 시스템, 주 슬롯 경로와 지문·작전 ID·세대·순번·영수증, 보존본 SHA, 단일 작성자 전환 창을 확정하면 재개한다. 기존 격리 리허설은 Win32 잠금·게시·첫 쓰기 전 복원·쓰기 후 롤백 거절을 검증했다. [운영 절차](o07-windows-release-and-operations-ko.md#실제-운영-슬롯-전환)
- **외부 지급** — 제품 호출은 `external_payment_contract_missing`을 반환한다. 운영 담당자가 승인된 비운영 수신자·연동 설정과 결산 ID 기준 영속적 중복 제거·다른 효과 충돌 계약을 확정하면 응답 유실 뒤 재시도와 수신자 원장 단일 기록을 검증한다. [지급 절차](o07-windows-release-and-operations-ko.md#외부-지급)
- **물리 전원 차단** — 검증 담당자는 승인된 시험 장비, 운영 대상과 동일한 파일 시스템·스토리지 조건, 시험 전용 슬롯, 전원 복구 절차를 확보한다. 현재 조회에서 E와 F는 exFAT이며 F는 `Warning`으로 보고됐다. 기존 프로세스 종료와 Win32 공유 거절에서 확인한 복구는 해당 실행의 증거다. 승인된 장비에서는 후보 지문·시드 세대·주/이전 슬롯 SHA를 기록하고, 차단 후 첫 쓰기 전 읽기 결과와 복구 뒤 결산 ID·세대를 대조한다. [프로세스 중단 결과](../battle-core/pc-campaign-design/evidence/20261113/validation/O07/p03-store-child-cutpoint-b2ba73ff-02/RESULTS.md)
