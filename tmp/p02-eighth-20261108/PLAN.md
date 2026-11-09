# P02 여덟째 조각 계획 — 두 제품 소비자의 공통 적벽 초기화 입력

2026-11-08 KST. 독립 계획 판정 전에는 제품 수정과 실행 검증을 시작하지 않는다. P02/I01/I01b/A04~A06 NOT_READY, 외부 저장 schema UNCLASSIFIED.

## 0~1 맥락과 선택

CLAUDE.md, 워크플로우-플레이북.md, battle-core/SESSION-HANDOFF.md, P02 진행 체크리스트, 일곱째 조각 PLAN-v5 및 독립 계획·5-b·마감, P03 최신 정적 추적과 병행 증원 계획 판정을 참조했다. 루트·상위 및 core/scripts/tests/docs 내 AGENTS.md 검색 결과 없음. 브랜치와 checkout 유지. worktree/commit/push/HTML/browser 금지. P03은 별도 변경이 진행 중이며 private owner와 service state는 읽기 전용으로 취급한다.

FleetBattle3D._prepare_game의 native 생성은 _publish_game과 분리되었다. WorldMap은 world_map_screen.gd의 _finish_sortie→_start_resolve→AutoResolver.start→_prepare를 사용한다. 두 소비자는 같은 적벽 데이터를 쓰되 직접 경로는 사용자 편성/전장 확대/이동·선회 배율, 유비 전대 direct를 사용하고 자동 경로는 Brief 자동 편성의 전장 및 아군 delegate를 사용한다. 난이도, RNG seed 및 양 모드의 차이는 기존 제품 동작이다.

- 전체 적벽 private-owner 연결은 적벽 scenario/reinf/AI와 morale/victory/command/stratagem/assault 거절을 해소해야 한다. 실제 UI의 place/delegate/posture, raw sim 규칙·함대 참조, 시계·양측 투영과 사건 및 결과도 함께 다뤄야 한다. P03 checkpoint 범위와 충돌한다.
- 제한 프로필 opt-in은 실제 적벽 연결을 증명할 수 없다. 적벽 기능 제거 또는 기존 엔진으로 조용히 재시도하는 설계는 채택하지 않는다.
- 선택한 전제는 두 제품 소비자가 실제 준비하는 native BattleSim의 초기화 계약을 공통 어댑터에 둔다. 실제 적벽 소비자가 공통 초기화 진입점을 통과하는 것이 이번 진전이다. 제한 owner factory의 제품 연결, product command/event adapter, WorldMap operation worker/outcome, replay, 저장/재개, 전체 P02 수용은 이후 과제다. 새 CLI와 제품 모드 선택은 범위 밖이다.

## 2 인수 체크리스트

