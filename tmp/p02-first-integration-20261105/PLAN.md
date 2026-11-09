# P02 첫 실제 소비자 연결 — 1~3 계획

2026-11-05 KST. v2: R1~R4 보완, 독립 재심 전. 구현 0/K6. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED.

## 0 지침·동결·소유

워크플로우-플레이북.md, CLAUDE.md, SESSION-HANDOFF.md를 먼저 확인했다. C:/AGENTS.md, C:/WorkSpace/AGENTS.md 및 저장소 hidden 포함 rg --files AGENTS 검색에서 적용 파일 없음. 사용자 지시가 과거 main/commit/HTML 지시보다 우선한다. 원본 cwd/branch codex/feature-i01b-not_remove / HEAD fb660cea69207fd332e26128643007694910a253 / index 빈 상태. baseline-files.json의 현재 dirty/untracked **3960경로**를 바이트 크기·SHA256으로 동결했다. 증거 폴더 생성 전에 목록을 고정했으며 baseline-status.txt에는 새 증거 파일이 표시될 수 있다. 원 source35/격리77은 과거 별도 manifest로 최종 재검증하고 현재3960에 합산하지 않는다.

기존3960은 전부 기존 소유자 영역이다. 이번 계획 담당은 tmp/p02-first-integration-20261105/만 작성한다. 모델명은 상속 상태로 실제 이름을 추측하지 않으며 조율자가 확보하는 agent/session 메타를 별도 보관한다. HTML/브라우저/localStorage/editor import/새 worktree/branch전환/commit/push 금지.

필수 정본은 SESSION-REQUIREMENTS-CHECKLIST §6 P02~09/§8, CHECKLIST-OPEN 27~35, ACTIVE-REPLACE RESULT/REVIEW/CHECKLIST/HANDOFF, 이전 PLAN/PLAN-ACCEPT/5B-ACCEPT/CLOSEOUT, P2c RESULT/REVIEW/HANDOFF, I01-ACCEPTANCE-PREREG/I01-READINESS(K01~08/S01~15), H2/D04(ST01~18)이다. 최신 tmp/i01b-checklist-confirmed-20261104의 MD4 갱신은 이번 REVIEW-PLAN.md 별도 확인에서 내용·보존 한정 수용되었다. 과거 ZIP이 이를 포함한다고 주장하지 않는다.

## 1 현 소비자와 반례

현재 라인은 이번 rg/원문 열람으로 확인했다.

| 소비자 | 구축·입력·controls | 시계/명령/사건/게시 | 차이·첫 연결 판단 |
|---|---|---|---|
| scripts/FleetBattle3D.gd init_game169~240 | 기존 vm/fx를 먼저 비움; scenario/organization 실패시 기본편성→POC fallback183~194; enlarge/tune196~201; raw sim204, 유비 direct206~208 | clock 두개211~212; G/vm/selection/camera/trace·backdrop 전체재구축; _process353~390 delta→TickClock→step, update_sim404~417 별도 accumulator; _sync420 projection→vm; _pump437 drain_events_for(0)→trace/UI; issue459~479 배치변환 및 즉시적용 | raw sim만 교체하면 clock/선택/뷰와 실패시 기존 host 보존이 깨짐. 실제 host opt-in은 후속 |
| scripts/world/auto_resolver.gd _prepare27~42 | brief.validate/profile 적벽, raw sim36, all delegate37 | _loop44~50 step, 매50tick events drain·progress; start70~76 main 구축후 worker; poll80~92 join 후 outcome 게시; cancel94~99 join | 제한 owner가 거부하는 적벽 활성모듈이며 동기 owner를 main/worker 공유하면 경합. 현재progress만 공유하는 계약 보존. 첫 조각 제외 |
| tests/autoresolve.gd _run32~73 / play104~118 | 실제 command-line 통계 생성기(파일 첫 주석 실행 예와 JSON summary/baseline 출력), default stock POC raw sim105 | 공개 projection 정책→queue→step→drain 매tick; max1800s, summary/fingerprint. play_rc261~385는 적벽 raw modules와 사건통계를 직접 사용 | UI/스레드 없는 실제 headless 소비자. 기존 play/RC는 그대로 두고 명시 opt-in 분기를 추가하는 가장 작은 실제 연결 |
| core/battle/battle_sim.gd replay183~193 | seed/hz/profile raw new, log 입력 | 현재tick과 같은 연속 log를 queue하고 step/drain; 정렬 안 된 첫 미래항목 뒤 과거명령은 놓칠 수 있음 | 현재 legacy replay 보존; 신규 replay 어댑터 연결과 전체명령cursor는 후속 |
| OperationProfile from_envelope8/build27~89 | host selection/headless/replay header 3봉투를 동일 순수설정 build로 정규화. 결과 scope=i01a_config_fixture_only/runtime deferred | 실제 BattleSim 생성/controls/명령/시계 소유 안 함 | 이를 그대로 private profile로 넣으면 rules/ally/foe 없음. I01a 유효 ≠ runtime readiness. 중복 공간변환/임의 프로필생성 금지 |
| OperationPrivateState create142~163 / command206~221 / advance223 / drain231 / observe243 | canonical guard67, profile_error79; explicit reinf=[]·지원모듈 subset·정확 controls; 첫 projection까지 private 완성 뒤 owner 공개 | deep detach, 동기 busy; observe는 큰 detached 관측, public projection 메서드는 없음. restore325 동일 원입력 atomic, close443 바인딩해제 | raw sim 노출 없이 소비할 공통 수명 경계의 기반. P2b OperationServiceState12/30는 contacts/sup slice만 담당하며 직접 host 연결 금지 |

