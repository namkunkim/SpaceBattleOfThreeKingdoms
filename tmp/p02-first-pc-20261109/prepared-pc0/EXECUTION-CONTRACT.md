# PC0 격리 준비물과 운용 계약

**검토 전용. 실제 Godot·Windows 창·입력은 실행하지 않았다.** 독립 검토가 `REVIEW-MANIFEST.json`의 SHA를 수용한 뒤에만 실행한다. 이 실행은 HEAD 0be09755b의 legacy 지도 직접 출전이다. 원본에서 현재 P03 +9행과 worker를 해시로 보호한다. 이전 여덟째 후보의 K1~K5, 미실행 K6 1회 및 21행은 별도다. 기존 Python Job 콘솔호스트 K3도 소진 이력 그대로 유지한다.

## 실행 명령과 격리

작업 위치 `C:/WorkSpace/SpaceBattleOfThreeKingdoms`. PowerShell 7의 독립 supervisor를 `pwsh -NoProfile -File tmp/p02-first-pc-20261109/prepared-pc0/supervisor.ps1 -AcceptedManifestSha <독립 수용한 SHA256>`로 시작한다. 원본과 기존 사용자의 창이 아닌 신규 소유 창만 대상으로 아래 CUA 계약을 적용한다. 실행 결과 5-a는 `python tmp/p02-first-pc-20261109/prepared-pc0/verify.py`다. 이 판정기와 별도로 시각 근거·이벤트 연계를 독립 판정한다.

`run-01/project`를 처음부터 만든다. git object에서 동결된 1,470 파일의 소스·데이터·리소스를 복제하며 기존 작업 트리와 캐시는 복제하지 않는다. generated cache 경로 및 데이터 출처 문구는 manifest에서 실행 시 읽는 source와 구분한다. GameSettings의 save는 `user://settings.cfg`, trace는 `user://battle_traces`를 사용한다. 원본 project.godot에는 custom user dir와 UID main scene 참조가 없다. APPDATA·LOCALAPPDATA·TEMP·TMP를 고유 경로로 넘긴다. `isolation`의 실제 `user://` 경로가 APPDATA 아래인지 확인하고 import 이후 제품 save 디렉터리가 비었음을 확인한다. `import`에서 생성한 캐시 및 변경한 import 메타데이터는 별도 해시화한다. 같은 project 경로를 제품이 사용하며 제품 전후 파일 집합 및 SHA가 일치해야 한다. 원본 APPDATA/LOCALAPPDATA의 프로젝트 app_userdata와 원본 .godot의 내용도 두 시점에서 비교한다.

Windows GUI 일반 exe의 exact argv가 아래 세 lane을 실행한다. console exe SHA도 확인하고 증거에 보존한다. 따옴표는 실제 CreateProcess 인자 구성에 들어간다. cwd는 import·product가 `<run>/project`, isolation은 동일 application 설정에서 main scene을 제거한 `<run>/isolation-project`다. 변수 `<run>`은 절대 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/p02-first-pc-20261109/run-01`이다.

- `C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe --path <run>/isolation-project --log-file <run>/isolation.log --headless --script res://pc0-user.gd`, 최대 30초.
- `C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe --path <run>/project --log-file <run>/import.log --headless --editor --import`, 최대 300초.
- `C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe --path <run>/project --log-file <run>/product.log res://scenes/WorldMap.tscn`, 최대 1,920초.

V3의 console argv에서 일반 exe 직접 시작으로 바뀌었다. Win32는 직접 suspended 실행 → exact HANDLE의 전용 Job 할당 → membership·image·생성 시각 확인 → resume 순서다. V3의 inert broker handshake 대신 suspended process 경계를 사용한다. 기존 Python/console broker를 시작하지 않는다. 호스트 Job 중첩에서 새 Job 할당이 실패하면 resume하지 않고 suspended HANDLE 하나만 정리한다. 제품 루프는 전용 Job에 예상치 않은 process가 확인되면 즉시 실패한다. 소유 Job만 종료하며 이름으로 찾은 프로세스에는 종료 요청을 보내지 않는다. 정상 종료는 소유 GUI 닫기다. 위반·오류·deadline에는 `abort` 또는 감독기의 Job 종료와 Job active 0·process HANDLE signaled를 남긴다. CUA 표면이 닫혀도 감독 프로세스의 자체 deadline이 진행한다. 감독 프로세스가 외부에서 종료되면 상속되지 않은 Job HANDLE의 kill-on-close가 적용되며 그 경우 정상 cleanup 기록은 생기지 않아 실패로 처리한다.

일반 PE GUI exe에 CREATE_NO_WINDOW가 효력을 갖는다고 가정하지 않는다. stdout/stderr 핸들을 상속하거나 캡처하지 않는다. 원문 근거는 각 lane의 엔진 `--log-file`과 battle trace 파일 및 감독기 출력이다. GUI exe의 headless import, probe `--script` 로딩, logfile에 print·엔진 오류가 남는지는 런타임 미확인이다. isolation 로그 marker가 없거나 경로·프로세스 소유가 맞지 않으면 제품 시작 전에 중지한다. capture 표면의 좌표계·DPI·창 ID를 일치시킬 수 없으면 입력 전에 중지한다.

