# P02-7 구현 GUI 재개 기록

사용자 요청 “다시 확인해줘” 후 Windows computer-use를 재개했다. 전용 Godot EXE에서 반환한 창을 제목과 HWND로 고른 뒤 창 스크린샷의 제목과 실패 버튼을 대조했다. OS 입력 탐침은 제품 코드를 호출하지 않고 들어온 키/마우스 이벤트를 관찰했다.

| 사례 | 실행 증거 | 확인 |
| --- | --- | --- |
| 독립 실행 마우스 | gui-after-02-mouse-verified | 기존 실행에서 실제 종료 좌표 클릭, exit 0, timeout=false |
| 독립 실행 키보드 | gui-after-02-resumed-key | 1280×720 및 인셋 50,34,28,22, HWND 3148126, 제품 버튼 포커스, Return 4194309, exit 0 |
| 천하 복귀 마우스 | gui-after-02-resumed-routed-mouse | 1600×900, HWND 855302, 왼쪽 버튼 이벤트, 실제 WorldMap, brief/outcome null, 표준/auto 보존, exit 0 |
| 천하 복귀 키보드 | gui-after-02-resumed-routed-key-v2 | 1280×720 및 인셋 50,34,28,22, HWND 7274976, 제품 버튼 포커스, Return 4194309, 실제 WorldMap과 같은 상태, exit 0 |

위 프로세스에는 최초 실패 안내, sim/presentation 부재, 호스트 process 비활성 및 legacy canvas 숨김이 기록됐다. 세 재개 실행에서 battle trace는 생성되지 않았다. 키보드 두 실행에는 다른 글자 키 이벤트도 있으나 마지막 Return과 결과를 확인했다. 앞선 gui-after-02-resumed-routed-key 실행은 사용자의 입력과 교차해 마우스로 복귀했고 키보드 성공으로 집계하지 않았다. 각 실행의 command.json, rows.jsonl, process.json, stdout, stderr를 보존했다. native renderer 캡처는 gui-after-02-render-routed-v2/initial.png, gui-after-02-render-live-v2/live-warning.png, gui-after-02-render-live-v2/recover.png다.

사전 gui-before-initial에서는 실패 후 레거시 화면과 “출격”이 그대로 남았다. battle_hud.gd의 “출격”은 _start에 연결된다. 원문은 _start에서 refresh_panel → my_sel의 null 선택자 dead 접근, 이어 빈 fleets의 index 0 접근을 기록했고, do_cmd에서도 null 선택자 접근을 기록했다. 그 입력의 주체는 확인하지 않았다. 수정본에서는 legacy canvas/UI 숨김 및 프로세스 차단, 기존 BattleInput 비활성, 새 버튼 포커스가 적용됐다. 재개 실행의 stderr는 의도한 invalid_candidate_profile 로그만 남았다.

240초 WorldLink 재검사에서 before-attempt-02와 after-attempt-02 모두 clean exit 1(WORLD_LINK_FAIL 1), returning exit 0(WORLD_LINK_PASS)이었다. K2 common 8행/27단언, atomic 10행/546단언, battle/organization exit 0. 이전과 같은 ObjectDB/resource 종료 진단을 comparison-02.json 및 각 stderr에 보존했다. 기존 trace 오라클의 변조 거절 검사는 통과했다. 새 common 전체 trace는 strict 비교에서 8개 중 7개 파일이 일치했다. 다른 한 파일은 비라우팅 fallback의 단독 session_start seed(298773128→3394180763)만 달랐다. 이는 trace-comparison-detail.json에 기록한 진단이며 계획의 strict 비교 통과로 집계하지 않는다.

5-a 전체 12행을 실제 버튼 입력으로 모두 재현하지 않았다. 독립 5-b 및 마감 판단은 별도다.

## 추가 검증

- gui-before-buttons-v1 및 gui-after-02-buttons-v1의 03–08은 각 6개 대상의 표시, enabled, 위치, 실제 마우스 입력, 기존 연결된 버튼의 pressed 도달을 기록했다. 원본은 6개 모두 안내 부재, 수정본은 6개 모두 안내 표시였다. 두 실행 모두 exit 0. 수정본 03–04에는 사용자의 클릭이 포함됐다. 05 전 자동 편성 버튼을 누른 추가 입력 두 건과 추가 start_auto 로그는 원문에 보존했다.
- GUI 버튼 비교의 differences는 sim identity, tick, org, G.state, 선택, 이벤트 여섯 필드만 뜻한다. 기존 atomic의 대응 사례는 03 deck_begin_changed_org_reject, 04 org_auto_reject, 05 org_repair_reject, 06 deck_restart_reject, 07 deck_unrouted_title_reject, 08 host_ready_restart_guards이며 fingerprint, camera, 두 clock과 alpha, org/deck cache, trace path/bytes/seq/files를 별도로 비교한다. 03·04·05의 atomic 구조 호출과 실제 GUI 입력은 별개 증거다. 실제 버튼 실행의 전체 상태를 포괄하는 단일 snapshot은 없다.
- gui-before-roster-before 및 gui-after-02-roster-after는 직접 초기화 네 건으로 비운 profile, 잘못된 ally, 잘못된 foe 및 동일 foe 반복을 검사했다. 모든 반환 path와 기존 sim identity 보존이 일치했다. 수정본에서 네 건 모두 같은 경고 layer를 재사용했고 ally/foe 이유는 동일한 중립 문구였다. 성공 재시도에서 즉시 숨고 다음 프레임에 제거됐다. 정상 첫 시작에는 경고가 없었다. 두 프로세스 exit 0. 오류 주입 로그와 별도 종료 진단은 stderr에 보존했다.
- 공통 fallback의 엄격 trace 차이는 미해결이다. 최초 _ready의 randomize() 및 unrouted 분기의 randi()가 seed를 뽑는다. 후속 고정 seed init_game을 추가로 검사할 수 있으나 기존 최초 진입 trace의 동일성을 대체하지 않는다.