최소 실패 반례: (1) stock PocSetup.profile에는 reinf가 있어 opt-in으로 조용히 지우면 다른 전투가 된다. (2) 적벽은 morale/victory/cai 등 지원 밖이므로 opt-in시 POC fallback 금지. (3) CLI charge30은 restricted KINDS에 없어 기존 정책을 강행하면 30초 뒤 실패한다. (4) JSON 숫자 ships/lv/p가 float이므로 검증없는 int절삭은1.5→1 오입력. (5) missing JSON이나 unknown mode를 legacy 성공으로 내리면 K01 위반. (6) new owner 공개 전에 초기controls를 배정하지 않으면 K06 위반. (7) 실패 입력을 처리하다 현 owner를 close하면 K08 실패보존 위반.

## 2 공통 책임과 첫 수용 범위

공통 adapter는 파일/표시/스레드를 소유하지 않는다. CLI는 현재 연결할 소비자 선택이지 제품에 CLI가 필수라는 정책이 아니다. adapter의 정규화·검증·private owner 구축은 OS args나 파일경로를 모르므로 향후 UI 선택/worker/replay header가 같은 Dictionary를 공급해 재사용할 수 있다. 신규 전용 core/battle/operation_runtime_adapter.gd는 static factory로 입력검증→한번 정규화→Private.create→완성된 OperationPrivateState owner handle 하나를 반환한다. adapter는 반환 뒤 mutable owner를 보관하지 않고 또 다른 wrapper 수명도 만들지 않는다. 반환된 기존 owner의 public projection/관측·명령·advance·drain·close 경계를 실제 소비자가 사용한다. 실제 입력선택/파일 I/O와 summary·out 게시만 CLI 책임이다. 어댑터가 단순 API 이름바꾸기인 것으로 끝내지 않고 신규 입력계약·원자 구축·정규화·초기controls·한정된 완료관측과 실제 CLI 실행에 연결한다. 내부 private._sim 직접접근은 금지한다. 필요 최소 public read_projection(side)·summary()를 private owner에 추가하여 guard 및 detach를 적용한다. summary는 현재 st clock/end/loss/alive/fingerprint/command count의 명시 detached DTO이며 저장packet을 매tick 생성하지 않는다.

### 명시 신규 입력계약(독립 수용 대상)

