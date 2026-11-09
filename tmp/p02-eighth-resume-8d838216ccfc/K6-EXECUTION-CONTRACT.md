# K6 실행 계약 보완 — 독립 재심 입력

이 문서는 RESUME-PLAN.md와 REVIEW-RESUME-INDEPENDENT.md를 함께 적용한다. 기존 심사 대상과 증거를 보존한다. 준비 작업만 수용됐으며 K6 실행 승인은 아직 없다. 원본 checkout, 제품 코드, Git, HTML, P03, 기존 자료에는 준비 결과를 쓰지 않는다.

## 실행 manifest의 필수 레코드

행마다 row_id, case_id, lane, ordered_dependencies, exact_argv, cwd, environment, input_files의 절대 경로·바이트·SHA, seed·시나리오·모드·fixture, 예상 exit 및 단언 ID 전량, timeout 및 정리 상한, stdout/stderr/typed raw/artifact 경로, oracle 비교 필드와 허용 편차를 기록한다. 하나의 프로세스가 여러 행을 다루면 case_id별 시작/종료 및 단언 귀속을 기록하고 wall-clock은 한 번 센다. 같은 이름의 단언 중복, 실행 후 기대값 생성, 선언된 단언/출력 누락은 해당 행 실패다. raw에는 순서·Variant 타입·정수 폭·좌표·ID·키를 보존한다. 시간·OS 메타데이터 등의 비교 제외 항목은 실행 전에 필드 단위로 동결한다.

프로젝트마다 비공유 APPDATA/LOCALAPPDATA 및 probe, 시험 전용 의존 파일을 지정한다. product before/after는 승인 세 hunk 외 차이 0, 계측 lane은 후보 대비 호출점 mode 치환 및 관측 지점만 allowlist로 고정한다. fixture 및 테스트 전용 변경은 제품 변경과 별도 목록으로 기록한다. 모든 probe와 fixture·runner의 해시, 엔진 두 바이너리·캐시, 실행 프로젝트 전체 manifest와 live guard를 실행 직전·직후 대조한다. P03 차이는 시점별 기록이다. 실행 의존 입력 또는 승인 hunk에 drift나 미귀속 변화가 있으면 보류한다.

## 행별 단언과 독립 비교

B/A는 실제 제품 before/after, I는 계측 after, N은 adapter와 독립인 before/native 기준이다. 각 실행에 동결된 stdout/stderr와 case_id가 있는 typed raw를 남긴다. 행별 예상 및 부가 파일은 다음과 같다.

