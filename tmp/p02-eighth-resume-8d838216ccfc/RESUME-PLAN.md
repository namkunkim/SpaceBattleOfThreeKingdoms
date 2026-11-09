# P02 여덟째 조각 재개 계획 — 독립 검토 전

범위는 FleetBattle3D와 AutoResolver의 기존 native 초기화 공통화다. 원본 제품 코드 미적용. P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED. 계획자 실제 turn metadata는 gpt-6.1-sol / low. 기존 v1, v2 한정 수용 및 독립 심사의 입력 계약을 따른다. 이 보완안은 검토 대상이며 실행 상태가 아니다.

## 동결과 실행 순서

1. WORKSPACE-FREEZE.json의 Git branch/HEAD/index/stage, Git tracked 및 표준 ignore 제외 untracked 경로별 bytes/SHA를 보존한다. 2,453 tracked / 39,759 untracked의 순차 관측에서 읽기 오류·파일 내부 drift 0, Git 메타데이터 전후 일치, 목록 차이 5건은 모두 tmp/p03-*다. 시점별 관측이며 변경 주체를 판정하지 않는다. EXECUTION-INPUT-FREEZE.json에서 live/격리 before/after/계측 실행 입력을 각 4,203경로씩 대조한다. 누락·변경 또는 승인 hunk 교차 시 실행 전에 새 계획 검토를 받는다. canonical patch와 기존 증거는 보존한다.
2. 실제 명령, 사용자 환경, 케이스별 기대값과 raw artifact 경로를 완성해 독립 수용을 받는다. 현재 k6-proposed-not-run/proposed-jobs.json은 초안이고 5·12·15·16행 등의 명령이 비어 있다. 현재 계획에는 명령 보완 조건을 기록한다. 보완 도구 제작은 다음 구현 역할이다.
3. 새 격리 복제만 사용한다. 프로브 경로·로컬 사용자 데이터·로그를 프로세스마다 분리한다. 엔진 본체 및 console wrapper, 캐시, 입력, runner, fixture, 세 복제의 승인 차이를 SHA로 고정한다. 원본과 P03 프로세스를 건드리지 않는다. K4/K5 역사 근거 및 실패는 별도 유지한다.
4. K1~K5는 모두 한도에 산입한다. 남은 K6 한 묶음은 preflight와 독립 재심을 충족한 뒤 최초 제품 검증 프로세스 시작부터 소진한다. 각 lane은 한 번만 시작한다. 예상하지 못한 종료와 시간 초과는 원문 보존 및 실패이며 중복 실행으로 덮지 않는다. 전체 직렬 상한 6시간, 개별 상한은 아래와 초안 manifest를 따르고 합산 상한도 6시간 이내인지 사전 계산한다. 사용자 stop 또는 사용량 제한 발생 즉시 중단하고 원문과 미완료를 보고한다.
5. 종료 뒤 SHA 재검사와 21행 증거 및 전체 프로세스/단언 분모를 정리한다. 독립 5-b가 성공 판정한 후에만 원본 적용을 검토한다. 적용 직전 예상 hunk와 현재 입력 일치, 적용 직후 무관 경로 보존을 다시 확인한다. K6 누락/실패 또는 GUI 미충족이면 미완료로 남긴다.

## 고정 행 실행 계약

B/A는 원본 코드 복제 및 승인 후보 복제의 별도 실제 제품 실행이다. N은 adapter 호출 없는 독립 native, I는 실제 호출점에서 mode만 주입한 별도 계측 복제다. K6 명령의 공통 꼴은 동결 console exe --headless --path 격리절대경로 --script res://고유_프로브.gd -- 단계와 출력 절대경로다. GUI만 --headless를 제거하고 동결된 GUI scene-tree runner로 실행한다. exit 0 및 명명된 모든 단언, 양쪽 원문, capture hash가 성공 조건이다. clean WorldLink의 한정 편차는 아래에 별도 명시한다.

