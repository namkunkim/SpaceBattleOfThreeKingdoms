# I01b-P2c 계획 — 제한 프로필 private runtime 준비

2026-11-01 KST / 0~3 계획 / **독립 계획 수용 대기, 코드 미작성** / 코드 K6, 문서 K3.

## 0. 맥락과 동결

원본 `C:/WorkSpace/SpaceBattleOfThreeKingdoms`, branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 비어 있음을 실제 확인했다. 새 worktree/branch 전환/커밋/푸시는 금지한다. 플레이북, CLAUDE, SESSION-HANDOFF, P2b 결과·체크리스트·독립 심사, H2, D04 ST01~18, I01 readiness K06~08과 실제 생성자/step/issue/queue를 읽었다. 적용 AGENTS.md는 루트·상위 경로와 저장소 검색에서 발견하지 못했다. 옛 SESSION-HANDOFF의 문서전용 역할은 현재 명시된 P2c 실행 지시로 대체한다.

`before.json`은 현재 dirty/untracked 파일 3660개를 SHA256 동결한다. 이 신규 증거폴더만 제외했다. 과거 P2b 3594는 다른 시점의 분모이며 동일 분모라고 주장하지 않는다. HTML 작업은 사용자 지시로 중지됐고 HTML/통합 MD 체크리스트는 읽기만 한다. 동결 후 다른 담당의 변경이 있으면 파일·SHA·소유자를 별도 기록하며 묵인하지 않는다. 기존 P2c PLAN/코드/정식 체크리스트는 발견하지 못했다. P2b helper/test는 기존 미커밋 완성품으로 보존한다.

동결 보정: 첫 기본 Git 출력은 quoted 비ASCII경로를 누락하여3543개였다. 불완전 기록을 `before-incomplete-quoted-paths.json`에 보존하고 `git -c core.quotepath=false status`로 다시 수집한 현재3660개 모두 존재·SHA를 확인했다. 신규 전용 체크리스트도 자기 소유이므로 baseline에서 제외했다. 보정 전 기존 코드 수정은 없었다. 후속 감사 기준은 보정된 before.json의 timestamp와 경로 집합이다.

## 1. 의도와 제한

P2b가 호출자에게 남긴 비대상 상태 복원을 **독립 fresh target에 실제 적용하는 생산 구성요소**로 채운다. 최소 범위는 POC 또는 Salvo/terrain/Detection/Supply만 활성인 제한 프로필이다. 시나리오 Morale/Victory/CommanderAI/DecisionBoard/Chain/Command/Assault/Skills 활성은 명명 오류로 거부한다. 적벽 캠페인 전체 지원을 선언하지 않는다. H2-02의 상태+후속 입력 방향을 따르되 외부 save 파일/schema/migration/게임 정책 수치를 만들지 않는다.

범위 축소: profile.reinf는 빈 배열만 지원한다. 비어 있지 않으면 생성자 전 `unsupported_reinforcement`로 거부한다. packet의 `_reinf_def`도 빈 배열이어야 한다. 그러므로 이번 증거는 실제 증원 예약/생성/중복방지를 포함하지 않으며 ST16 및 원 작전 전체 NOT_READY를 유지한다.

완료 경계를 검증할 수 없는 외부 BattleSim을 인자로 받아 boolean만 믿는 API는 만들지 않는다. 신규 owner가 복사한 입력으로 private BattleSim을 만들고, 동기식 issue/queue/step/drain 작업을 owner 경로로만 수행한다. 가변 sim/fleet/module 참조를 정상 public 결과로 내보내지 않는다. GDScript의 underscore는 보안 격리가 아니므로 이 계약은 정상 API 호출자의 소유권 계약이며 악의적 reflection/thread 접근 보장은 아니다. 기존 host가 가진 임의 sim을 입양하는 기능은 이번에 없다.

## 2. 구성요소·필드 책임과 인수 기준

신규 `core/battle/operation_private_state.gd` 한 파일에 owner와 내부 packet/검증/준비 기능을 둔다. 계획 API는 `create(profile, seed, hz, initial_controls)`, `issue(command)`, `queue(command)`, `advance()`, `drain_events()`, `observe()`, `capture_completed()`, 정적 `prepare(packet)`다. 생성/복원 성공은 owner만 반환하며 실패는 명명 오류, target은 노출하지 않는다. observe는 detached typed 자료다. packet은 외부 wire format이 아닌 국소 typed in-memory API다.