CLI에 `--operation-input <JSON path>`가 **있을 때만** 신규 경로. 누락시 현재 _run/play/play_rc 전체 동작 그대로. 플래그가 있으나 인수누락/빈경로/읽기/parse 오류는 exit1, legacy fallback 없음. --profile red_cliffs나 legacy --hz/--runs/--baseline/--policies 등과 혼합되면 명시 conflicting_option 오류(단 --out 허용). 신규 JSON은 `{mode:"operation", format:"p02/restricted-headless/1", profile:<명시 완성된 제한 profile>, seed:<uint32>, hz:10, initial_controls:[...], policy:"none"|"attack5", max_ticks:<양의정수>}` 정확 필드. profile은 필수이며 PocSetup.profile 자동 공급/모듈삭제/증원삭제/기본profile 대체 금지. 파일은 작전 저장이 아닌 실험용 fresh runtime 입력이며 full I01 definition 변환/재개와 구분한다. instance/run metadata는 결과 진단으로만. source/effective 변환은 **없음**(runtime-ready 입력임을 format으로 명시), 변환 ledger는 identity/no transform; I01a source 정의나 effective 결과를 받으면 unsupported_input_representation. 전체 K02 충족 아님을 기록한다.

JSON 정수 의미만 한번 정규화한다: seed/hz/max_ticks와 profile.ally/foe 각 fleet의 ships/lv/p/command/might/intellect/level/start_morale_bp 및 composition.count. bool제외·유한·소수부0·범위검증 뒤 int. 그 밖 임의 숫자/배열/key order는 유지하고 profile rules/combat을 기준자료로 교체하지 않는다. 직접 Variant API도 같은 계약 검증; private owner의 existing exact-context 비교는 손대지 않는다. 입력은 깊게 복사하며 실패 결과는 `{ok:false,error:<code>,path:<input path>}`; owner/effective 없음. profile 지원밖 오류는 private의 정확한 원인을 전달. 메타키/unknown options를 조용히 무시하지 않는다.

controls는 필수 명시 배열, []도 명시 원입력으로 허용하며 delegate 배열과 구분한다. C0는 tick0/clock0/emptyqueue 후 첫 관측까지 구성된 이후에만 게시한다. policy attack5는 현재 policy_commands를 그대로 활용하되 지원 subset만 사전 허용. charge30/unknown policy는 진행 전 거부. 논리시간은 sim이 유일 정본이고 max_ticks는 실행 상한; tick×100으로 종료시각을 재구축하지 않는다. 정책은 step전 projection→ordered queue→advance→ordered drain. 신규 결과는 단일 run summary와 events count/order 관측이며 기존 통계분모에 섞지 않는다. 정상 종료/상한 도달의 reason은 기존 play와 같은 구분, 엔진/명령 오류는 성공 summary 게시 금지. 파일 출력은 전 검증/실행 완료 후 새 경로에 한 번 게시, 실패시 기존 out 파일을 바꾸지 않는다. 실행중 owner에 요청 실패가 나면 그 요청으로 state/event/queue 변경이 없어야 하고 정상 다음 호출이 가능해야 한다.

thread는 이번 동기 CLI 한 스레드만 소유한다. 향후 AutoResolver는 worker가 candidate부터 구축/소비/close하고 완료 DTO만 join후 공개하는 별도 계약이 필요하다. FleetBattle3D는 sim뿐 아니라 clock/G/vm/selection/trace/UI candidate commit이 필요하다. 현 host는 건드리지 않는다.

### 전체 P02 의존성/남은 조건

첫 조각은 실제 headless opt-in만이며 3소비자 공통 연결 완료 아님. K01 명시실패, K02 중복변환없음, K03 정수거부/순서보존, K04 실행입력SHA, K05 현 명령순서, K06 private초기controls/clock0, K07 현step/issue경계, K08 unsupported_checkpoint/실패보존 일부를 검사한다. I01 source→effective runtime 변환·hash계약·ID/command seq·전체 C0/Cn·checkpoint가 없다. operation definition/checkpoint 필드를 받으면 unsupported 명시거부한다. P03~09/제품공간/저장schema/운영Cn/globalcursor/화면Android성능은 미완료 유지한다.

## 3 허용 hunk·분모·oracle·흐름

