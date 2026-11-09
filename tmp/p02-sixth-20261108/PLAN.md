# P02 여섯 번째 조각 계획 — 실제 FleetBattle3D 준비/게시 경계

2026-11-08 · 독립 계획 심사 대기, 구현 미착수. P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

## 의도 및 근거

제품의 실제 `scenes/FleetBattle3D.tscn`에서 새 전투를 준비하는 동안 현재 호스트를 보존한다. `init_game()`이 먼저 기존 3D 함대/VM/FX를 비우는 순서를 바꾼다. 현재 적벽은 계속 기존 방식으로 플레이하며, 이번 인수는 제품 호스트 준비/게시 경계다. 새 CLI, UI 선택기, operation 엔진 구동 또는 적벽 operation 출시를 주장하지 않는다. 작업물은 본 파일과 증거 폴더만 생성됐다.

- 실제 직접 지휘: `WorldMapScreen.make_brief/_finish_sortie → WorldLink.go_battle → FleetBattle3D._ready/init_game`; `command_deck.begin_battle/restart/to_title` 및 `org_screen.open_org`도 `init_game`으로 진입. `BattleBrief`로 난이도와 seed를 전달한다. 기존 무효 편성은 자동 배치 preview + 안내 + org_blocked로 처리되며, legacy 시나리오 로드 실패의 명시 오류/대체는 원래 계약이다. `back_to_world → BattleOutcome.from_sim → WorldLink.take_outcome`은 종료 후 1회 결산 경로다.
- 실제 자동 지휘: `WorldMapScreen._start_resolve/_process/_cancel_resolve/_exit_tree → AutoResolver.start/poll/cancel`, worker는 스냅샷만 반환하고 메인 join 후 결산과 결과 UI를 게시한다. 5조각 독립 5-b 및 마감 재심은 여기만 한정 수용했다. operation worker는 CLI summary/events만 보유하며 제품 결산과 진행 UI는 아직 지원하지 않는다.
- `operation_runtime_adapter`와 private owner의 제한 입력은 runtime-ready identity, 10Hz, 제한 정책/모듈이다. 실제 적벽의 증원, 시나리오, 지휘관 AI, 변형 전투 규칙, morale/victory/command/stratagem/assault는 현 제한 계약에 맞지 않는다. 실제 적벽 입력을 정본 그대로 검증해 첫 code/path를 진단하되 한 번의 거절이 나머지 모든 검사 실행을 뜻하지 않는다. 입력 기능을 끄거나 다른 프로필로 대신 승인하지 않는다. 제품 operation 소비 경로가 생기면 지원 밖 요청은 기존 전투를 유지하면서 호출자에 명시 실패를 전달해야 하며 legacy로 암묵 전환하면 안 된다. 이번 조각에는 operation 요청을 받는 진입점 자체를 만들지 않는다.

## 한 세션, 제품 hunk 한 곳

