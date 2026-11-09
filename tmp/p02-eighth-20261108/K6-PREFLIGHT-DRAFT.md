# K6 사전 동결 후보 — 실행 보류

이 문서는 실제 실행을 허용하지 않는다. 조율자 승인 및 독립 재심, K4·K5 종료, 별도 SHA 검증 후 한 묶음만 실행한다. K1/K2 비정본도 각 1회, K3 1회, K4 1회, K5 1회로 계산한다. 남은 1회를 재실행하지 않는다. 사용량 제한 관측 즉시 중단한다.

K4 자동 재시도는 OS 프로세스 timeout이 아니다. 175000ms 프로브 deadline에 도달하여 ASSERT auto-retry-join-result가 false이고 프로세스 exit 1이었다. 기존과 변경 경로의 동일 seed 결산 대조 없이 원인을 판정하지 않는다.

후보 입력: candidate-k1/before, after의 실행 입력 manifest(4203), instrumented-k4의 별도 manifest, 두 Godot 본체, canonical class cache, 현재 live 원본 SHA, 재수집 workspace SHA 및 Git branch/HEAD/index/stage, 새 probe/runner/config SHA. 실행 시 직전·직후 전량 대조. 소스 동시 변경 시 실행 보류 또는 증거 무효. GUI와 headless에는 고유 프로젝트 probe 상대 경로 및 고유 APPDATA/LOCALAPPDATA를 할당한다. 원본 checkout·cache에는 실행하지 않는다.

## 고정 21행

아래 증거는 부분 관측이다. 부족한 행은 분모에 남기고 0/미검증으로 집계한다. 이 문서는 관측 계약이며, 아직 없는 명령이나 프로브를 실행 완료로 쓰지 않는다.

| 행 | 입력/기대 | 현재 증거·남은 부분 |
|---|---|---|
|1|입문, -27182818, direct/auto; 동일 효과/원본 native, 10Hz 0/1/10/100 및 보강|K3 typed direct effective/raw+native, auto raw+native 일치. auto effective identity, viewer 큐와 자연 증원은 부족|
|2|표준, 같은 계약|동일|
|3|상급, 같은 계약|동일|
|4|극한, 같은 계약|동일|
|5|확정 편성, 배치·명령·진행, trace|미검증|
|6|POC, -27182818, direct; native state 동일|K3 snapshot 일치|
|7|표준, 잘못된 org의 기존 자동 편성 fallback|미검증|
|8|bench density, cross-counter, synthetic alias; callback 후 변환 없음, 참조 보존|미검증|
|9|표준, -1/4294967296×direct/auto; invalid 및 빈 mode exact fail, 생성0|K3 정적 계약/상태. 생성0 count 추가 필요|
|10|direct 실제 active, foe 비배열; 기존 guard, factory 0, 보존 및 재시도|K3 오류 사전, K4 guard factory 0 관측. before active 대응 부족|
|11|unknown-difficulty; 기존 Brief 오류, thread0/result0|K3 전후 일치|
|12|direct 최초 invalid roster, 기존 오류, 천하 복귀/result0|미검증|
|13|direct 계측 복제만 mode invalid, valid guard 통과, 진입1/생성0/게시0·복구|K4 headless 상태 및 버튼 pressed.emit 합성 입력으로 돌아옴. 전체 trace/time/event snapshot 및 실제 GUI 입력 부족|
|14|auto 계측 복제만 mode invalid, valid Brief, 진입1/생성0/thread0/result0, 탐색 및 복구|K4 거절·browse 및 retry start 확인, 175s join assertion 실패. 동일 seed 비교 필요|
|15|실제 routed direct OS 마우스 출격/배치|K4 OS 입력 기록 없음. K5 OS_MOUSE 다수, Sky 입력은 0이며 실제 입력 주체 미확인·성과 미집계|
|16|실제 routed direct OS 키보드 재시작/천하 복귀|미검증|
|17|실제 WorldMap auto 완료, join 및 결산1|K4 process 기록 판독 필요|
|18|실제 WorldMap auto 취소, join 및 결산0|K4 before exit 0, after 원문 판독 필요|
|19|제한 adapter/worker/replay/viewer 및 private/service/replace 기존 suite, 예상 exit 0|K1 비정본 로그 별도|
|20|BattleFlow 및 AutoResolve, 예상 exit 0|K1 비정본 로그 별도|
|21|WorldLink clean/returning; 두 clean 동일 기존 prologue 실패일 때만 분리, returning exit0|K1 비정본 로그 별도|

동일 seed 종료 대조 제안: before·after·injected 회복 순차 프로세스에서 같은 표준 Brief -27182818, 같은 WorldMap._start_resolve 및 반환 상태. each 600000ms 내부/630s 외부 deadline, 5초 간격 Time.get_ticks_msec(), resolver.clock_s(), worker is_alive, state, poll/결산 가시성 기록. 직접 live worker tick을 읽지 않고 공개 clock으로 진행을 남긴다; join 후 sim.st.tick, fingerprint, outcome raw, thread null, poll idempotent 비교. 프로브 종료 전 worker는 반드시 취소하고 join한다. 600초는 유한한 관측 한계일 뿐 충분함을 보장하지 않는다. 만료 시 해당 행은 미검증이다. 이전 실행과 상대 속도를 추정하지 않는다. 계속 도는 외부 엔진/K4·K5와 겹치지 않게 한다.

GUI는 OS 입력마다 고유 제목·fresh Sky 창 ID·Godot native HWND·Godot OS PID·실행 PID·OS foreground·창 rect·fresh screenshot 동시 일치가 필수다. 사용자의 물리 ESC/stop 또는 대상·foreground/좌표 불명 시 입력을 중단한다. 별도 lane의 probe는 viewport 합성 입력을 OS 입력으로 기록하지 않는다. 이미지와 입출력 raw를 보존한다. 앱 창 관찰/조작은 computer-use 스킬을 따른다.

Sky API의 Window.id는 문서상 opaque이며 owner PID/foreground/rect 필드가 없다. 원본 창과 독립해서 검증할 수 없는 상태에서는 GUI OS 입력을 실행하지 않는다. gui8-k6-draft.gd는 Godot 쪽 자체 PID·native handle·focus·rect 관측만 추가하며, 그 기록을 OS 소유 판정으로 승격하지 않는다.
