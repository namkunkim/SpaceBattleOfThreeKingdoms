# 전투 진단 로그

새 게임 실행부터 전투별 JSONL 파일을 자동으로 저장한다. 이미 실행 중인 게임에는 코드가 반영되지 않으므로 다시 실행해야 한다.

저장 위치: `%APPDATA%/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces/`

Godot 콘솔의 `[TRACE]` 줄에도 전체 경로를 표시한다. 전투 재시작은 새 파일을 만든다. 각 기록을 즉시 flush해 강제 종료 시에도 마지막 명령을 보존한다. 파일은 로컬에만 저장하며 자동 전송·자동 삭제하지 않는다.

기록 내용:

- `session_start`: 시드, 프로필, 난이도, 이동·선회 배율, 초기 아군 상태.
- `right_press` / `right_release`: 마우스 좌표, 선택 ID, 끌기 여부, 월드 좌표.
- `ui_state`: 선택, 게임 진행/일시정지, 창 포커스, 배속 변화.
- `command_request` / `command_applied`: 명령 요청과 코어 처리 직후 아군 상태. `command_applied`는 처리 완료를 뜻하며 성공을 보장하지 않는다. 뒤따르는 `core_event`의 `rejected`를 확인한다.
- `command_blocked`: 초기 배치 단계에서 차단된 명령.
- `fleet_status`: 사기 단계, 퇴각/항복/격침/탈출, 직접 지휘/위임, 지휘관 상태 변화.
- `snapshot`: 게임 시간 약 1초 간격의 아군 위치·목적지·사기·지휘 상태와 양측 군 사기. 표시 프레임마다 파일을 쓰지 않는다.
- `core_event`: 명령 거부의 원래 코드와 당시 상태.
- `battle_end`: 실제 승패 코드와 코어 결산 전체(손실률, 군 사기, 판정 조건 등).

로그는 시뮬레이션 상태를 읽기만 하며 난수·판정·명령 처리 결과를 바꾸지 않는다. 마우스 로그는 UI가 소비하지 않은 전장 우클릭 경로를 기록한다. 적 전대의 상세 상태는 주기적으로 기록하지 않는다. 전투가 길면 파일 크기가 늘 수 있다.

분석:

```powershell
python tools/analyze_battle_trace.py
python tools/analyze_battle_trace.py "C:/path/to/battle-....jsonl"
```

경로를 생략하면 가장 최근 파일을 읽는다. 테스트 파일도 같은 폴더에 생기므로 실제 플레이 파일은 `session_start`와 전투 시간을 함께 확인한다. 거부 코드와 패배 코드가 찍히기 전에는 영상만으로 원인을 확정하지 않는다.