- `scripts/FleetBattle3D.gd`의 `init_game`과 바로 인접한 private 준비/게시 함수만 수정한다. `init_game`이 로컬 후보를 먼저 준비하고, 유효 후보에서만 기존 게시 루틴을 호출한다. 후보 준비: 기존 seed 선택, 프로필 로드/편성 적용, 기존 경고 및 legacy fallback 정책 선택, 전장 확대와 이동/선회 조정, 기존 bench profile_patch, fresh BattleSim, 유비군 초기 direct, roster DTO 준비. 후보의 sim은 별도 인스턴스다. 이 단계는 sim/seed/roster/에러 필드, rig/GameSettings, VM/FX/선택/시계/trace/HUD를 게시하지 않는다. 기존 push_error 진단은 선택한 legacy 결과의 게시 시 한 번 유지한다. 경고를 후보 실패와 혼동하지 않는다.
- 준비 함수는 `{ok:false,error,path}` 또는 완전 후보만 반환한다. 최소 명시 실패는 실제 비어 있거나 roster 배열을 없애는 bench patch 출력(예: profile.clear(), profile.ally를 잘못된 타입으로 교체)이다. 잘못된 입력을 BattleSim 생성/roster map 전에 거절하고 기존 호스트 필드를 그대로 둔다. 이 범위를 일반 profile 스키마 검증으로 확대하지 않는다. 기존 정상 bench patch는 유지한다. 사용자에게 노출되는 기존 입력에는 새 편성/난이도 정책을 만들지 않는다. 측정용 콜백 자체가 호스트에 부작용을 쓰는 경우, RNG 전역 소비, 엔진 예외, GPU/노드 생성 중 장애는 rollback 보증 밖이다.
- 게시 순서: 후보 성공 확인 후 기존 함대 제거/VM·FX 초기화, sim·seed·roster·오류 대입 및 기존 scene 전용 rig/GameSettings 설정, 시계와 UI 상태 초기화, trace.start, 초기 큐 소진, side 0 투영, 기본 그룹/카메라/HUD. 현재 데이터와 경고·카메라·표시 결과를 보존한다. 실패 때는 초기 큐도 기존 큐도 drain하지 않는다. `_restart`가 `_start`로 진행하지 않도록 필요한 경우 바로 그 한 호출 지점의 성공 확인 1 hunk를 허용한다. 프로덕션 UI의 실패 주입은 노출되지 않는 측정 patch에 한정하므로 UI caller는 이번에 수정하지 않는다. 현재 `_ready`에서 후보를 못 만드는 경우 기존 세션이 없으므로 즉시 처리 중지하고 진단; 필요 시 바로 그 호출 지점의 성공 확인 1 hunk 허용. `init_game` 반환을 검사하는 호스트 경계 외 테스트 hook/flag/autoload 추가 금지. 대체안이 HUD caller 변경을 요구하면 구현 중 범위 확장하지 말고 계획으로 복귀한다.
- 명령·배치·시간: 제품은 호스트의 TickClock 및 기존 `_sim_acc_clock`, 배치 중 정지와 기존 `BattleSim.issue` 즉시 명령/동틱 순서, `_sync`의 side 0 projection과 `_pump`의 side 0 filtered shared drain, 이벤트 trace/UI, 선택·카메라·HUD를 계속 소유한다. 이번엔 이 루틴을 건드리지 않는다. future operation backend에는 private owner의 step/command/event를 해당 책임에 매핑하고 초기 UI 데이터와 Victory 결산을 검증한 뒤에만 연결한다. UI/scene은 메인 스레드, WorldMap legacy worker/join과 BattleOutcome 및 CLI worker/replay는 미변경.

## 5-a 검사와 정본

정본 엔진 `C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe` 4.7.2.stable.official.ed1daf0bf SHA c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643, 클래스 캐시 SHA 0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1. 엔진/캐시/closure 불일치 결과는 비정본. editor/import 금지. V3 5조각의 경로 격리 교훈을 적용해 증거 폴더 안에 실제 res:// 상대 경로를 보존한 전후 native headless 프로젝트를 완전 복제·동결하고 테스트마다 사용자 데이터 분리. 사전 canonical launcher, probe, 리소스 해시, 경로 guard, APPDATA 환경, 각 exit/timeout/stdout/stderr/result SHA 및 diff를 고정한다. 기존 제품 클래스의 res:// 경로를 런타임 확인하며 기존 전투/적벽 리소스를 stub으로 바꾸지 않는다.

전 4 / 후 5 프로세스: `product-host-common.gd`, `tests/battle_flow.gd`, `tests/world_link.gd` (clean와 returning 각각 1개), 사후만 `product-host-atomic.gd`. `--headless --path <frozen-before-or-after> --script <res://script>`. WorldLink clean의 기존 서막 line 239 실패를 정확히 재현하면 알려진 실패 별도 기록; returning은 고정 유저 파일 SHA로 양쪽 성공 요구. 다른 실패/스크립트 에러/timeout/누락 marker는 새 실패. 시간 예산을 첫 launch 전 고정하며 사례 분모와 프로세스 분모를 섞지 않는다.

공통 8행. 아래 열거한 각 행의 판정 한 개와 실제 세부 단언수를 로그에 독립 기록한다. 편집 전 저장한 행별 native 관측값이 오라클이며, 구현 코드에서 만든 기대값을 쓰지 않는다.