| 행 | 사전 동결 입력과 기대 단언 | 비교 출력 |
|---|---|---|
| 01 | 입문 seed -27182818 direct/auto 각각 제품 B/A와 N, 각 0/1/10/100틱 및 증원 전후. 타입·배열 순서·native profile/정책, 10Hz, raw와 별도 viewer 큐 일치 | effective.gdvar, state.gdvar, commands.gdvar, raw.gdvar, viewer.gdvar, reinf.gdvar |
| 02 | 표준, 행 01과 동일 분모 | 행 01과 같은 파일을 난이도별 분리 |
| 03 | 상급, 행 01과 동일 분모 | 동일 |
| 04 | 극한, 행 01과 동일 분모 | 동일 |
| 05 | 확정 편성, 명시 순서의 제품 배치→동틱 명령→진행, 다음 tick 사건/투영. B/A/N 비교. fixture에 모든 전대, 좌표, 명령 인자, tick과 action ID를 고정 | deployment.gdvar, timeline.gdvar, raw.gdvar, projection.gdvar, camera_selection.gdvar, trace 원문 |
| 06 | POC direct 고정 RNG init_game, 초기화·지휘·clock 및 N 일치 | source_effective.gdvar, state.gdvar |
| 07 | 표준 direct 무효 org 및 명시 fallback fixture, 기존 fallback 선택과 실제 candidate 상태 | source_effective.gdvar, fallback 진단, state.gdvar |
| 08 | 실제 density/cross-counter 콜백, synthetic reinf 사후 이름 변경, 기존 mutable combat 참조 범위. B/A 비교 | 콜백 전후 좌표/속도·identity boolean·증원 raw 및 typed state |
| 09 | direct/auto × seed -1/4294967296 exact success. mode invalid 및 빈 mode 각각 exact error/path, constructor 0 | contracts.gdvar, counters.gdvar |
| 10 | 기존 active에서 foe 비배열 patch, 기존 오류, adapter 진입 0, 불변 및 정상 재시작 | 아래 거절 snapshot 및 counters.gdvar |
| 11 | unknown-difficulty Brief 기존 오류, worker 0·outcome 0 | brief.gdvar, diagnostic, lifecycle.gdvar |
| 12 | 최초 invalid roster의 legacy guard, routed 최초 탈출 및 천하 복귀/결과 0 | diagnostic, route.gdvar, outcome.gdvar |
| 13 | 유효 direct effective 및 seed를 유지해 mode만 invalid. I 정상 대조 각각 진입·생성·게시 1, I 거절 진입 1/생성 0/게시 0, active 및 최초 실패 분리, 정상 복구 및 routed 최초 천하 복귀/결과 0 | injected_mode.gdvar, counters.gdvar, 아래 snapshot 및 route.gdvar |
| 14 | 표준 seed -27182818 실제 B/A/I WorldMap. I 첫 회 진입1/생성0/thread0/result0, 오류 칩과 browse, 주입 해제 뒤 같은 Brief 재시도, 모든 lane 종료·join·결산 1 및 반복 poll 불변 | brief.gdvar, failure_ui.gdvar, progress.gdvar, terminal.gdvar, result_visibility.gdvar |
| 15 | B/A routed 마우스 출격/배치, 실제 Godot 렌더·초점 및 출처 귀속 | 아래 GUI 원문 전체 |
| 16 | B/A routed 키보드 재시작/천하 복귀, 실제 Godot 렌더·초점 및 출처 귀속 | 아래 GUI 원문 전체 |
| 17 | B/A 실제 WorldMap 제품 버튼에 viewport complete, thread join 뒤 게시 1, 결과와 반복 poll 동일 | input_kind.gdvar, lifecycle.gdvar, terminal.gdvar, result_visibility.gdvar |
| 18 | B/A 실제 WorldMap 제품 버튼에 viewport cancel, join 뒤 결과 0·browse·재클릭/반복 poll | input_kind.gdvar, lifecycle.gdvar, result_visibility.gdvar |
| 19 | B/A 제한 adapter/worker/replay/viewer 및 private/service/active replace 각각 exit 0 및 전체 suite assertion | suite별 stdout/stderr와 결과/단언 index |
| 20 | B/A BattleFlow·AutoResolve 각각 exit 0 | suite별 stdout/stderr와 결과/단언 index |
| 21 | B/A clean 및 returning 각각 별도 실행. returning exit 0. clean exit 1 허용 조건은 동일 이름의 기존 서막 실패 단 1건 및 그 외 실패 0 | stdout/stderr, fixture.sha, 결과 index |

행 01~04에서 N은 source→effective에 원래 Organization/ScenarioProfile과 독립 계산을 사용한다. adapter 결과를 기대값에 복사하지 않는다. direct·auto의 독립 초기 controls와 후발 증원 controls는 분리한다. 같은 큐를 소진하는 raw/viewer는 독립 인스턴스를 사용한다. 자연 증원 미관측과 debug 강제는 각각 기록한다.

행 10·13에서 active session 준비 전/거절 직후의 객체 identity를 프로세스 안에서 검사하고, tick·clock·RNG·fingerprint·명령 큐·사건 큐·trace·org·카메라·선택·UI 결과/route를 비교한다. 비교 동안 두 lane의 동일 tick을 고정하고 destructive drain 대신 독립 복제의 동등 snapshot 또는 실제 다음 drain 관측을 사용한다. 거절 뒤 정해진 명령·한 tick의 사건/투영을 동일 seed에서 거절을 건너뛴 control과 비교한다. 첫 오류 표시는 허용된 변경 목록에 명시한다. 정상 복구는 새 객체 게시와 오류 표시 제거를 별도 검사한다. I 카운터는 실제 호출·생성 직전·게시 지점에서 잡고 정상 대조가 같은 카운터 동작을 입증해야 한다. 원자성 범위는 준비 실패 이전 경계다. 게시 이후의 임의 엔진 예외는 별도다.

행 14는 B→A→I 순서다. 175초 역사 실패는 그대로 보존한다. 600초 이내 정상 종료의 tick·clock·fingerprint·typed outcome·UI 가시 전환 및 join을 각각 원문으로 남긴다. 600초는 관측 상한이다. 만료 시 취소 및 join을 요청하고 최대 630초 외부 한도에서 종료한다. 어떤 lane이든 만료·비정상 종료면 성공 집계에서 제외하고 원문을 보존한다.

