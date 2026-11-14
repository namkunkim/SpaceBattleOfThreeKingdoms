# Windows 공개 적벽 v1 실전 PresentMon 계측

2026-11-14 KST · Windows 릴리스 후보 `69fc5df4bcc434ba0c6b3e661fd0c96cc7128ad7`

공식 지문이 고정된 릴리스 후보를 새 APPDATA·LOCALAPPDATA 프로필에서 실행했다. PID 3640, 실제 클라이언트 영역 1600×900, DPI 96, Windows 세션 2, 창 모드였다. Intel Arc 130V, 드라이버 32.0.101.8626, 기록된 디스플레이 1920×1080·60Hz 및 Godot OpenGL Compatibility를 사용했다. 같은 세션의 관리자 PowerShell에서 PresentMon 2.6.0을 연결했다. 네 QPC 마커와 최종 CSV의 동일 세션·PID를 확인했다. 게임과 캡처의 종료 코드는 모두 0이었다.

타이틀에서 전술 준비를 거쳐 일반 적벽 전투의 함대 편성 브리핑으로 진입했다. 기본 자동 편성은 아군 411척이었다. 실전 시계가 진행하고 1×가 선택된 것을 확인한 뒤, 카메라를 고정하고 전투 명령 없이 계측했다. 전투 TRACE에는 시작 시 1배속, 전경과 전투 상태가 기록됐다.

| 구간 | 길이 | 표본 | FrameTime 중앙값 / p95 / p99 (ms) | DisplayedTime 중앙값 / p95 / p99 (ms) | 미표시 | 미확인 |
| --- | ---: | ---: | --- | --- | ---: | ---: |
| 브리핑 | 6.759초 | 405 | 16.6744 / 17.2583 / 17.7267 | 16.6660 / 16.7295 / 16.7445 | 0 | 0 |
| 실전 1× | 39.262초 | 2,362 | 16.6652 / 17.4889 / 18.2603 | 16.6670 / 16.7367 / 16.7924 | 6 (0.254%) | 0 |

`CPUStartQPC`의 각 시작 포함·끝 제외 구간에서 일치 PID 행을 집계했다. 백분위는 nearest-rank를 사용했다. 미표시는 `DisplayedTime=NA`이며 숫자 분포에서는 제외했다. 해당 PID 전체 5,686행에서 `PresentRuntime=Other`, `SwapChainAddress=0x0`, `Composed: Copy with GPU GDI` 조합 하나가 보고됐다. OpenGL에서 주소 0은 도구가 보고하는 값이다. 이 수치는 동일 PID와 구간으로 귀속된 표시 관측이며 개별 스왑체인 주소를 확인할 수 없다. [PresentMon OpenGL 설명](https://github.com/GameTechDev/PresentMon/blob/v1.10.0/README.md#analyzing-opengl-and-vulkan-applications) · [2.6.0 CSV 지표](https://github.com/GameTechDev/PresentMon/blob/v2.6.0/README-ConsoleApplication.md)

첫 연결의 활성 CSV 읽기 잠금과 두 번째 연결의 게임 종료 뒤 자동 정지 시간 초과 기록을 보존했다. 최종 실행기는 활성 CSV를 읽지 않고 `live-end` 뒤 지정 ETW 세션을 정리한 다음 CSV를 확정했다. 성공 실행기 SHA-256은 `51fab1123565f307982895aa7f8657250ddc43ef50154326b4738c5b716e3d04`이다.

[원시 실행 폴더](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-red-cliffs-v1-presentmon-1794642120) · [집계 결과](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-red-cliffs-v1-presentmon-1794642120/analysis.json) · [원시 CSV](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-red-cliffs-v1-presentmon-1794642120/presentmon.csv) · [출시 후보 해시](P08-RED-CLIFFS-V1-RELEASE-PERFORMANCE-20261114.md)

원시 CSV SHA-256은 `b91d2f24877e6356cdf5982f81d3a2996169d45cf64c13ff37cb6e76124954ec`이다.