1. `routed_seed_roster_controls`: 실제 WorldMap 직접 경로, 고정 seed와 네임드 난이도, 초기 상태·양 진영 roster 및 숨은 증원, 직접/위임 지휘·시계 비교.
2. `deck_start_restart`: 실제 서막 skip/자동 편성/출격 후 진행·재시작, sim 교체/VM 초기화·선택/카메라/HUD/trace 경계 확인.
3. `placement_clock`: 수동 배치 중 0틱, tick 0 위치/방향 명령, 확정 및 10Hz 진행 비교.
4. `same_tick_commands_events`: 실제 issue 2개, 동틱 기록 순서, 다음 투영과 filtered UI 사건/trace, 두 번째 drain 공백 비교.
5. `invalid_org_legacy_preview`: 기존 오류 문구·자동 편성 preview, 출격 차단과 편성 복구 경로.
6. `legacy_profile_fallback`: 의도적으로 없는 legacy profile 경로의 기존 표시 진단과 POC preview, operation과 분리.
7. `direct_outcome_once`: 실제 종료 후 기존 결산 카드/WorldLink 1회 인계. 빠른 종료가 강제 주입이면 자연 종료로 세지 않는다.
8. `actual_profile_operation_rejection`: 실제 적벽 편성·튜닝과 본편 규칙이 남은 프로필에 제한 요청을 건 테스트 진단의 첫 거절 code/path; 적벽 제품 프로필 변경 없음과 현재 제품 진입점 부재 확인. 해당 진단은 테스트 검증으로만 분류.

사후 원자성 3행: `reject_clear_profile`, `reject_wrong_roster_type`, `recover_publish_once`. 첫 두 행은 실제 제품 `init_game` 호출로 실패의 error/path와 sim identity/fingerprint, tick/두 clock 객체 및 누산, VM 및 FleetView identity, 그룹·선택·inspect/marker/drag/배치, HUD/FX, 카메라, 설정 및 trace 상태 불변을 대조한다. 미회수 사건을 미리 심어 실패 후 독립 native 통제 인스턴스의 순서/내용과 같고 다음 drain이 공백인지 확인한다. 두 거절은 기존 세션마다 다른 초기 조건에서 실행한다. 마지막 행은 정상 원문 profile로 다시 출격하여 기존 경계의 한 번 게시·정상 초기화와 이전 큐/선택/trace 혼입 없음을 독립 native 정상 초기화와 대조한다. 전 공통 사례 모두 실제 제품 호스트에서 구동하고 진단/강제 상태는 명시. 시간·객체 주소는 데이터 동일성에 포함하지 않으며 identity는 동일 프로세스 안에서만 비교한다.

## 보존과 심사

`baseline.json` 전수: tracked 2,453 + nonignored untracked 16,912, 읽기 오류/중간 변경/목록 drift 0. 새 증거 폴더 자체 및 gitignore 대상은 제외하고 classcache와 엔진은 별도 동결. 원자 스냅숏은 아니다. branch codex/feature-i01b-not_remove, HEAD fb660cea69207fd332e26128643007694910a253, stage 변경 없음, index SHA 09ac9b489ae38de5bdcb1ce75e1689c6a4bb8e86d3b4a7ed99ee3db2928f6afd. P03 최신 detection-expiry 계획/실행과 기타 tmp/p03-* 915경로가 관측됐으며 소유 미확인 병행 경로다. P03 또는 다른 신규/변화는 시간·경로·bytes/SHA로 분리하고 수정·삭제·귀속하지 않는다. 실행 입력이나 허용 제품 hunk와 충돌/원인 불명일 때 해당 게이트를 보류한다. 편집 직전/실행 전후/마감 전 전수 재관측, staged/index 비교와 허용 hunk 역치환, 기존 전체 diff-check 진단 별도 분리. 이전 문서/ZIP, UID/import 및 제품 데이터 쓰기 금지. 현재 checkout/branch 유지, worktree/commit/push/HTML/browser 금지.

최대 K=6, 최초 실행도 포함한다. 모든 시도의 분모, 실측 결과, 원인 및 변경 입력을 보존한다. 실패 분모 변경 또는 제품 범위 확대 전 독립 계획 재심. 독립 비-Astra 계획 승인 전 구현하지 않는다. 구현자와 다른 비-Astra 모델의 5-b는 사전 산출물·사후 비교·host 실패 반례·보존을 독립 판정한다. 실제 모델/세션/에이전트와 요청 모델을 구분하고 확인 불가는 명시한다. 5-b 이후 별도 마감의 허용 공유 문서 hunk만 정하고 독립 마감을 받는다. 사용량 제한은 즉시 상위 보고·중단하고 반복하지 않는다. 제품 operation host 활성화/적벽 프로필 지원/WorldMap operation 결산·취소/제품 replay, 수동 GUI/Android/성능은 미인수다.
