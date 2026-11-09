# P02-7 현재 checkout 재동결 검증 기록

PLAN-v5 SHA d064c3e280345fea1e1c026a8b7941f5fc0bb61ad2d7492d9da3d3249d3bb904에 따라 기존 전체 K=6을 유지했다. K1/K2 기존 실행과 K3 0프로세스 preflight 원문은 PLAN-v5와 GUI-RESUME-EVIDENCE.md에 연결되어 있다.

- K4 k4-current/preflight.json과 freeze-complete.json은 엔진 wrapper/본체 및 class cache, HEAD/index/stage와 전체 실행 입력을 기록한다. before/after에서 다른 제품 파일은 FleetBattle3D.gd 하나다. 기존 사후 입력 대비 owner operation_private_state.gd SHA C5550999…→AC59A754…를 양쪽 모두 복제했다. 실행 전후 해시는 관측 시점 비교이며 그 사이의 변경 부재나 변경 주체는 입증하지 않는다.
- K4는 headless 19, 네이티브 4개 프로세스를 기록했다. common 8행 27단언 전후, after atomic 10행 546단언, battle/organization/direct roster 및 fixed trace는 exit 0. WorldLink before clean/returning 240초 timeout, after clean 예상 서막 단일 실패 exit 1 및 returning exit 0. WorldMap 제품 자동 4개는 카드 가시성에서 멈춰 exit 2. 모든 종료 진단은 K4-K5-OBSERVATIONS.json 및 stderr에 있다.
- k4-current/fixed-trace-comparison.json은 최초 _ready 이후 전역 RNG 고정값 27182818에 대응하는 후보 seed 2803350157, fallback 진단 및 실제 roster 동일, 추가 init_game의 seq 1 시작 행 한 개를 확인한다. 전체 행에서 wall_time/mono_ms만 제외해 strict 일치했고 control/pos 변조를 거절했다. 이전 common 및 새 common의 최초 randomize는 각 strict 7/8이며 합산하거나 고정 시드 성공으로 치환하지 않았다.
- 현 after routed 마우스 HWND 1052082 및 키보드 HWND 4721236을 별도 프로세스로 확인했다. 각 Godot 타이틀과 화면을 대조하고 실제 Windows 입력을 넣었다. 마우스 x=807,y=503 및 Return 4194309 직후 WorldMap/brief·outcome null/표준·auto 유지, exit 0, settings SHA 유지, trace 없음. 키보드 실행 앞선 글자 키들은 원문 보존. 원본 GUI의 off-target 및 교차 사례는 GUI-RESUME-EVIDENCE.md에서 별도 분류했다.
- 현 최초 routed 화면 k4-current/after-render-routed/initial.png는 이전 캡처와 PNG SHA 동일. 프로브 exit 81은 12초 렌더 전용 센티널이며 실제 탈출은 위 두 OS 사례가 별도 증명한다. 현재 1280×720 인셋 live-warning.png에는 읽을 수 있는 한국어 경고, recover.png에는 제거 상태가 보인다. 움직이는 배경 프레임이 달라 두 live PNG의 해시도 이전 캡처와 다르다.
- K5 k5-world-retry는 K4 실패 조각만 동일 복제본으로 재실행했다. 기존 테스트와 같은 전장 표식 touch 입력 후 형주 카드가 열릴 때까지 기다렸고, 출격 클릭 직전 동일 RNG seed를 고정했다. 양쪽 동일 하네스와 검증 입력이다. 모드/난이도/출격/연출 건너뛰기/중단은 실제 제품 Button에 전달한 자동 viewport 이벤트이며 OS GUI 입력은 routed 증거와 별개다. 각 완료 14단언과 취소 15단언, 네 프로세스 exit 0 및 입력 해시 유지. 완료는 실제 Brief seed 350157, 표준/auto, 같은 resolver의 thread join, 결산 1회, poll 멱등, 동일 조조 승리 결과 및 sim·outcome fingerprint 3028c9c61eadaa2fb1c7a6ea2934f6d2c6b6d079491b4cd0aa1cc1f17e3835c8. 취소는 같은 resolver join과 poll false, browse/card 복구 및 결과 부재.
- 이전 03–08 GUI의 전투 보존 snapshot은 여섯 항목만 포함한다. 카메라, clock alpha, trace, deck/org cache, 명령과 소비는 별도 atomic 증거 범위에서만 다룬다. 실제 GUI 이벤트에 546개 atomic 단언을 적용하지 않았다.

K6 WorldLink는 별도 순차 실행 기록을 참조한다. 독립 5-b와 전체 P02 완료 판정은 별도다.

## K6 마지막 WorldLink 재검사

k6-worldlink-retry/preflight.json은 동일 K4 before/after 입력 manifest, canonical 입력/엔진, 검사 하네스와 returning 설정 SHA, 네 사례 및 순차 320초/프로세스 제한을 기록한다. k6-worldlink-retry/processes.json의 전후 clean은 각각 exit 1, returning은 각각 exit 0이고 모두 timeout=false, inputs_unchanged=true, expected_result=true다. clean의 서막 단일 예상 실패와 154 ObjectDB/20 resource 종료 진단은 그대로 보존했다. K4의 before timeout을 K6과 분리한다. 이로써 전체 K1~K6을 소모했다.

## 실행 모델 근거

아래 해시는 원문 UTF-8 행에서 끝 CR/LF만 제외했다. 세션 대화 본문은 기록하지 않았다.

- C:/Users/nk782/.codex/sessions/2026/11/08/rollout-2026-11-08T16-54-18-01a1ba26-a8fe-7931-bf6b-b7da2d0708b0.jsonl line 1은 session_meta 01a1ba26-a8fe-7931-bf6b-b7da2d0708b0, /root/p02_seventh_impl, SHA 3a7658c48fc2377575deea6f6bb8bfba5df69c3c3ce78466d3c01941bb9f282d.
- 같은 파일 line 10의 구현 turn 01a1ba26-a996-7120-b225-b76a7f132cd3은 gpt-6.1-sol low, SHA e6da3878ba1454b7509ce4d37e907a6b56f16cdb66b838152259fa3883412c99.
- 같은 파일 line 574의 GUI 재개 turn 01a1ba35-4aed-7c72-97f6-30024fffba02는 gpt-6.1-sol low, SHA 156d49c44e7330a13d33cc8dcc7f9300ae789a1dfb737f30e05d9f1411a55b00.
- 같은 파일 line 929의 K3~K6 turn 01a1ba3c-767a-7bc3-a093-fbf10e2234dd는 gpt-6.1-sol low, SHA a96fffeb49d246d73748e079f5628df9b4765f3e8c8877e25ef46bea1fafde0d.