## 상한 검산

실제 실행 manifest의 고유 process_id마다 내부/외부 한도와 종료 정리 예산을 적는다. 직렬 최악 상한은 모든 고유 프로세스 외부 한도 + GUI 관찰 및 증거 검증·정리 예약 시간이다. 이 보완안의 최대 예산은 6시간(21,600초)이다. 구현 준비용 예산 배분은 WorldMap terminal 3×630초 = 1,890초, GUI B/A의 행 15·16 각 2회 합계 최대 4×480초 = 1,920초, 그 밖의 모든 프로세스 예산 최대 16,590초, 실행 사이 OS 확인·증거 검사·종료 정리 예산 1,200초다. 480초 GUI 한도는 내부 관찰·외부 종료를 합쳐 프로세스 단위로 적용한다. 이 배분은 실제 프로세스 수·합계의 검산을 대체하지 않는다. 초안에 있던 320/630초는 잠정값이며 최종 manifest가 실제 합계를 증명하기 전 실행하지 않는다. K1~K5를 포함해 K=6이며 이번 실행의 일부만 시작해도 K6을 소진한다. 누락행도 21행 분모에 남긴다.

## GUI 창 대응과 입력 귀속 게이트

실행 전에 독립 검토가 필요한 조건이다. 이번 문서는 대상 Godot 창이나 입력 성공을 증명하지 않는다.

- OS 기록은 실행별 자식 PID, creation time, executable image 경로/SHA와 Godot 자체 PID/native HWND를 묶는다. Win32에서 HWND 유효성·소유 PID·고유 제목·foreground HWND·client rect 및 ClientToScreen·DPI를 읽는다. mouse 화면 좌표 hit-test가 대상의 client 또는 그 자식인지 확인한다. 제목에는 실행마다 새 nonce를 넣고 OS와 Sky 양쪽에서 일치하는 단일 창을 확인한다. opaque Sky ID는 Win32 핸들로 변환하지 않는다. 최신 Sky screenshot, Sky 반환 Window 객체, client geometry 및 예상 버튼을 action_id에 연결한다.
- 입력 전부터 입력 후 제품 전환까지 foreground WinEvent를 타임스탬프와 함께 읽기 전용으로 연속 기록하는 수단을 사전 검증한다. 로그 시작/종료·heartbeat와 gap/overflow를 검사한다. 타깃 이탈, 창 파괴/재생성, 확인 불능이면 해당 action 실패다. 독립 observer는 읽기만 하며 활성화나 입력을 하지 않는다.
- 실제 입력은 스킬이 안내한 Sky의 최신 screenshot을 사용하는 단일 click 또는 press_key다. 한 번에 하나의 action_id만 열고 요청 시작/종료, Sky 성공·오류, OS 이벤트의 시간·좌표/키·종류·injected flag, Godot 수신 이벤트 및 focus·route를 동일 시간 기준에서 교차 기록한다. 필요한 경우 읽기 전용 저수준 이벤트 관측의 지원 여부와 로깅 권한을 먼저 검증한다. 입력 창 밖의 데이터나 키 내용은 수집하지 않는다.
- injected flag는 Sky의 배타적 출처를 보장하지 않는다. 독립 검토에서 승인한 구별 수단이나 다른 입력원이 개입하지 않았다는 독립 관찰이 필수다. 사용자 물리 입력, 다른 injected 이벤트, 요청 대비 이벤트 수/순서 불일치, clock 상관 오차, observer 공백, foreground 전환이 있으면 성공으로 집계하지 않는다. 관측 수단 자체가 환경에서 가능하다고 확인되지 않으면 GUI 행은 미완료로 분리하고 K6 사전 실행 승인도 보류한다.
- 보존 파일은 process.json, windows.jsonl, foreground.jsonl, action.jsonl, os_input.jsonl, godot_input.gdvar, focus_route.gdvar 및 최신 네이티브 렌더 캡처 증거다. OS 이벤트 관측과 캡처 보존은 적용 스킬과 사용 환경에서 허용되는 방식으로 수행한다. 승인된 수단으로 필수 원문을 보존할 수 없으면 해당 GUI는 미충족이다.

완성된 실제 명령·fixture·probe·expected 및 모든 SHA를 제출한 후 독립 재심한다. K6 후 독립 5-b 전에는 원본 제품 코드 적용 및 전달 마감을 보류한다.
