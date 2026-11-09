# P02 네 번째 조각 계획 — 제품 표시용 사건 회수 경계

2026-11-08 KST. 독립 계획 수용 전 구현 금지. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

## 0–1. 의도와 실제 제품 경로

사용자 가치는 향후 새 전투 소유자를 화면에 붙일 때 기존 안개 가시성 규칙대로 사건을 표시하는 데 있다. 이번에는 제품 FleetBattle3D가 이미 사용하는 진영별 사건 회수를 제한 private owner에서 동일하게 지원한다. 실제 장면을 private owner로 전환하는 것은 이번 인수에서 제외한다. 테스트는 production 메서드의 경계를 검사하며 새 CLI, 제품 옵션, 호스트 래퍼를 만들지 않는다.

- 정본은 저장소 워크플로우 플레이북, CLAUDE, battle-core 인계, P02 진행표·first/worker/replay 결과/인계 및 비-Astra 독립 구현·마감, 세 번째 계획/controls 보완·독립 계획 심사, I01 readiness K01~08 및 A04~06이다. C:/, C:/WorkSpace와 저장소 숨김·ignored 포함 AGENTS.md 탐색에서 적용 파일을 찾지 못했다.
- FleetBattle3D.gd:137–244 기본 장면의 _ready→init_game은 검증 전에 이전 view/VM/FX를 비우고 실제 적벽 프로필을 WorldLink seed, 난이도·편성, 공간·기동 튜닝과 함께 구성한다. 현재 실패 정책은 편성 오류 UI 또는 legacy fallback이다. BattleSim 생성 직후 유비군을 direct로 바꾸고 두 TickClock, G, 선택/그룹/카메라/trace를 초기화한다. :353–478은 배속·감속·배치 중 일시정지, 부분틱 clock, 투영→도착 처리→native side0 사건 drain→trace/UI, 즉시 issue 및 초기 move/face→place를 결합한다. owner는 이 관람용 사건 필터가 없고 place/face/posture/delegate, live sim trace/debug, 적벽 모듈 및 증원 전체도 제공하지 않는다. 기존 주 경로에 제한 입력을 넣거나 raw drain으로 연결하면 배치·지휘 또는 안개가 깨진다.
- world_map_screen.gd:600–620,672–690은 기존 BattleBrief→AutoResolver.start/poll/cancel→BattleOutcome 및 진행 UI다. 제한 operation worker는 plain snapshot으로 worker에서 owner 생성/실행/닫기, 메인 join 후 DTO 공개만 지원한다. 제품 결산과 진행 계약 없이 DTO를 결산으로 해석할 수 없다.
- BattleSim.replay 호출자는 battle_flow/core_rules/commander_ai/organization_rules/placement/special_skills 테스트다. 제품 diagnostic trace는 완전한 fresh 입력/초기 controls/적용 명령 및 cursor를 제공하지 않는다. 제한 replay CLI를 제품 재생의 진입점으로 세지 않는다.
- 향후 호스트 연결 조건은 정식 제품 입력과 opt-in, 독립 candidate 구성(정규화·controls·첫 투영 준비 뒤 commit), 모든 호스트 상태/trace/FX/설정/WorldLink의 실패 보존, UI 명령과 사건 소유권, main-thread lifecycle이다. 이 조각은 그중 사건 경계 한 항목만 진전시킨다. 적벽의 비지원 기능을 제거하거나 source를 effective로 간주해 호스트 진입을 우회하지 않는다.

## 2–3. 변경과 인수 조건