허용 생산 hunk: 신규 operation_runtime_adapter.gd(글로벌 class_name 없이 preload 가능), operation_private_state.gd의 public read_projection/summary 최소 추가(기존 CODE/STATE/FLEET/context/restore 동작불변), tests/autoresolve.gd의 _run 첫 opt-in 분기와 신규 전용 CLI helper(기존 play/play_rc/정책/요약통계 본문 불변). 신규 tests/p02_headless_adapter.gd 및 입력 JSON 예시/fixture. .uid 자동생성은 새 소유만 기록, class cache 수정/editor import 금지. 기존 테스트 allowlist/skip/runner 불변. 전용 RESULT/CHECKLIST/HANDOFF와 상위 필요한 추가행만 최종 허용; 타 문서진단 해소 수정금지.

코드 runner 새 K6, 이전 P2c5/K6·active2/K6와 분리. **정상 사례 분모:** seed0,7 × 2profile(명시 제한POC, 명시 trusted Salvo+D/S) × 2policy(none,attack5)=8. profile2는 JSON 구성도 출처/명시 disabled 모듈을 공개하며 stock 자료를 런타임에서 지우지 않음. 거부 분모는 아래 v2 표의 API/CLI/read 부문을 각각 집계하고 서로 합쳐 성공사례를 늘리지 않는다.
8 정상은 독립 raw BattleSim reference를 동일 명시입력/controls로 구축하고 현재 policy_commands→queue→step→drain을 직접 수행하여 full script property 기반 상태/시간/command/event 순서를 비교한다. adapter observe끼리 자기capture 비교만 금지. 5/10/15tick 등에 projection/clock/controls·queue-before-step·events once drain을 확인하고 seed쌍 determinism과 입력 byte SHA 불변 확인. 각 프로필마다 pending nextstep1회·issue즉시·재거부 전후 typed state exact/다음 정상호출 검증. timeout/자연종료 양쪽은 종료 fixture 구성 출처를 명시하며 max_tick 시각을 end_ms로 꾸미지 않음. JSON number→typed 필드 정규화 oracle은 하드코딩 독립 예상 int 값/분수거부이고 adapter converter 재사용금지.

실제 CLI 실증: 신규 명시 JSON 정확2성공(POC/services), 아래 v2 표 CLI 거부14건, default legacy 1회(`--runs 1 --policies none --out 새경로`)를 기존 원문 OUT-only baseline copy 실행과 exact row 비교. baseline copy는 신규branch 추가 전 source를 별도 .txt로 보존하고 필요 실행본 역치환 SHA를 남긴다. legacy RC source hunk 불변과 opt-in+red_cliffs 거부는 확인하되 무관200/1000seed 통계재실행 금지.

최소 회귀: 기존 i01b_private_state(OUT-only 새경로/역치환SHA), core_rules. private 추가 읽기 API 외 상태변경이 없고 data파일변경이 없으므로 data_rules 중복실행은 기본불필요; 신규 현상/의존성 변경시만 추가. active_replace는 기존 코드/새 public 메서드가 _coverage 대상 sim이 아니므로 보존연속성 검토, reviewer가 필요 판단하면 OUT-only1회로 추가. 로그는 actual exit와 SCRIPT ERROR/ERROR/종료 ObjectDB/resources 진단 별도 집계. full git diff --check 기존 exit2/CRLF는 유지하며 새 코드 공백검사 분리.

실행 전 엔진SHA/정본classcache SHA 및 실제 resource_path guard, 코드·입력·정본자료SHA/snapshot을 새 attemptN에 동결한다. tmp snapshot은 .txt 보관으로 class registration 오염 예방, 과거 source 삭제금지. 기존 helper6be2adeb.../test e76bc22.../cache0eb214...와 현재SHA 대조, 두 이전ZIP SHA 보존. 독립 계획수용 전 구현금지 → 실행담당 최소구현/5a → 구현비참여 다른모델 최종5b → 수용뒤 기록·3960/source35/격리77보존감사·manifest/ZIP → 독립closeout. 반려시스펙복귀. usage-limit 즉시보고/반복금지.
## v2 R1~R4 보완 계약 — 위 일반 문구보다 이 절의 정확 계약을 우선 적용

v1 원문은 PLAN-v1.before.txt(SHA f4e87fccb6bcc6140e0682d36b268708083469db5f654fa92780b773f4210c4c)에 보존했다. REVIEW-PLAN.md는 범위선택만 수용하고 R1~R4 재심을 요구했다. 아래는 그 반려에 따른 2단계 스펙 보완이며 아직 코드/fixture 생성이나 Godot 실행은 없다.

