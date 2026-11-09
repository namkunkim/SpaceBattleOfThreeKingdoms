# P03 다음 조각 — 같은 틱 명령 절단점 반례

2026-11-07 KST. **독립 계획 심사 대기. 구현/실행 미착수, K6 사용 0.** 조사·구현 gpt-6.1-sol, 독립 심사 gpt-6.1-terra 명시 배정. Astra 제외. [선행 인계](../p03-state-checkpoint-20261105/HANDOFF.md) · [명령 조사](../p03-state-checkpoint-20261105/COMMAND-AUDIT.md) · [상태 조사](../p03-state-checkpoint-20261105/STATE-AUDIT.md)

## 범위와 의존성

가장 작은 조각은 신규 테스트 전용 Godot runner 한 개로 기존 제한 private owner의 완료 호출 사이에서 **같은 틱의 prefix, packet pending, 후속 issue**가 서로 다른 범주임을 실행 증명한다. 경계는 테스트 작성자가 직접 배치한 호출 위치다. seq/cursor API, 신규 replay helper, serializer, 생산 코드 변경, 저장 형식 또는 호환 정책은 추가하지 않는다. H2-02, D04 ST02/ST18·O07, I01 K05~08 및 A06에 대응하는 제한 반례이며 A06 전체 통과가 아니다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.

P03은 이 폴더의 신규 테스트·증거·문서만 쓴다. runner는 root project에서 `--script res://tmp/p03-command-suffix-20261107/command_suffix.gd`로 명시 로드하고 class_name을 등록하지 않는다. 여기에만 .gdignore를 두고 editor/import는 실행하지 않는다. 명시 로드에 실패하면 scope를 넓히거나 cache를 재생성하지 않고 원문 로그를 보존해 계획 심사로 돌아간다. 기존 P03 기록, 공통 helper/OperationPrivateState/BattleSim/adapter/host/replay, tests와 공유 체크리스트의 기존 경로는 읽기 전용이다.

P02 11/07 revision4의 읽기 관측에서 worker attempt2 검증 및 모듈 거부 분석 중이다. P02 계획의 생산/CLI 소유는 `scripts/world/auto_resolver.gd`, `tests/autoresolve.gd`, 전용 worker test/fixture 및 합의된 마감 문서다. P03 runner는 이 경로와 worker 프로세스를 입력으로 쓰지 않는다. 직접 메시지를 보내지 않았으며 상위 소유 변경은 하지 않는다. [P02 계획](../p02-next-20261107/PLAN.md)

시작 branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 빈 상태. [새 동결](dirty-baseline.json)은 dirty/untracked 5162 파일, 누락0, 해시 전후 status bytes 동일이다. 경로/해시 관측이며 원자적 snapshot이 아니다. 선행 3965, P02 7078 분모를 재사용하지 않는다. 최종 단계에서 새 5162를 재해시하고 P02 동시 변경 및 이후 신규 경로를 별도로 열거한다. worktree/branch/commit/push/merge/dirty 폐기/HTML/브라우저/localStorage 작업 금지.

## 입력·시간표

고정 POC 제한 fixture 하나, seed 7/hz 10/reinf=[], 편성 순서 ally1/foe2. 신뢰 rules를 PocSetup에서 분리 복사하고 world 3400×2300, ally (500,500), foe (2600,1500), 각 30척·lv1·p0·flag true. 초기 controls는 명시 `["direct","direct"]`. note는 `Array[int]([7])`, 정수/문자열 키, 순서 고정 probe를 포함하는 plain data다. 제한 create가 이 입력을 거부하거나 timeline precondition이 성립하지 않으면 실패를 공개하고 fixture를 조용히 바꾸지 않는다.

동일 profile/seed의 **원시 BattleSim**을 별도로 생성해 controls를 직접 세팅한다. 이 raw oracle은 packet/prepare/restore를 호출하지 않는다. 양쪽을 먼저 2회 실제 advance하여 noninitial T=2를 확정하고 초기 사건을 drain한다. 아래 각 동기 호출 뒤 raw oracle 및 수기 기대값을 대조한다.