| 상태 | 책임 | 검사/복원 순서 |
|---|---|---|
| 원본 profile 전체, seed/hz, 초기 direct/delegate 배정 | 입력 깊은 사본 보관. 빈 profile의 암묵 POC fallback 금지. POC는 명시한 기존 PocSetup.profile로 입력 | 내부 build 입력의 타입/필수 구조/지원 모듈/유한값을 생성자 전 검사. 동일 규칙 내용과 초기 제어를 생성자 완료 후 확인 |
| BattleState 모든 script 변수 | fleets/missiles/swarms/ID cache를 제외한 tick/clock_ms/cp/ecp/나머지/손실/증원/AI timer/ID/진형/event counter/종료/result/군사기 등 정확 보존 | 필드명 allowlist와 실제 script 변수 집합을 대조해 새 필드 누락 시 거부. tick*dt 재계산 금지 |
| FleetState 모든 script 변수 | P2b sup_*10만 helper에 위임하고 나머지 전부 정확 보존. ammo/wch/wmax/next_fire/stages/heat/energy remainder/hit_tick/healed_*/supplied/이동/그룹/타이머/효과 포함 | 새 FleetState 객체를 packet 순서대로 만들고 허용 필드·타입·유한값·ID 참조 검증 뒤 적용. 객체를 packet에 넣지 않음. 표시 필드도 우선 정확 보존하고 임의 파생 삭제 안 함 |
| BattleState.Missile/Swarm 모든 script 변수 | 진행 중 공격 ID/src/target/수명/pts/striking까지 정확 복원 | 기존 내부 클래스 신규 객체, typed 배열로 복원. source 객체 공유 금지. roster에 남는 dead 참조는 코어의 실제 의미를 따름 |
| st._idx/_idx_n | 직렬화하지 않는 객체 참조 cache | fleet 배열 완성 후 clear/-1하여 재구성. by_id가 새 target 객체를 반환하는지 검사 |
| sim.command_log/_queue/_events | 순서·실제 타입·내용 깊은 사본 보존 | issue 적용/기록/사건 완료를 함께 capture. queue는 미적용 상태이며 로드시 실행하지 않음. drain의 이미 소비한 사건을 재발행하지 않음 |
| sim.first_hit_tick/sub_ms/_hold_d2/endless/_reinf_def | 실제 값 정확 보존 | 시간이 일부만 흐른 종료도 보존. debug/effect 상태를 초기화하지 않음 |
| sim.profile_id/R/rs(v/world/scenario/c)/dt/T/rng.profile_id/_ai | constructor 재구성 후 capture 입력/derived와 정확 대조 | PocEnemyAi는 현재 script 상태 없음, RNG는 profile seed 기반 stateless. 향후 script 필드 추가는 coverage guard로 실패. profile/config 불일치 fallback 금지 |
| Salvo.C/sim/terr/terrain_class, terrain.zones | config·참조는 target 생성자 재결합, terrain_class/zones는 재구성 대조 | 실제 생성 순서와 config binding 확인. 소스 모듈 참조를 옮기지 않음. terrain 객체의 영역 정렬/값 대조 |
| Detection/Supply | P2b capture_partial/restore_into_prepared_target 재사용 | 비대상 state/fleet/공격/명령/사건 복원 → P2b preflight/적용 → 전체 관측 대조. 생성자를 slice 적용 뒤 재호출 금지 |
| 다른 활성 모듈/알 수 없는 script 상태 | UNSUPPORTED 명시 거부 | 생성 전 profile 의도와 생성 후 실제 layout 양쪽 검사. disabled와 미제작을 동일 성공으로 취급하지 않음 |

모든 mutable data는 Object/순환/NaN/Infinity를 선행 거부하고 deep copy한다. 정수/float/StringName/Vector2 및 배열·사전 키/삽입 순서를 보존하며 JSON 왕복이나 양자화된 fingerprint로 충분성을 판단하지 않는다. 필드별 최소한의 구조/정확 타입·ID·시간·배열·범위를 preflight한다. 실제 코어가 허용한 stale/dead roster 참조를 신규 정책으로 거부하지 않는다. profile 생성자 선행조건의 허용 범위는 테스트 profile의 실제 구조로 명시하고 임의 Dictionary 전체를 지원한다고 주장하지 않는다.