### R1 검증 순서와 기술적 정수 상한

1. API Variant의 top Dictionary 여부부터 확인한다. definition/checkpoint 키가 있으면 각각 unsupported_input_representation/unsupported_checkpoint를 우선 반환한다. 나머지는 top 정확 필드(누락은 missing_field, 추가는 unsupported_field) 검사→mode/format→profile Dictionary→ally/foe Array→각 fleet Dictionary→composition가 있으면 Array→각 item Dictionary 순으로 타입을 검사한다. 인덱싱/필드읽기는 해당 컨테이너 검사 이후에만 한다. 첫 실패 경로를 반환한다.
2. seed는 0..4294967295, hz는10, max_ticks는1..2147483647. 명시 fleet 정수들/각 composition.count는0..2147483647, ships/lv/count는 추가로1이상. composition 합도 overflow 없이 더하기 전 `total > LIMIT - count` 검사하여 LIMIT 초과 거부. 이 상한은 제품 편성 정책이 아니라 이번 입력 표현의 signed32 안전전달 한계다. 최대값을 실제 대규모 전투로 실행하는 검사가 아니다. owner 기존검증보다 느슨하게 만들지 않는다.
3. 모든 정수는 int 또는 float만 허용(bool거부), 유한·상하한·floor(value)==value를 **int() 전에** 확인. 1e30/NaN/Infinity/분수는 invalid_integer, 올바른 정수형이나 float 정수의 범위초과도 invalid_integer. seed/hz의 정수형식 검증 후 hz!=10이면 unsupported_hz. 정규화가 필요한 whitelist만 int화하고 다른 numbers/Dictionary key order/array order를 유지한다. nested composition aggregate 초과는 integer_total_overflow. helper의 exact typed context 비교는 변경하지 않는다.
4. private.create 선행 실패는 error를 그대로 전달하되 path는 최초 owner 오류분류의 명시 경로로 매핑한다: unsupported_reinforcement→profile.reinf, unsupported_module_config→profile.combat, initial_controls→initial_controls(원소 검증은 adapter에서 구체 index), unsupported_profile_field→profile, 나머지는 profile(세부 field를 임의 추정하지 않음). adapter 자체 타입오류는 invalid_container + 해당경로. 성공메타는 norm profile이나 raw sim을 노출하지 않고 format/identity-transform/input hash 진단만 반환한다.

### R2 출력 no-clobber와 실패 경계

신규 opt-in은 `--out <새경로>`를 필수로 한다. CLI 허용 옵션은 --operation-input과 --out 각1회뿐이다. 정확 parser는 플래그존재를 `_arg` 기본값과 구분한다. 각 값 누락·빈값·다음 옵션토큰은 missing_option_value, 중복은 duplicate_option, 알 수 없는 옵션/남은 위치인수는 unknown_option, 기존 legacy option은 conflicting_option. legacy 분기는 새 parser를 거치지 않는다.

입력읽기/JSON parse/type 검사 후 출력경로 검사: 기존 file 또는 directory가 해당경로에 있으면 output_exists, parent directory가 없으면 output_parent_missing. 입력과 동일경로는 이미 존재하므로 output_exists. 기존 경로를 열지 않는다. write시점에도 exists 재검사한다. 신규 파일을 WRITE로 열기 실패는 output_open_failed. JSON문자열 전체 store_string 후 flush, get_error가 OK인지 확인하고 close 후 새 파일을 읽어 기대 UTF-8 바이트 길이/SHA가 정확한지 확인한다. write/flush 오류는 output_write_failed, 재읽기 불일치는 output_verify_failed. 모두 exit1, 성공 PASS/summary stdout 게시 없음. partial 새 파일이 남으면 실패증거로 보존하고 경로·실제크기/오류를 진단에 남기며 자동삭제/재시도하지 않는다. 실패파일은 다음 시도에서 output_exists로 거부한다.

