# P08·P09 Windows 1600×900 전경 실행 카드

[단일 체크리스트 21행](../../../../SESSION-REQUIREMENTS-CHECKLIST-20261031.md)의 P08·P09 대표 플레이·성능·오디오 종료·전체 TRACE 실행 준비. 후보는 `681ecda17567979edfe693a7c9230ed6786f8c4f`. 실행 전 승인된 Windows 전경 입력 시간과 입력 담당자를 확인하고, 해당 창의 정상 조작과 계측 권한을 확보한다. 이 카드 작성 시의 증거는 패키지·헤드리스 기동, PresentMon 오프라인 재생, 합성 오디오 캡처까지다. [기존 전경 절차](../P08-P09-windows-foreground-preflight-7f138c2d-01/README.md) · [후보 검증](../P08-windows-trace-681ecda1-01/RESULTS.md)

## 실행 단위

- 네 파일은 실행 직전에 실제 사용할 경로에서 SHA-256을 대조한다. EXE와 DLL을 같은 폴더에 두고, 새 F: 검증 경로의 실행별 `profile/roaming`과 `profile/local`을 비운 상태에서 제품 자식 환경의 `APPDATA`와 `LOCALAPPDATA`로 지정한다. 실행마다 별도 프로필을 사용한다.
- 제품 인수는 `--resolution 1600x900 --log-file <run>/engine.log -- --first-operation-trace`. 실제 전경 창의 클라이언트 크기를 확인한다. `run.json`에 파일 경로·해시, 명령행, PID·생성 UTC·창, 디스플레이 배율·주사율, GPU·드라이버, 출력 장치·볼륨, 호스트 시각대를 남긴다. `timeline.jsonl`에 실제 클릭·관측·수집의 UTC와 QPC 기준점(같은 시점의 UTC·QPC 값과 주파수)을 기록한다.

| 파일 | SHA-256 |
| --- | --- |
| SpaceBattleOfThreeKingdoms.exe (원본 실행 폴더 자료) | `57a664fc5a82801e14d3492f95b981b642fe868af4232c145b4ba3ee2eaddf09` |
| o07_win32.dll (원본 실행 폴더 자료) | `a9e45eed91cbe8721469359160bbcb3716675a575537acf716a2da782a75b6e8` |
| PresentMon-2.6.0-x64.exe (원본 실행 폴더 자료) | `b2a706bc6ad475749e3b7e3409263aa1e6906d45bdcf993f6dbc0f660188f1af` |
| ApplicationLoopback.exe (원본 실행 폴더 자료) | `8234b65763c85047b49164070fed5f9e78a1b0c641deaba58d3ddfab12384b40` |

## 대표 플레이와 수집