| 순서 | 동작 | 수기 기대값 |
|---|---|---|
| prefix 1 | Q = `move` fleet 1, Vector2(900,500), typed `Array[int]` ids, 입력 tick 77. 동일 Q 두 번 queue | log/event 변화0, pending `[Q,Q]`. 이후 호출자의 Q.ids와 Q.point를 바꿔도 이미 대기된 입력은 그대로다 |
| prefix 2 | S = fleet 1 `stop`, 입력 tick -1을 queue 후 I = fleet 1 `stop`, 입력 tick 88을 issue | pending `[Q,Q,S]`(입력 tick 그대로), log `[I@2]`, 사건 `[say(stop)@2]`. I는 이미 반영됐으며 queue 접수 순서와 log 적용 순서가 다르다 |
| 절단 | capture 완료 직후 checkpoint state/packet/pending/log/events를 exact 저장 | tick2·clock 실제값과 nonempty pending/events를 guard로 요구. tick/로그 길이는 후속 호출을 고르는 입력이 아니다 |
| suffix 1 | B = fleet 1 `move` Vector2(1100,500), 입력 tick 89를 같은 T에서 issue, 이어서 R = 존재하지 않는 양의 id 999의 stop을 issue | log `[I,B,R]@2`, pending 불변, B로 실제 target 이동 상태, R wrapper ok 및 `rejected/no_selection` append. 적용 전 입력 tick과 적용 log tick을 구분 |
| suffix 2 | 첫 advance, drain, 두 번째 advance, drain | 첫 적용 log `[I,B,R,Q,Q,S]` 전부 @2이고 queue 비움. S가 B/Q의 이동 의도를 마지막에 지운다. 첫 drain의 명령 사건 접두는 `stop,move,no_selection,move,move,stop` 순서·정확 payload. 나머지 틱 사건은 raw twin exact. 두 번째 advance에는 Q 재적용/새 명령 기록 없음 |
| 복원 | active가 위 suffix를 실제 소비하여 tick·log·pending이 변경됐다는 guard 뒤 같은 owner에 restore | handle 동일/새 sim identity, checkpoint의 pending/log/미소비 event exact, packet 불변. 기존 drain을 되감는 인메모리 동작 |
| 재실행 | 똑같은 suffix 호출만 반복, Q/Q/S는 재주입하지 않음 | 첫 실행의 모든 단계별 관측과 raw oracle 양쪽에 exact. 두 번째 drain 호출의 빈 결과도 양쪽 동일. 외부 소비자의 exactly-once를 뜻하지 않는다 |

기존 활성 교체의 pending1/advance-only suffix, 투사체·탐지·보급 완료, old bindings/반복 복원 전체 매트릭스를 재실행한 성과로 집계하지 않는다. 신규 신호는 같은 T의 B 손실/ I 재적용, log 길이와 queue 접수의 불일치, **동일 Q의 합법적 반복 두 번**, 비가환 Q/Q/S 순서, wrapper 성공/게임 거부 구별이다.

## 사전등록 인수표

| 이름 | 기대 |
|---|---|
| suffix_01_prefix_pending_applied | 시간표 prefix에서 raw twin 및 수기 log/pending/event, caller alias 분리, T=2·비초기 보장 |
| suffix_02_live_same_tick_suffix | 처음 실제 suffix에서 같은 T의 B/R, queue 적용 순서와 중복 Q 두 번, 실제 이동 의도·시계/실제 advance·사건 exact |
| suffix_03_restore_and_replay_suffix | 같은 handle에 fresh sim, 복원 직후 checkpoint exact, Q/Q/S 재주입 없이 모든 suffix phase에서 첫 실행/raw 비교 |
| suffix_04_reject_tick_and_content_cutters | 수기 동결 applied log로 tick>T가 B/R을 잃고 tick>=T가 I도 잡는다는 반증. 내용 dedup의 Q 1개 손실, 접수/적용 순서 차이를 별도 assertion. 잘못된 cutter를 제품 경로로 구현하지 않음 |
| suffix_05_reject_context_keeps_active | 별도 정상 owner에서 만든 context variant packet을 사용한다. `[]` 대 명시 controls, 같은 값의 untyped note Array, Dictionary key 삽입 순서, 정수/문자열 key 타입 각각 독립 소거 실험. 후보 자체 prepare 성공을 먼저 증명하고 4건 모두 `replacement_context_mismatch`. current handle/sim/busy, 정본 관측/pending/log/events, 대상 packet exact 보존과 다음 정상 suffix 진입 가능. 예외/스레드/host 실패 주장은 없음 |