이것은 단일 CLI 프로세스의 기존출력 보존 계약이다. Godot WRITE API의 check-open 사이에 제3자가 경로를 생성하는 OS 경합이나 디스크 장애의 원자 복구를 보장하지 않는다. concurrent writer를 지원한다고 주장하지 않으며 임의 파일을 덮어쓰는 fallback은 없다. open/write/flush 실제 실패유발이 플랫폼에서 불가능한 경계는 source검토/관측한 경계와 분리해 미실행으로 남긴다. output verify까지 통과한 뒤에만 성공메시지·exit0.

### R3 공개 read와 소유권/정리

factory는 handle 하나만 반환하고 자체 static/mutable owner reference를 유지하지 않는다. CLI가 반환 owner의 단일 소유자다. 실행 helper는 관측/정책/queue/advance/drain 실패마다 error result로 반환하며, 호출자가 성공/실패 모두 owner.close()를 반드시 호출한 뒤에 파일쓰기/성공게시로 이동한다. 출력실패 때는 이미 owner가 closed 상태다. projection/summary 초기 읽기 실패도 같은 cleanup 경로를 거친다. 단순 local reference소멸을 close로 대체하지 않는다. 정리검사는 보유한 Salvo/Detection/Supply module.sim이 null이고 closed read가 unprepared_owner임을 확인한다. runtime script예외 복구 보장은 추가하지 않는다.

read_projection(side)는 `_guard` 먼저, 그다음 typeof(side)==TYPE_INT and side in [0,1] 검증. 인자형은 Variant로 받아 engine coercion 방지; 실패 invalid_side이고 projection 호출 없음. summary도 guard 후 detached Dictionary. read는 state/events/queue를 소비하지 않는다. 정책 입력은 read_projection(0)만이며 summary/observe/owner._sim 사용금지. 테스트 oracle만 private 원본상태를 독립 관측할 수 있다. 새 read API의 실패결과 path는 side검증오류=side, guard오류=owner로 명시한다. 반환 projection과 summary에 대한 깊은 변조가 이후 state/events/queue/projection/summary에 영향없고 첫 실패뒤 정상 read/issue가 가능한지 확인한다.

### R4 정확 named case / 예상 error·path / 도달경로

v1의 18 named 항목을 다음 N01~18로 고정한다. slash로 묶인 문자열은 더 이상 집계단위가 아니다. API 실패는 ok=false/owner없음·입력불변, CLI 실패는 actual exit1/PASS없음/기존out불변을 공통 oracle로 한다.

| ID/name | 경로 | expected error | expected path |
|---|---|---|---|
| N01 missing_input_argument | 실제 CLI `--operation-input` 인수없음 | missing_option_value | --operation-input |
| N02 missing_profile | API | missing_field | profile |
| N03 malformed_json | 실제 CLI parse | invalid_json | input |
| N04 unknown_mode | API | unsupported_mode | mode |
| N05 unknown_format | API | unsupported_input_representation | format |
| N06 unknown_top_field | API | unsupported_field | extra |
| N07 fractional_seed | API | invalid_integer | seed |
| N08 fractional_ships | API | invalid_integer | profile.ally[0].ships |
| N09 unsupported_hz | API | unsupported_hz | hz |
| N10 controls_length | API | initial_controls | initial_controls |
| N11 controls_value | API | initial_controls | initial_controls[0] |
| N12 reinforcement | API | unsupported_reinforcement | profile.reinf |
| N13 active_unsupported_combat | API | unsupported_module_config | profile.combat |
| N14 charge30 | 실제 CLI | unsupported_policy | policy |
| N15 conflicting_legacy_option | 실제 CLI --profile red_cliffs | conflicting_option | --profile |
| N16 unsupported_definition | API definition 키 | unsupported_input_representation | definition |
| N17 unsupported_checkpoint | API checkpoint 키 | unsupported_checkpoint | checkpoint |
| N18 unknown_profile_field | API | unsupported_profile_field | profile |

R1~R3 보완 추가분은 N01~18에 합치지 않고 별도 X/Y/Z named 부문으로 증가한다.