1. **대표 플레이**에서 게임 PID를 확인하고 출격 전에 PresentMon을 연결한다. 새 프로필의 공개 동선은 **적벽대전 시작 → 서사 건너뛰기 → 적벽 → 출격 · 실제 전장 준비 → Start operation**이다. 각 단계에서 실제 화면·버튼 문구·작전 상태를 기록한다. 이전 배포본에서 사용한 **Move to waypoint 2**로 A 접근, A 활성화 뒤 **Move to waypoint 3**으로 C 접근은 참고 입력이다. 현재 전장의 버튼과 A 상태를 확인한 뒤 적용한다. C 아군 소유, `objective_success` / `objective_conditions_met` 자연 종료와 **Return to map** 결산을 화면·시각·TRACE로 대조한다. 초기 전장·교전·지도 결산의 시작과 끝을 `timeline.jsonl`에 기록한다. [이전 배포본의 실제 플레이 기록](../I01/r5-dimensions-canonical-windows-ui-prep-01a1c838/run-67f9cb20-20261111-01/RESULTS.md)
2. **성능**은 PresentMon을 `--process_id <gamePID> --session_name <uniqueRunId> --terminate_on_proc_exit --no_console_stats --v2_metrics --qpc_time --no_track_input --output_file <run>/presentmon.csv`로 시작한다. PID 필터는 CSV에 적용되며 라이브 ETW가 시스템 이벤트를 읽을 수 있다. 결산 관찰 뒤 제품 창을 정상 종료하고 PresentMon 종료·CSV 기록 완료를 확인한다. 조기 정리가 필요하면 이 실행이 만든 고유 세션만 `--session_name <uniqueRunId> --terminate_existing_session`으로 정리하고 수집 중단으로 기록한다. `presentmon.log`에 출력·종료 코드를 남긴다. 원본 CSV에서 PID·게임 swapchain·구간·실제 헤더를 확인하고 `FrameTime`, `DisplayedTime` 및 표시되지 않은 프레임을 해당 v2 열로 보고한다. 지원되지 않거나 빠진 값은 미확인으로 남긴다. [CLI 및 라이브 전제](../P08-presentmon-preflight-7f138c2d-01/README.md) · [오프라인 PID·CSV 재생 검증](../P08-presentmon-offline-e13fce6a-case2-01/README.md)
3. **오디오**는 기존 카드의 설정 클릭·타이틀 복귀, 지도 전환·타이틀 복귀, 설정·지도에서 각각 음악 재생 중 정상 창 닫기 구간을 수집한다. 현재 후보에서 관측한 설정·지도 화면 문구, 이동 버튼과 재생 상태를 기록한다. 대표 플레이 중 음악 교체와 지도 복귀도 구간을 표시한다. 전환/종료마다 `ApplicationLoopback.exe <gamePID> includetree <run>/audio-<event>-<take>.wav`를 고유 경로로 실행한다. 수집 시작 메시지와 동작 전후가 같은 약 10초 창에 들어오도록 기록하고 제품 창이 닫혀도 루프백의 자체 종료와 WAV 마감을 기다린다. `audio-<event>-<take>.log`의 시작·완료·오류와 WAV의 PCM 헤더·데이터 길이·전후 구간을 대조한다. 각 창 닫기의 제품 종료 코드·대상 PID/하위 프로세스·엔진 종료 진단도 보존한다. 프로세스 트리의 렌더링 출력이 관측 범위다. 물리 출력이나 특정 엔드포인트에서 실제로 들렸는지, 다음 화면의 새 음악과 이전 음악의 잔류, 내부 참조 해제는 해당 판정을 뒷받침하는 독립 증거가 부족하면 미확인으로 기록한다. [루프백 명령·제약](../P09-application-loopback-434f6002-01/RESULTS.md) · [합성 신호 독립 검증](../P09-synthetic-loopback-native-20261113-8b451a/offline-verification.json)

## TRACE와 증거 제출

- `engine.log`의 `[FIRST OPERATION TRACE]` 출력에서 경로를 확인한다. 격리된 `profile/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/first_operation_traces/operation-*.jsonl` 원본을 보존한다. 공개 출격은 v1 `session_start`(`restored=false`), 초기 `snapshot`, `operation_started`, 두 이동의 `command_request`·`command_queued`, 작전 이벤트·주기적 스냅샷, 결산을 포함한 `operation_end`, 마지막 `session_closed`(`settled`)를 기대한다. 각 행의 JSON 파싱, 1부터 연속인 `seq`, 비감소 `tick`·`sim_ms`, 화면·결산과의 일치를 확인한다. 파일명 시각·`wall_time`은 호스트 현지 시각으로 해석한다. 생성·기록 경고, 중도 종료, 누락은 결과에 명시한다. 후보 TRACE 형식 (원본 실행 폴더 자료)
- 실행별 `run.json`, `timeline.jsonl`, `engine.log`, `presentmon.csv`·`presentmon.log`, 오디오 WAV·로그, `operation-*.jsonl`, 화면 증거 `screens/<UTC>-<event>.*`를 모은다. `sha256.txt`로 원본을 고정하고 `RESULTS.md`에 구간별 관측, 누락과 원인, 정상 종료 및 입력 반환을 적는다. 성능 수치는 관측값으로 보고한다.