## 실제 입력과 관측 계약

CUA는 Windows 화면을 보는 액션만 사용한다. 화면 캡처나 입력 호출 구현은 CUA 도구의 지침을 따른다. 기록은 `run-01/screens`, `run-01/actions.jsonl`, `run-01/product.os.tsv`, engine 로그를 연결한다. 사진과 액션을 아래 순서대로 저장한다. 각 액션 레코드에는 action/keys/button, pre/post 이미지 경로와 SHA, 요청 전/후 OS monotonic 및 UTC, native HWND 및 동일 PID, client rect/DPI, 화면/viewport 위치, 대응 engine seq 또는 링크 marker, 육안 판정을 기록한다. `product.os.tsv`의 `window` 행은 `boot_ms, utc, window, count, foreground_HWND, owned_HWND, PID, x, y, width, height, dpi`다. 바로 직전 250ms 이내 행의 owner count=1·foreground=owned를 확인하고 대상 client가 사진과 맞을 때만 입력한다. 이동 클릭은 client 안쪽을 사용한다. OS 행은 100ms 표본이며 표본 사이 외부 입력의 완전 배제를 의미하지 않는다. 액션 후의 최초 유효 OS 표본과 trace의 focus를 비교해 이탈이 있으면 실패다. 정상 소유 창 닫기는 HWND 소멸을 예상한다.

엔진 `clock_anchor`의 `utc_s / mono_ms`와 OS `boot_ms / utc`를 가까운 launch 표본에서 연결한다. `publish/consume/display`의 Unix 시각도 비교한다. 시스템 시계 점프나 UI·engine 이벤트가 여러 액션 중 어느 것인지 모호하면 실패다. 원문은 자르거나 이어 붙이지 않는다. `brief.witness`는 브리핑 확인, `resume.witness`는 pause의 계속 버튼 후 실제 tick/clock 증가 확인, `terminal.witness`는 결과 화면과 battle_end 확인, `map.witness`는 지도 결과 표시·지역색 확인 뒤 run-01 아래 신규 파일로 원자적으로 생성한다. 각각 연결한 action/seq/engine time를 본문에 남긴다. 감독기는 각 marker를 순서대로 소비하며 상한 180/180/1,440/120초와 총 1,920초를 적용한다. marker는 관측을 대신하지 않는다. 순서·관측 누락/이탈/장애 시 `abort` 파일을 생성하여 소유 Job만 닫고 OS 로그를 보존한다.

1. WorldMap에서 적벽 카드 → 입문 → 직접 지휘 → 출격. 전환·서막은 실제 표면에서 진행하거나 건너뛴다. 직접 배치 CheckButton과 자동 편성으로 시작한다. 정상 브리핑 전 `brief.witness`를 생성하지 않는다. 초기 실패는 내부 호출로 복구하지 않는다.
2. 배치에서 2.5초 이상 머무르고 두 관측 사이 프레임 및 phase 표본을 남긴다. 두 엔진 표본은 같은 host/sim/epoch이고 tick/clock은 0/0이어야 한다. 배치 확정 뒤 첫 advancing 표본을 본다.
3. 해당 화면에서 유비 기함 ID 1을 왼쪽 클릭해 선택한다. 직전 사진에 유비 ID/유일 선택 및 정지, 가시 적 방향, 빈 목표를 근거화한다. 그 방향으로 viewport 폭 8~12% 떨어진 화면 내 지점을 한 번 오른쪽 클릭한다. UI/다른 함대/field 경계가 겹치면 실패다. 기존 right_press/right_release의 viewport 좌표와 release world를 기록하고, field clamp가 발생하면 실패다. 소유 창의 렌더와 trace가 같은 ID에 대해 명령 전후 이어지는지 확인한다. 동일 ID의 실제 `has_move/move_to`와 양의 투영/최소 순이동을 10 논리초 내 다음 의도적 입력 전에 관측한다.
4. Space 실제 입력으로 pause. 2.5초 이상 유지하고 두 엔진 표본과 사진을 보존한다. 실제 계속 버튼 뒤 첫 증가를 확인한다. 1배속에서 자연 종결을 기다린다. 추천 결정 카드가 열리면 기존 계약상 표시된 추천 선택만 실제 클릭하고 카드의 선택 권한·이유·전후 시각을 기록한다.
5. battle_end 뒤 결과 화면에서 terminal tick/clock 두 표본을 확인한다. 천하로 실제 버튼을 누르고 outcome publish, consume, show_result 입구·동기 표시의 exact payload와 큐 상태를 본다. 0.6초 지역색 지연 및 지도 전환 뒤 사진으로 UI를 검증한다. 소유 HWND를 정상 닫고 cleanup 0을 확인한다.

`oracle.json`은 실제 로그를 읽기 전 source 기반으로 동결했다. 숨겨진 적 위치/생존을 플레이어 가시성 근거로 쓰지 않는다. move 근거는 아군과 화면 렌더다. terminal 이후 공개 결산에는 적 손실 집계가 포함된다. 자연 종결 및 지도 복귀가 성공해도 legacy PC0에만 해당한다. P07 목표·철수·P03 저장·operation 권위 연결과 전체 P02 인수는 별도다.