- [ ] 기존 adapter에 명시적으로 구분되는 제품 내부 native 초기화 진입점 하나를 제공한다. 기존 제한 format/normalize/create 및 worker/replay 계약은 그대로 둔다. 입력은 효과 적용이 끝난 프로필 사전, 원본 seed int, 고정 10Hz, 변환·초기 지휘 선택의 고정 ID를 포함한다. 네이티브 준비 경계는 사본을 소유한다. 프로필 효과를 다시 적용하거나 적벽 모듈·키·좌표를 삭제하지 않는다. 불명 ID·잘못된 top-level 타입·hz·누락/비배열 roster는 field별 오류 사전으로 명시 거부한다. 기존 seed 범위를 축소하지 않는다. 제품 내부 입력 계약은 임의 JSON·제품 save·외부 profile 검증을 의미하지 않는다.
- [ ] direct/auto 생성 지점 둘 다 같은 진입점의 성공 후보를 실제 소비한다. 기존 source→effective 변환은 caller에서 유지하고 ID로 구분한다. direct 시나리오/POC, 벤치 patch 및 기존 명시적인 load fallback 정책을 보존한다. direct의 후속 편성·UI 정책과 auto의 기존 Brief 검증 및 빈 프로필 오류를 유지한다. 공통 준비 실패 이후 native 생성으로 재시도하지 않는다. 초기 지휘는 기존 sim 생성 이후의 정책을 그대로 호출한다. auto의 set_manual_all(false)는 아군에만 적용되며 적군은 native 기본값을 유지한다. 모드별 전장 크기, 배율 및 증원 배치 시각을 같게 만들지 않는다.
- [ ] 어댑터 오류는 direct 후보 반환 경계와 auto worker start 전 경계에서 중단된다. direct active sim·org·시계·선택·카메라·trace·사건 큐와 최초 실패 복귀를 관측한다. auto 실패에서 thread 시작·outcome 게시 0, browse 복귀 및 사용자 재시도 가능을 관측한다. 성공 후 UI 게시 중 임의 엔진 예외·롤백은 기존 문제이며 이 조각이 보장하는 경계는 공통 준비 거절까지다.
- [ ] native 진행과 제품 UI/worker 경계를 유지한다. direct TickClock 및 BattleSim.step, 배치/명령 순서, side0 투영과 drain, 카메라·선택·trace의 기존 소유권을 비교한다. auto는 기존 start/loop/취소/join/결산 소비 순서를 유지하고 Worker owner 인수로 집계하지 않는다. 현 auto native sim 준비는 메인에서 이뤄지므로 worker 내부 새 owner 생성이라고 주장하지 않는다. 결정된 terminal outcome만 기존대로 join 뒤 게시한다.
- [ ] 허용 코드 경로·hunk는 core/battle/operation_runtime_adapter.gd의 제품 준비 진입점/상수와 scripts/FleetBattle3D.gd._prepare_game의 native 생성/초기 지휘 대체, scripts/world/auto_resolver.gd._prepare의 preload 재사용 및 native 생성/초기 지휘 대체에 한정한다. 신규 검증 프로브와 기록은 이 증거 디렉터리 내부만 허용한다. 공유 문서 갱신은 구현/독립 검증 후 독립 마감용 개별 hunk 승인 및 보존 감사에서만 허용한다.

## 3~5 실행과 판정

독립 계획 심사 후 구현 담당자가 K1 실행 전에 원본과 예정 비교 행의 정확한 입력/기대값 및 명령을 동결한다. 구현자가 self-grade하지 않는다. 5-a 통과 이후 독립 5-b와 별도 마감을 요구한다.

5-a 고정 기본 분모 22행. 아래 1~8과 16~22는 before/after 각 15행, 9~15는 after 7행이다. 엔진 프로세스 수와 단언 수는 별도로 집계한다. 추가 보강은 분모와 섞지 않는다.

1~4. 네 제품 난이도 각 1행. 고정 Brief seed에서 direct와 auto를 각 원본 caller/독립 native 생성 및 변경 제품과 비교한다. source/profile JSON과 변환 계산의 전장 크기·배치 좌표·전대 ID·편성·증원·modules와 seed/10Hz/controls, 초기 및 고정 진행 시점 fingerprint를 비교한다.
5. direct 확정 사용자 편성과 초기 배치, 같은 틱 제품 배치→명령→진행, 다음 tick 사건/투영·카메라/선택·trace를 독립 native 기준 및 전후로 비교한다.
6. direct POC(테스트 전용), 7. direct 알려진 편성 fallback, 8. direct bench patch 성공. 고정 RNG init_game 전후를 비교하고 randomize 최초 실행을 bitwise 증거로 섞지 않는다.
9~13. 진입점 잘못된 ID, hz, seed 타입, roster 누락, roster 비배열 각 1행. 정확 오류·경로와 생성 실패를 단언한다. 성공 프로필을 바꿔치기하거나 native 생성 fallback 하는 경우 검증 실패.
14. 실제 direct active 후보에서 잘못된 roster patch로 거절 및 재시작, 15. 실제 auto 준비 실패/재시도. 15의 공통 어댑터 거절 주입이 자연 제품 입력으로 만들 수 없다면 제품 로컬 복제에서 프로필 반환만 변이한 분리 탐침으로 표시하고 일반 사용자 입력으로 보고하지 않는다. 준비 실패 전후 동일 객체·남은 명령 및 사건·후속 진행을 비교한다.
16. 실제 routed direct OS 마우스 출격/배치, 17. 실제 routed direct OS 키보드 입력 및 재시작/천하 복귀. 각 네이티브 렌더 이미지와 focus/input 증거 보존. 기존 GUI 기록은 역사 근거이고 새 동결 쌍의 실행이 필요하다.
18. 실제 WorldMap 자동 해결 버튼→완료, 19. 자동 해결 버튼→취소. 제품 씬 viewport 입력은 허용하고 OS 입력과 구분한다. same resolver, join, terminal fingerprint/outcome 1회, UI 결산/결산 없음, 브라우즈 복귀, 재클릭/반복 poll을 검사한다.
20. 제한 adapter/worker/replay/viewer와 I01b private/service/active replace suite 그룹. 21. 기존 BattleFlow 및 AutoResolve 그룹. 22. WorldLink clean/returning 분리. clean-user 서막 기존 실패는 현재 전후 양쪽 같은 실패가 재현된 경우만 기존 편차로 남긴다. 각 그룹 안 모든 명령과 기대 exit를 명명해 누락을 검사한다.