비교기는 production의 `_same/_context_same`나 packet allowlist를 참조하지 않는다. 먼저 정확 typeof, Dictionary 키 배열의 타입/삽입순서 및 값, Array의 순서와 typed builtin/class/script identity를 재귀 대조한다. Dictionary의 typed metadata를 읽을 수 있으면 독립 관측에도 보존한다. 객체가 들어간 배열은 script/resource identity 및 같은 script property 순서/값을 대조한다. 관측할 core/fleet 필드는 script-property introspection에서 생성하고 _idx 캐시·인스턴스 참조는 값 비교에서 제외하여 별도 handle/sim/binding/ID 검사로 보완한다. 순환 module 참조는 따라가지 않는다. 이벤트와 명령은 형·키 삽입순서를 유지하며 JSON은 수치/진단 기록에만 쓴다. 현재 fixture에서 nonempty typed class/script 배열이 발생하지 않을 수 있으므로 해당 metadata의 비어 있지 않은 동작 범위까지 검증했다고 주장하지 않는다.

## 실행 및 보존 인수

기존 정본 `C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe`의 경로·버전·SHA, `.godot/global_script_class_cache.cfg` SHA(읽기 관측 0eb214eb…ab1), project.godot, 실제 runner/fixture 코드, core/battle 31개와 PocSetup/BundleLayout 및 활성 경로의 preload·FileAccess가 읽는 profile/data 파일의 전이 목록과 SHA를 런 직전·직후 저장한다. class map에 불일치가 있거나 실제 loaded Script `resource_path`가 정본과 다르면 즉시 실패한다. 정본 Script preload 객체와 런타임 sim/st/fleet/활성 모듈 script identity를 별도 검증한다. runner가 global class symbol의 `.resource_path` 직접 접근으로 생긴 기존 파싱 오류를 반복하지 않도록 값으로 받은 Script나 인스턴스 get_script를 쓴다. 캐시/엔진이 바뀌면 실행 증거 무효. 관련 전이 입력과 shared source 변경 시 실행을 멈추고 소유·입력 범위를 검토한다.

새 단계 K6, 최초 실제 headless 검사를 attempt1로 집계한다. 동일 프로세스 내 5개 명명 검사·context 4거부와 실제 assertion 수를 분리한다. 성공은 실제 exit0, 5개 명명 완결, 예상 명명 거부 4 및 정본 guard, 불변 입력, SCRIPT ERROR/ERROR 0이다. WARNING/종료 누수 진단도 따로 집계하고 기존 허용 이력과 구별한다. 이 새 짧은 fixture에서 미설명 진단은 실패다. stdout/stderr, timeout 및 실제 반환 코드, 실행 argv/cwd, fixture/runner와 실제 정본/캐시/엔진 SHA, 커밋 없는 새 파일 diff를 시도마다 덮어쓰지 않는다. 전체 diff-check 기존 33행 exit2와 새 경로 공백 검사 분리. 실패 보완은 해당 조각만 K6까지, 오라클/범위 변경은 재심사, capacity/사용량 제한은 즉시 보고하고 반복 금지.

독립 계획 수용 뒤에만 구현한다. 5-a 통과 뒤 독립 5-b는 같은 틱 오라클·typed 비교·wrong-cut 반례와 원문 출력을 직접 검증한다. 그 뒤 전용 결과/체크리스트/인계·보존 감사/manifest/ZIP/독립 closeout을 남긴다.