| 행 | 실행 lane과 판정 |
|---|---|
| 1 | 입문 seed -27182818 B/A/N direct·auto. native-k3를 보완해 실제 caller effective, typed 시계·지휘·raw 및 별도 viewer 큐, 증원 직전과 첫 증원, tick 0/1/10/100을 비교 |
| 2 | 표준, 행 1과 같은 lane 및 관측 |
| 3 | 상급, 행 1과 같은 lane 및 관측 |
| 4 | 극한, 행 1과 같은 lane 및 관측 |
| 5 | 고정 편성 B/A/N, 제품 배치→동틱 명령→진행 및 다음 tick 사건/투영, 카메라/선택·trace 원문. 새 전용 명령 필요 |
| 6 | POC B/A/N, -27182818 고정 init_game과 native 상태 |
| 7 | 표준 B/A/N, 무효 org 입력에서 기존 자동 편성 fallback, 출처 표식과 native 초기 상태 |
| 8 | B/A, bench_density와 cross_counter 실 callback 및 synthetic 사후 alias를 각각 실행. 변환 이후 표식과 reinf/combat identity, 첫 증원 상태/사건 비교 |
| 9 | A/I, -1 및 4294967296 × direct/auto, 정확 성공 shape. invalid/빈 mode 정확 실패와 생성 0 |
| 10 | B/A/I, active direct foe 비배열 guard, factory 0, 이전 객체/trace/명령·사건, 정상 재시작 |
| 11 | B/A, unknown-difficulty Brief, 오류 원문, thread/outcome 0 |
| 12 | B/A, 최초 invalid roster guard, 실제 routed 천하 복귀와 결과 0. 별도 최초 실패 fixture 및 명령 필요 |
| 13 | I, direct 실제 호출 mode invalid. 유효 effective·seed, 진입1/생성0/게시0, 기존 객체 및 UI·trace·명령·사건, 정상 복구. 최초 실패 변형의 실제 천하 복귀와 결과 0 포함 |
| 14 | B/A/I, WorldMap 실패→브라우즈→재시도 terminal 비교. 아래 고정 Brief |
| 15 | B/A 실제 GUI, routed 마우스 출격·배치 및 네이티브 렌더 |
| 16 | B/A 실제 GUI, routed 키보드 재시작·천하 복귀 및 focus |
| 17 | B/A world-complete, viewport 제품 버튼, join 뒤 결산 1 및 재poll |
| 18 | B/A world-cancel, viewport 제품 버튼, join 및 결산 0과 browse |
| 19 | B/A tests/p02_headless_adapter, p02_worker_adapter, p02_replay_adapter, p02_viewer_events, i01b_private_state, i01b_service_state, i01b_active_replace 각 exit 0 |
| 20 | B/A tests/battle_flow.gd 및 autoresolve.gd 각각 exit 0 |
| 21 | B/A WorldLink clean 및 returning. clean exit 1은 양쪽 동일 기존 서막 단일 실패 원문일 때만 한정 편차로 집계. returning exit 0 |

자연 증원 전 종결이면 debug 강제 별도 표기, 자연 증원 미관측 기록. 공통 18행과 after-only 3행을 별도 집계한다. 기존 K3/K4 결과는 참고이며 현재 분모를 채우지 않는다.

## WorldMap 오류 주입과 정상 종료

먼저 B/A 모두 별도 fresh WorldMap에서 명시 표준 Brief seed -27182818, mode auto, 동일 정본 payload와 returning fixture를 사용한다. 제품 _start_resolve 진입에서 준비, start, process loop의 poll, join, UI 결산 가시 전환 1회, 결산 결과와 poll 재호출 불변을 수집한다. 그 후 I의 새 WorldMap에서 첫 호출 한 번만 유효 Brief로 mode invalid를 주입한다. 진입 1·생성 0·thread 0·outcome 0, 실제 오류 칩/browse/resolve 패널 복귀를 관측한 뒤 주입을 해제한다. 동일 화면의 실제 재시도 경로에서 동일 Brief를 재확정한다. retry-terminal-k6 초안의 직접 함수 호출은 준비와 터미널 비교용이며 실제 버튼 경로 보완은 별도 명령에 명시한다.

각 프로세스 내부 600초, 외부 630초. 5초마다 elapsed, 공개 clock_s, worker 생존, 제품 state/결산 가시성을 남긴다. live worker의 sim 내부를 직접 읽지 않는다. 제한 내 미완료면 취소 및 join 관측을 남기고 exit 1. terminal 뒤 tick/clock/fingerprint/typed outcome과 게시 횟수를 B/A/I 원문으로 비교한다. B/A 미종료도 실패다. K4 175초 내부 제한에서 retry start true, join-result false, exit 1이며 외부 timeout과 구분한다. 600초는 유한한 관측 창이며 충분함은 미검증이다.

## GUI 독립 소유 확인

computer-use Sky list_windows 실측 7개, Window 키 app/id/title, Godot 대상 0개. id는 문서상 opaque다. Win32의 읽기 전용 GetForegroundWindow→GetWindowThreadProcessId→GetWindowRect 실측은 비대상 창 HWND 6883306, PID 4164, TID 37048, rect [-8,-8,1928,1040], 두 전경 조회 일치. 이것은 API 동작 근거이고 대상 소유나 입력 증거는 아니다.

향후 고유 run-id 제목과 프로세스 시작 시각·PID·실행 파일 SHA를 고정한다. Godot이 보고하는 native HWND/PID와 OS의 IsWindow, GetWindowThreadProcessId, GetForegroundWindow, GetWindowRect 및 DPI 일치 client 영역을 대조한다. Sky 반환 제목/앱과 OS에서 읽은 동일 고유 제목·경로의 유일성을 매 입력 직전에 대조한다. 화면 좌표 대상은 최신 screenshot과 client 영역 및 hit-test가 일치해야 한다. SDK 창 ID를 HWND 숫자로 간주하지 않는다. 입력은 승인된 Sky 호출만 사용한다. 바로 뒤 전경 및 제품 입력 이벤트, 시간, event 종류/위치·키, focus 및 실제 화면 전환을 교차 기록한다. 고유 창 매칭·전경 전환 감시·입력 주체 상관관계를 독립 검토자가 수용할 수 없거나 입력 주체가 섞이면 해당 GUI는 미완료다. Sky와 Win32의 두 조회는 원자적이지 않으며 단순 전후 일치만으로 중간 전경과 입력 주체는 확정할 수 없다. 이번 조사에서 Godot 실행, 활성화, 입력을 수행하지 않았다.