완료/선행 guard:

- public issue/queue는 허용된 **명령 구조**를 busy나 코어 호출 전에 검사하고 깊은 사본을 만든다. 입력은 정확히 tick:int, side:int(0/1), ids:Array[int], kind:String, target_id:int, point:유한 Vector2, args:Dictionary 구조다. ids는 음수/중복/비정수를 거부하고 target_id는 -1 또는 비음수 int를 받는다. 없는/죽은 ID나 게임상 불가능 명령은 구조 거부와 구분하여 기존 코어의 논리 rejected 경로를 유지한다.
- public 지원 kind는 stop/move/attack/formation/missile/fighter/volley/def/supply_first/supply_hold로 한정한다. 기본 args는 빈 사전, formation은 정확히 id:String, supply_hold는 정확히 on:bool이다. move의 이번 args도 빈 사전만 지원하며 route/strafe/facing 확장은 명시 거부한다. 알 수 없는 kind/extra args/NaN·Object·순환은 `invalid_command` 또는 `unsupported_command`로 코어 호출 전 실패하고 command_log/events/state/busy가 불변이어야 한다. accepted command의 코어 논리 rejected는 적용/로그/사건이 완료된 정상 경계다.
- queue 호출 후 원본 command/ids/args 변형이 pending에 전달되지 않아야 한다. 저장 packet의 command_log/_queue도 위 구조를 전량 검사하며 pending의 손상된 마지막 명령은 prepare를 거부한다. log의 tick은 실제 적용된 과거 tick, pending tick은 아직 적용되지 않은 입력 값임을 구분하고 복원 중 덮어쓰지 않는다.

- create는 constructor, 초기 controls, 초기 projection 생성 준비와 관측 검증을 모두 끝낸 뒤 owner를 반환한다. 첫 issue/queue/step 전을 local C0 준비 경계로 기록하지만 작전 정의/제품공간/공통 adapter C0 완료는 아니다.
- owner busy guard는 작업 시작 전 세우고 정상 반환 후 해제한다. capture/prepare/공개 작업은 busy 또는 미완성 owner를 거부한다. step 반환 및 즉시 issue 반환은 K07의 완료 경계다. queue는 pending 변경이며 명령 적용 경계로 기록하지 않는다. drain도 상태 변경이라 busy 경로를 통한다.
- 이번에는 전역 command_seq/commit_seq를 발명하지 않는다. command_log와 pending queue를 정확 보존하지만 K05 전역 cursor/원자 운영 commit은 후속 범위다. 기존 host의 직접 mutation이나 외부 불명 경계는 지원하지 않는다.
- prepare는 packet 전체를 먼저 검증하고 private target에 constructor → 비대상 상태 → P2b slice → config/bindings/cache/전체 exact 관측 검증 순서로 진행한다. 마지막 단계 실패에도 기존 owner/source/packet은 불변이며 private target은 반환하지 않는다. 성공한 새 owner 반환만 게시다. 게임 host 교체 원자성은 아직 구현하지 않는다.

## 3. 분해·허용 경로·검증

독립 계획 수용 → helper와 신규 `tests/i01b_private_state.gd` → 5-a → 다른 모델의 독립 5-b → 전용 결과/체크리스트/증거 마감. 소유 경로는 이 두 신규 코드, 이 evidence 폴더, 신규 `I01B-P2C-CHECKLIST-20261101.md`, `I01B-P2C-RESULT-20261101.md`다. 독립 reviewer가 `REVIEW-I01B-P2C-20261101.md`를 소유한다. 기존 BattleSim/기존 검사/P2b helper/HTML/통합 MD 체크리스트/데이터는 수정하지 않는다. UID가 엔진에 의해 새로 생기면 자기 신규 코드의 UID만 소유 목록에 기록한다.

5-a 의미 있는 시험:

1. 기존 P1/P2b 10seed 각각에서 실제 명령·step으로 만든 source owner를 capture하고 **한 번도 source와 같이 전진하지 않은 생성자 직후 fresh target**으로 prepare한다. target을 source와 병행 선진행해 비대상 상태를 맞추는 P2b 방식은 금지한다. 직접 typed 관측을 별도 test oracle로 작성하고 전체 state/fleet/공격/로그/queue/events/config binding을 비교한다. helper의 packet을 자기 oracle로만 쓰지 않는다.
2. 실제 사격·피해/이동/진형·탄약/열/누적나머지/타이머와 missile/swarm 진행이 있는 상태, issue 즉시 적용 후/queue 미적용 후/step 후/drain 전후를 검사한다. seed별로 모든 특징이 우연히 발생한다고 가정하지 않고 개별 사례에 실제 활성 전제 guard를 둔다. pending queue는 준비 직후 미적용이고 다음 step에 단 한 번 적용돼야 한다.
3. P2b 과거 remembered contact 및 보급 진행/완료 후 재고를 실제로 만든다. source와 fresh 복원은 동일 후속 명령 suffix로 탐지 평가·보급 완료·투사체 소멸 또는 공격 적용·타이머 경계를 넘어야 하며 매 step 직접 상태/ordered events를 비교한다. 손상/자원·이벤트·ID도 비교한다. 실제 시간을 tick*100으로 치환하지 않는다.
4. 독립 부정대조는 정상 prepare 이후 외부 필드(ammo/next_fire/hit_tick 또는 projectile age)를 누락/초기화하는 잘못된 경로가 direct state 또는 실제 suffix를 갈라놓는지 확인한다. P2b helper만 fresh에 적용하는 잘못된 경로가 source와 다름도 확인한다. target/source 전체를 동일 packet으로 관측하는 것만으로 독립 oracle라 주장하지 않는다.
5. 마지막 fleet/공격/사건 malformed, 누락/추가 필드, 타입·NaN/순환/Object, profile/config/seed/hz/module mismatch, 중복 ID/해석 불가능 참조, busy·미완성 owner, 활성 미지원 모듈 각각 명명 거부. source와 packet 불변 및 기존 성공 owner 불변을 확인한다. private target 실패 시 반환값에 runtime 없음도 확인한다.
   malformed issue/queue는 로그 추가나 부분변이 전에 거부되고 busy가 남지 않아 다음 정상 호출이 성공해야 한다. 논리 rejected 사건을 내는 정상구조 명령과 다른 결과를 검사한다. pending command alias/손상 packet 및 비어 있지 않은 reinf의 생성 전 거부도 별도 명명 사례다.
6. source/profile/packet/복원 관측의 가변 alias 분리를 양방향 변경으로 확인한다. by_id cache는 prewarmed source와 새 target에서 각각 자기 fleet identity여야 한다. 재준비는 새 owner를 만들 뿐 command/event/자원 효과를 중복 실행하지 않는다.

회귀는 core_rules/data_rules/i01_operation_config/i01b_logical_clock/i01b_service_state/detection_rules/supply_rules 7개. 실제 Godot exit/log/source·입력·엔진 SHA를 기록하고 PASS 문자열뿐 아니라 SCRIPT ERROR/ERROR 및 계획된 사례/거부 수 완결성을 검사한다. ObjectDB/resources 기존 종료 진단은 별도 기록한다. headless import가 필요하면 실행하되 권한/장기 대기는 즉시 root에 보고한다. `git diff --check`, index 비어 있음, before3660경로 보존 및 동시변경 소유를 감사한다.

5-b는 구현자가 아닌 다른 모델이 실제 필드 책임 누락, 지원 profile 생성자 guard, busy/완료 경계, private 준비 순서, 전체 exact oracle의 독립성, 실제 suffix 활성/부정대조, alias/cache 참조, 실패 원자성, 실제 로그·SHA·허용경로 보존을 검토한다. 5-a 코드 재시도 K6를 넘기면 중단 보고, 5-b 반려는 2단계 계획으로 돌아간다.

## 정확한 완료/NOT_READY 경계

성공해도 완료는 **제한 프로필에 대한 private runtime fresh 준비·비대상 복원 구성요소**뿐이다. 캠페인 활성 모듈의 복원, 전체 ST01~18, 운영 command cursor/checkpoint Cn, 외부 저장파일/schema·호환 migration, host/headless/replay 공통 연결·원자 활성 교체, 제품공간/화면/Android/성능/사람플레이는 미완료다. 전체 I01/I01b/A04~A06는 NOT_READY, 외부 save schema는 UNCLASSIFIED를 유지한다.