- [ ] core/battle/operation_private_state.gd에 생산 API drain_events_for(side: Variant) -> Dictionary 한 메서드를 추가한다. 기존 read_projection과 동일한 우선순위로 _guard 후 exact int 0/1 확인. guard 실패는 {ok:false,error:기존guard,path:"owner"}, side 오류는 {ok:false,error:"invalid_side",path:"side"}. 숫자 문자열·bool·float의 강제 변환 금지. 오류에서 단일 event queue와 전체 소유자 상태는 그대로다.
- [ ] 유효 입력은 _busy 구간에서 기존 _sim.drain_events_for(side)를 단 한 번 호출하고 그 결과를 깊게 복사한 typed 사건 배열 {ok:true,events:...}을 돌려준다. 시간·동틱 ID·순서·필드·타입을 보존한다. 별도 필터나 event cursor, 누적 버퍼, payload/키 삭제 규칙을 만들지 않는다. detect가 없으면 native 전량, detect가 있으면 native 기준으로 숨김/마스킹과 contact side0 조건을 그대로 사용한다. 판정은 사건 발생 시점이 아닌 drain 시점의 detect.contacts 기준이며, 추정 접촉도 해당 ID가 테이블에 있으면 native가 동일하게 취급한다. 마스킹은 native가 정의하는 수준이며 원본 drain도 남으므로 owner 자체를 보안 권한 API로 분류하지 않는다.
- [ ] 숨긴 사건까지 단일 큐에서 소진된다. 즉시 raw 또는 반대쪽 drain은 빈 배열이다. raw→filtered 역시 동일하다. 동시에 두 진영에게 fan-out하거나 유효 drain을 재시도하는 계약은 없다. 호출자는 기존 owner와 동일하게 한 소유 스레드에서 직렬로 사용한다. _busy는 재진입 가드이며 lock이 아니다. 기존 worker의 join/공개/취소 경계에는 영향이 없다.
- [ ] runtime-ready 실제 입력은 기존 adapter.create의 명시 mode/format/profile/seed/hz/initial_controls/policy/max_ticks 그대로 사용한다. 기본 게임은 기존 legacy 경로다. CLI sync/worker/replay의 raw 사건 소비와 출력, BattleSim, 실제 UI/trace 및 WorldMap은 기존 계약을 유지한다. 시계·initial controls·명령의 의미를 바꾸지 않으며 event drain이 tick/clock, controls, command queue/log, 투영/요약에 영향을 주지 않음을 확인한다. drain 전후 내부 completed packet의 이벤트 구성과 캡처 허용 결과는 동일 시점의 직접 native 실행과 비교한다. 새 code SHA로 과거 private packet의 버전/코드 일치 보장을 추가하지 않는다.

## 5-a. 오라클과 고정 분모

독립 계획 수용 후 구현 전 기존 tests/fixtures/p02/{poc,services,timeout-poc}.json의 raw SHA, 직접 typed 프로필/controls 작성 및 기대값을 고정한다. 차별적 사건을 만들 fixture의 위치/방향 변경이 필요하면 동결된 파생 원본과 변환 근거를 이번 증거 루트에 둔다. 최소 재현은 기존 tests/detection_rules.gd의 far enemy stop 사건을 따른다. adapter를 통과한 owner의 사건 원문을 기대값 생성에 쓰지 않는다. 별도 native BattleSim에 같은 seed, hz, typed profile 및 명시 controls를 독립 적용하고 즉시 issue와 step 후 native drain의 배열/순서/타입/값을 비교한다.

- [ ] 고정 신규 API 검사 논리 행 14개. E01–E04 fog 없음/있음 × side 0/1 네 행. 매 행 native raw에 직접 명령으로 양쪽 식별 가능한 사건이 실제 발생함을 확인하고 filtered 결과는 두 side를 별도 owner/sim에서 비교한다. E05 contact 가시성 변화 및 contact side0 조건, E06 미탐지 salvo sq=-1 및 상대 other=-1 분기(동일 사건일 필요 없음). E05–06의 native fixture가 재현하지 못한 분기는 exit0으로 분류하지 않으며 원인과 실제 관측 건수를 기록하고 계획 재심사한다. skill 규칙은 제한 프로필 미지원이므로 별도 범위다.
- [ ] E07 filtered→raw/반대쪽 empty, E08 raw→filtered empty. E09–E12 invalid side false, 0.0, "0", -1 각각 오류·전체 owner 무변이 및 후속 정상 drain. E13 closed/busy 우선순위 및 내부 큐 보존. busy 상태는 테스트에서만 주입하며 실제 동시 호출 검증으로 집계하지 않는다. E14 반환 DTO의 깊은 사본과 capture/clock/control/command/projection 비변이. 사본 관찰은 drain 이전 보관한 원래 event 배열 또는 nested 자료 참조와 비교하여 돌려받은 자료의 수정이 원본에 미치지 않는지 검증한다. capture 비교는 양쪽에서 대응되는 이벤트 소거 시점을 맞추고 전체 복구 스키마 인수로 세지 않는다.
- [ ] E05/E06의 사건이 정상 public issue/advance에서 관측되지 않으면 우선 직접 native 경로로 fixture를 보강한다. 필터 분기만을 위해 테스트에서 사건을 생성해야 하면 public 자연발생 검사와 분리 표기하고 동일 native fixture의 필터 전달에만 근거로 삼는다. native 기대값과 별도로 fog 유무의 event count, raw에 존재하나 filtered에서 사라지는 ID, masked id, 순서 및 native 타입을 주장하고 side 교환/raw 대체 반례가 실제 실패하는지 검증한다.
- [ ] 실제 프로세스 기본 분모는 신규 API runner 1, 기존 API p02_headless_adapter / p02_worker_adapter / p02_replay_adapter 및 기존 detection_rules / battle_flow / placement / world_link / i01b_active_replace 회귀 8, 변경 전후 CLI sync / worker / replay의 대표 성공 3쌍(6회), 변경 전후 지원 밖 입력 거부 1쌍(2회), 총 17회. 이전 회귀 진단/exit/timeout 분포와 actual 값 분리. 새 runner 1회의 14행과 내부 assertion을 프로세스로 세지 않는다. CLI 성공은 새 출력 경로와 출력 raw SHA, 거부는 actual exit1/error/path 및 출력 부재로 확인한다. 이 분모에 제품 화면 테스트를 넣지 않는다.
- [ ] K=6 코드 재시도. 최초·실패·최종의 명령/exit/timeout/stdout/stderr/엔진 로그, SCRIPT ERROR/ERROR/WARNING, 입력/출력 SHA와 오라클 분모를 보존한다. 변경 전후 지정 회귀의 기존 종료 진단 및 전체 diff-check 결과를 별도 비교한다. 현 기준선은 CHECKLIST-OPEN.md 33행 후행 공백으로 exit2다. 새 소유 hunk는 별도 diff-check 통과가 필요하다. 스펙·오라클 또는 허용 hunk 변경은 독립 재심사. 사용량 제한이면 즉시 보고하고 중단한다.