| ID/name | 경로 | expected error | expected path |
|---|---|---|---|
| X01 top_scalar | API | invalid_container | $ |
| X02 roster_scalar | API | invalid_container | profile.ally |
| X03 fleet_scalar | API | invalid_container | profile.ally[0] |
| X04 composition_scalar | API | invalid_container | profile.ally[0].composition |
| X05 composition_item_scalar | API | invalid_container | profile.ally[0].composition[0] |
| X06 huge_seed | API 1e30 | invalid_integer | seed |
| X07 huge_max_ticks | API 1e30 | invalid_integer | max_ticks |
| X08 huge_ships | API 1e30 | invalid_integer | profile.ally[0].ships |
| X09 huge_count | API 1e30 | invalid_integer | profile.ally[0].composition[0].count |
| X10 composition_sum_overflow | API 2147483647+1 | integer_total_overflow | profile.ally[0].composition |
| X11 boolean_integer | API true | invalid_integer | seed |
| X12 nonfinite_integer | API INF | invalid_integer | max_ticks |
| Y01 bad_side_type | API prepared read_projection(0.0) | invalid_side | side |
| Y02 bad_side_value | API prepared read_projection(2) | invalid_side | side |
| Y03 busy_projection | API busy read_projection | busy | owner |
| Y04 closed_projection | API closed read_projection | unprepared_owner | owner |
| Y05 busy_summary | API busy summary | busy | owner |
| Y06 closed_summary | API closed summary | unprepared_owner | owner |
| Z01 missing_out | 실제 CLI | missing_option | --out |
| Z02 empty_input_argument | 실제 CLI 빈문자 | missing_option_value | --operation-input |
| Z03 unknown_option | 실제 CLI --bogus | unknown_option | --bogus |
| Z04 duplicate_option | 실제 CLI --out 두번 | duplicate_option | --out |
| Z05 input_not_found | 실제 CLI | input_read_failed | input |
| Z06 input_top_scalar | 실제 CLI JSON [] | invalid_container | $ |
| Z07 unsupported_stock_poc | 실제 CLI 명시 stock JSON | unsupported_reinforcement | profile.reinf |
| Z08 output_sentinel | 실제 CLI 기존 out sentinel | output_exists | out |
| Z09 output_parent_missing | 실제 CLI 존재안하는 부모 | output_parent_missing | out |
| Z10 output_unopenable | 실제 CLI Windows에서 금지된 leaf 문자 bad*.json(부모는존재)로 open실패 | output_open_failed | out |

정확 분모: 기존 N18 + X12 + Y6 + Z10 = **46 named negative**. API는 N의 API14 + X12 + Y6 =32, 실제 CLI는 N4(N01/03/14/15) + Z10 =14. N14는 실제JSON policy charge30 선행실패이고 API버전 추가호출은 수를 늘리지 않는다. read alias변조/정리 성공검사는 negative수가 아니라 정상8의 공통 불변식으로 검사한다. Z10 실제환경 재현 불가능 시 억지 PASS 금지, 미실행/근거와 함께 reviewer에게 반환하여 계약·검사변경 독립수용 후 진행한다. 구현자가46을 줄여 맞추지 않는다.

정수 정상경계는 실행하지 않는 순수 정규화 테스트로 seed4294967295, max_ticks2147483647과 fleet/composition 허용최대의 변환결과를 독립 예상 int와 대조한다. factory까지 생성하면 거대한 편성 비용이 생길 수 있으므로 이 경계확인은 adapter의 순수 validate/normalize 결과에서 하고 정상8은 작은 입력으로만 실제 runtime을 만든다. adapter는 이 pure 함수와 factory 두 단계로 노출할 수 있으나 mutable state/중복변환 금지. X10은 합계만 검증하고 실제 구축하지 않는다.

CLI 성공2(POC/services)+실패14+legacy before/after1쌍=17논리항목/18실제프로세스이며 main API runner1 및 private/core회귀2는 별도다. 원문 source snapshot/OUT-only 역치환·실행전SHA/exit/로그 분류는 v1 계약을 유지한다. output_open_failed는 실제 Godot error 진단이 나올 수 있으므로 이 거부 실행에만 예상 FileAccess 오류를 좁게 분류하고 script 오류와 혼합하지 않는다. 전 정상/negative 분모 완결과 새 실패0 없이 최종PASS 선언하지 않는다.