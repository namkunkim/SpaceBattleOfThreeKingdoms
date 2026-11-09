# P02 다섯 번째 조각 — WorldMap 결산 스레드 경계 선행 작업

2026-11-08. 계획 심사 대기. 실제 operation 제품 연결 미완료. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

## 현 제품 경로와 범위

- WorldMapScreen.make_brief/_start_resolve/_process/_cancel_resolve/_exit_tree → BattleBrief.profile(Organization.load_auto) → AutoResolver.start/poll/cancel → BattleOutcome.from_sim → WorldMapScreen._show_result. 화면은 기존 clock_s/limit_s/army_bp/progress를 사용한다. 직접 경로는 WorldLink.go_battle → FleetBattle3D → 종료 후 back_to_world(BattleOutcome.from_sim) → take_outcome 1회다. run_blocking은 자연 종료나 기존 1800초 상한에서 동일 결산을 만든다.
- 제품 입력은 BattleBrief의 네 실제 적벽 난이도, 직접/자동 모드, seed와 표식 메타, 직접 편성의 사본이다. 기본 정의는 data/profiles/red_cliffs_rt.json, 데이터 변환은 ScenarioProfile.load_profile/build와 Organization.load_auto/apply다. FleetBattle3D는 enlarge_field/tune_for_play 및 profile_patch, 유비군 direct와 나머지 기존 지휘를 적용한다. AutoResolver는 set_manual_all(false)와 10Hz 시계를 쓴다.
- 제한 adapter는 fresh runtime-ready identity만 받는다. 제품 시나리오, M7 AI, 변형 rules 및 M3+ morale/victory/command/stratagem/assault가 범위 밖이다. 실제 적벽 프로필을 그대로 넣은 진단에서 첫 거절 코드/경로를 기록한다. 모든 모듈 검사가 독립적으로 실행됐다고 해석하지 않는다. 기존 명시 실패를 보존한다. 프로필·편성·정책·Victory를 제거하거나 POC/CLI fixture를 제품 입력으로 대체하지 않는다.
- FleetBattle3D.init_game은 함대·VM·FX부터 초기화한다. 향후 operation 교체는 별도 후보를 준비·검증하고 나서만 게시해야 한다. 기존 플레이/시계 누산·controls, 배치와 issue/queue·동틱 순서, side 0 projection와 filtered event shared drain, 선택·카메라·HUD·trace를 검증하는 후속 제품 작업이다. 현재 조각은 init_game 또는 해당 상태에 쓰지 않는다. WorldMap operation 모드/입력의 선택·provenance, 진행 계약, 상한/취소/에러 처리 UI, 결과 게시, 원자적 화면 전환, 제품 replay 및 지원 프로필 확장은 별도다.

## 구현 후보

- scripts/world/battle_outcome.gd의 from_sim 안에서 현재 읽는 sim facts만 뽑는 정적 snapshot 함수와, 해당 신뢰된 내부 facts와 brief로 BattleOutcome을 만드는 정적 함수를 분리한다. facts는 st.win/end_reason/clock_s/result의 깊은 사본과 fingerprint만 가진다. Object·sim·brief 참조를 넘기지 않는다. 기존 from_sim은 둘을 이어 기존 직접 지휘와 동기 호출을 유지한다. brief seed/mode/difficulty는 현재와 같은 소비 시점과 null 기본값으로 읽는다. grade, loss, 종류, 엔딩, 후일담, to_dict/from_dict의 정책과 공개 표현은 그대로다. 내부 facts는 외부 JSON 형식이나 operation 입력이 아니다.
- scripts/world/auto_resolver.gd의 legacy Thread.start callable만 교체한다. 같은 _loop를 worker에서 실행하고 미취소 시 facts를 Thread 반환값으로 보낸다. poll은 기존 is_alive 이후 wait_to_finish의 반환값으로 main에서 결산을 구성한다. cancel은 기존 join 후 반환 폐기, 취소 시 outcome 미게시. 기존 공개 sim·brief 수명, _clock_s/_bp 진행 업데이트, tick 종료 조건, _cancel 정책 및 run_blocking 호출 경계를 유지한다. 기존 operation worker 메서드와 상태는 동결한다. 기존 Thread.start OS 실패, 동시 호출 정책, 기존 진행 필드 동기화는 여기서 재설계하지 않는다. 지원밖 입력 또는 실패 시 이 조각이 기존 세션 교체/화면 게시를 유발하는 경로는 없다.
- 현 제한 owner.summary는 Victory result가 없고 제품 결산을 지원하지 않는다. 앞으로 적벽 모듈 지원 및 owner의 실제 결산 facts 투영이 필요하다. sim 참조 없이 제품 결산을 구성하는 기존 호출 경계만 이번에 수용할 수 있다.

## 판정과 보존