## 보존 및 5-b/6

- [ ] 기준선 branch codex/feature-i01b-not_remove, HEAD fb660cea69207fd332e26128643007694910a253. baseline.json은 tracked 2453 + nonignored untracked 6203 = 8656 경로 bytes/SHA, 결측·읽는 중 변경·관측 외부 신규 0. 이번 증거 루트 자체 제외. index.raw/staged SHA와 실제 index 파일 SHA, branch/head raw 별도. 기존 ZIP 네 개 포함. 시작·종료 목록이 같아도 동시 파일 전체를 원자 스냅샷으로 보장하지 않는다. 실행/편집 직전 및 사후 재검사로 drift를 판정한다.
- [ ] 허용 생산 hunk는 위 메서드 한 개, 신규 검사는 tests/p02_viewer_events.gd 한 파일. 추가 test uid/import 자동 생성 금지. 검사 입력·명령·오라클·결과·사전 사본과 로그는 이번 증거 루트만. 기존 untracked owner 원문을 사전 복사하고 최종 hunk 역제거 결과를 SHA 일치로 증명한다. 기존 docs/checklist는 이번 계획·구현 동안 그대로 두며 독립 5-b 이후 기록용 hunk는 별도 범위 승인·동결한다. 이전 ZIP·HTML, index/HEAD, P03 활성 파일을 변경하거나 되돌리지 않는다. 동시 외부 변경은 전수 감사에서 따로 기록하고, 소유 hunk와 겹치거나 출처 불명 차이는 편집을 보류해 조율자에게 넘긴다.
- [ ] runtime-freeze.json에 canonical engine과 class cache SHA, engine-version.txt에 실제 버전을 동결했다. 실행 전후 해시 확인 및 Private._classes()의 canonical 리소스 경로를 확인한다. 변경 전/후 각 단계 runner/fixture/의존 source의 실제 경로·SHA를 기록한다. editor/import/cache 갱신은 금지, 오염된 실행은 비정본. 브랜치/worktree/commit/push/merge/HTML/browser 금지.
- [ ] 독립 비-Astra 계획 수용 후 구현자를 배정한다. 구현자와 다른 독립 비-Astra 모델이 5-b에서 native oracle의 변별력, 분모, 실패 불변성, 단일 큐·호환 경계, 변경 전후 증거와 소유 hunk 역제거를 검증한다. 실제 session_meta/turn_context의 session ID, parent, agent path, 모델, 판정 원문 SHA를 남긴다. 동일 세션이거나 실제 모델 확인 불가 시 교차 검증으로 승인하지 않는다.
- [ ] 정본 실행과 독립 수용 뒤 결과/체크리스트/인계에는 관측한 범위만 기재한다. 제품 FleetBattle3D·WorldMap·replay 연결, K01~08 공동 인수, 보급 완료 E2E, Android/성능·UI 화면, OS/engine 장애·동시 호출은 별도다. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED.