독립 oracle은 변경 어댑터를 거치지 않는다. 동결 원본 코드·실제 제품 경로의 고정 Brief/native 호출로 전후 차이를 확인하며 초기 10Hz/clock, faction→control, profile 난이도 및 world transform, 주요 모듈 활성·증원 타이밍·명령 시점은 동결 데이터와 기존 공식에서 별도 계산한다. 전후 summary 일치만으로 event 순서·공급 완료나 모든 적벽 규칙을 증명하지 않는다. 원문 명령/사건·투영·outcome, exit/timeout, 과정 시점 및 GUI 입력 유형을 남긴다.

K=6. 동결 이후 묶음 실행 또는 입력 변동으로 보류된 시도도 1회로 기록하고 재동결로 리셋하지 않는다. 실패 시 해당 조각만 수정하고 구현 5-b 반려 시 스펙 단계로 돌아간다. 사용량 제한 첫 관측 즉시 보고 및 중단한다. 실제 planner/구현/심사 모델·turn evidence는 각각 로컬 메타데이터로 기록하며 요청/추정 모델 표기를 실제 모델로 쓰지 않는다. Astra 사용 금지.

## 동결 및 P03 보존

- baseline.json은 처음 순차 관측이며 P03 신규 리뷰 경로 1개와 long-path 누락 위험을 드러냈다. longpaths 임시 git 설정을 적용한 후속 두 관측으로 전체 tracked/nonignored untracked path/byte/SHA와 index/branch/HEAD 차이를 분리한다. 이 폴더만 스냅샷 순환에서 제외하고 기존 증거는 읽기만 한다.
- 실행 전에는 독립 evidence 폴더에 쌍을 복제한다. 현재 작업 트리의 고유 프로젝트 상대 경로를 유지하고 재수집한 실제 실행 의존 입력(프로젝트, 코드·UID, 시나리오·프로필·데이터, native assets/import/class cache/관련 엔진 캐시, probes, runner, engine console 및 본체)과 원본/변경 파일, canonical guard, source 매핑을 path·bytes·SHA로 동결한다. 전후·마감 시 재검사한다. 본체/콘솔 엔진 버전과 SHA가 모두 필요하다. 사용자 디렉터리는 clean/returning과 시도별로 분리한다.
- 공통 owner/service/adapter, native class source, class-cache·설정의 승인된 hunk 밖 SHA 불일치 또는 실행 입력 미귀속 drift는 실행 전 보류, 실행 중 확인 시 그 묶음 무효·보존 후 재동결한다. P03 증거와 대형 비실행 경로는 따로 관측하고 변경을 되돌리지 않는다. path 위치로 P03 관련임은 분류할 수 있으나 수정 주체나 두 관측 사이 안정성을 확정하지 않는다. 현재 P03 정적 추적은 독립 5-b 미완료이며 실제 제품 resume 연결이 없다.