- 변경 전 원본 파일 SHA와 원문 사본, 본 조각 외부 전체 경로 현재 바이트/SHA를 기준으로 삼는다. baseline.json의 12,281개는 tracked 2,453 및 nonignored untracked 9,828이다. 결측/읽는 중 변경/목록 drift 0. branch codex/feature-i01b-not_remove, HEAD fb660cea69207fd332e26128643007694910a253, staged raw 및 index 파일 bytes/SHA 별도. 증거 폴더 제외. 동시 작업 디렉터리 전체의 원자 스냅샷을 뜻하지 않는다. 편집 직전, 실행 전후, 마감 전 재해시. P03 경로 포함 전수 차이는 출처와 시점을 기록하고 겹침/불명 차이는 보류한다. 원본 checkout 유지, 기존 변경 revert·브랜치/worktree 변경·commit/push·HTML/browser 금지.
- 허용 hunk는 BattleOutcome.from_sim 교체와 새 facts 추출/결산 함수, AutoResolver.start의 legacy callable 및 poll의 join 반환 전달, legacy worker callable 한 개다. 전체 기존 파일 바이트는 역치환해 baseline과 일치 확인한다. 테스트 runner/오라클/로그만 새 증거 폴더에 둔다. UID, import, 이전 문서·ZIP·P03 갱신 금지. 기록 문서는 5-b 후 별도 허용 hunk와 전수 동결로만 갱신한다.
- 정본 엔진 및 .godot/global_script_class_cache.cfg 실제 SHA는 baseline.json, 버전은 engine-version.txt. 동일 엔진·캐시·원본 res:// 경로 확인, editor/import 실행 금지. 엔진 또는 클래스 캐시 drift가 난 실행은 비정본. 필요하면 기존 리소스 closure를 완전 동결한 격리 프로젝트에서 경로 해석을 확인한다. 기존 suite가 파일을 쓰는 경우 원본 경로 쓰기 전에 격리한다.
- 5-a 프로세스 분모는 단계마다 4개다. (1) 증거 폴더의 product-outcome probe, (2) tests/world_link.gd, (3) tests/p02_worker_adapter.gd, (4) tests/p02_headless_adapter.gd. 각 headless --path 원본 --script 또는 검토된 리소스 격리 경로로 사전 및 사후 실행하고 로그·exit·timeout·실제 명령·입력 SHA를 보관한다. 사례별 프로세스 분모와 probe 내 사례 분모를 합치지 않는다. 기존 테스트 단언 수는 로그 실측으로 별도 기록하며 이전 분모를 소급하지 않는다.
- Probe 사례 10행. ① 실제 적벽 BattleBrief 입문 seed 11 threaded 자연 종료 ② 동일 blocking ③ 실제 표준 seed 777 routed 직접 승리의 결산(BattleSim native _end 주입은 테스트에서만) ④ 실제 threaded 취소와 join 후 비게시 ⑤ 실제 표준 적벽 profile 지원 밖 code/path ⑥ POC 빈 result/null brief ⑦ 제한 패배·time_limit의 기존 fallback(실제 AutoResolver 최대 틱을 강제로 기다리는 사례와 구분) ⑧ 제한 승리 result의 loss/grade/후일담 ⑨ 초기 미종료에서 결산 호출 시 기존 fallback ⑩ 변경 후 facts 입력 격리·후처리 사본 오염 검사(사전에는 API 부재로 미실행, 사전 공통 9행/사후 10행). ①~③·⑥~⑨ 각 결과의 to_dict 및 ending_text/line_text를 편집 전 원본에서 고정해 전필드 대조한다. ④ 취소/종료 경합에서 취소가 먼저 소비된 경우 결과 비게시와 poll false를 검증한다. ⑤ profile 원문 사본 SHA와 거부 code/path를 대조한다. ⑦/⑨는 시간 상한/빈 결산 변환 대조용으로 기존 run_blocking의 1800초 도달을 주장하지 않는다. 기존 WorldLink는 제품 씬의 라우팅·결과카드, worker/blocking 비교, 취소를 별도로 검증한다.
- K6 상한을 시도 전 고정한다. 최초 정본 및 재시도마다 분모·누락/실패·환경 오염을 기록하며 무조건 재실행하거나 앞선 실패를 지우지 않는다. 새 실패가 나오면 분모를 변경하기 전 독립 재심을 받는다. git diff --check 기존 진단과 소유 hunk의 별도 검사, P03/원본 SHA 보존을 증거로 남긴다.
- 5-b는 구현 시작 전 이 계획을 별도 비-Astra 리뷰어가 심사한다. 이후 구현자와 다른 비-Astra 모델이 독립 재검산/반례 주입/실행 증거 및 마감 검토를 맡는다. 실제 session id·agent 경로·모델/검증 근거를 기록한다. 사용량 제한 발생 즉시 상위에 보고하고 그 작업을 멈춘다.
