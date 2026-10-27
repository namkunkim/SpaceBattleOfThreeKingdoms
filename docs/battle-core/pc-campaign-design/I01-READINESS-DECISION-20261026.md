# I01 준비 판정 — 초기 상태·커밋 계약과 사전등록 추천안

2026-10-26 / **계약 준비·독립 검토 대기 / 코드·검사·작업트리 생성 미승인** / 문서 K=3.

## 1. 이번에 내리는 판정의 범위

기준은 [I01 인수/사전등록](I01-ACCEPTANCE-PREREG-20261026.md), [직전 독립 검토](REVIEW-I01-PREPARATION-20261026.md), [H2](H2-DECISION.md), [구현 스펙](IMPLEMENTATION-SPEC-20261026.md)이다. 사용자 ‘이어서 해’는 남은 입력·공간·상태·사전등록 계약을 정합화하는 준비 승인이다. 코드·게임/검사 실행·작업트리 생성·커밋을 승인한 것은 아니다.

이 문서는 기술 선택을 다시 OPEN으로 열거하는 대신 아래 **권고 규약**을 하나로 제안한다. 그러나 I01은 공간 접근·지속 상태 경계를 포함한 원래 범위다. C0 초기화가 구체화됐다는 이유로 A04의 실제 공간 입력이나 A06의 운영 저장 반례를 삭제하지 않는다. 코드 착수와 종합 I01 통과는 별도다.

## 2. 권고 규약 K01~K08 — 일상 기술 선택의 구체안

| K | 권고 규약·유효 범위 | 근거·거부 oracle |
|---|---|---|
| K01 입력 분기 | 신규 `mode=operation` 명시일 때만 신규 정의 사용. 누락된 mode는 기존 legacy 그대로. 필수 정의·지원 버전·해시 불일치는 신규 진입 실패 | 현 `ProfileLoader` 빈 사전 및 host의 POC 대체와 신규 오류를 분리. 실패 후 기존 활성 전장·원본은 불변, 신규 오류가 POC 성공이면 FAIL |
| K02 실효 설정 | 새 deep copy→유형/단위/참조 검증→난이도/편성→원점0·등방 공간변환1회→기동튜닝1회→ID/준비상태→manifest. `source/effective` 태그 필수 | `enlarge_field/tune_for_play`는 직접 변경. effective 재입력·누락튜닝값·묵시비등방 원 반경 변환은 거부. legacy 변환순서 전역 변경 금지 |
| K03 직렬 표현 | UTF-8, object 키는 순서 정규화·배열 순서는 원래 의미 보존. 유한 숫자만, 의미상 정수의 소수 절삭 금지. 내부 ID/키는 문자열·런타임 ID/커서는 int | 같은 자료의 key순서 차이만 해시에 영향을 주지 않고 roster/명령/진형 배열 순서 차이는 보존. NaN/Infinity·중복참조·누락필수값 거부 |
| K04 정본 해시 | `definition_content_hash`, `effective_content_hash`, `rules/schema/scenario/map/profile` 버전 참조를 분리. SHA-256 권고. 직렬화 정규형 버전도 헤더에 포함 | hash 대상은 실효 규칙·편성·지도·태그·필수 상태계약. 경로절대값·wall/mono시각·runID·관찰주석은 별도 진단. 게임결과 차이를 제외필드로 숨기지 않음 |
| K05 ID·명령 순서 | 새 시도 instance ID는 실행군 내 고유. roster ID→runtime ID 대응은 ally/foe의 확정 배열 순서. 신규 command_seq는1부터, `last_applied_seq=0`은 없음 | 기존 `next_id/next_event_id`는 int·1부터 증가. seq중복 또는 1을 건너뛴 적용은 거부. runtime배열을 hash 편의로 정렬하지 않음 |
| K06 C0 경계 | 정의·편성·전투모듈 초기화와 direct/delegate 초기 배정·첫 투영 생성 준비가 끝났고 **첫 issue/queue/step 전**인 원자 경계 | `BattleSim._init:40~92`와 host의 후속 control 배정을 함께 완료해야 함. C0는 tick0/clock0/적용커서0/대기명령0. 부분 초기화 결과는 게시하지 않음 |
| K07 후속 커밋 | Cn은 step이 반환하고 양자화·모듈 효과가 끝난 시점, 또는 step밖 issue의 적용/로그/이벤트가 함께 끝난 시점. 별도 `commit_seq` 단조 증가 권고 | issue는 즉시 적용하고 queue는 미적용이다. step은 queue를 먼저 적용한 뒤 tick을 증가시키며 종료는 하위걸음에서 가능. tick2/clock150은 그대로 보존; tick×100 복원 금지 |
| K08 재개 범위 | H2의 상태+후속명령·동일 규칙 버전 재개를 유지. 형식/스키마/정의·규칙 내용 불일치면 명시 거부, migration/옛runtime을 자동 호출하지 않음 | 관람 전용 결과는 로직재생 성공이 아니다. 실패로드는 현재활성상태 유지. 신규 checkpoint 기능이 미제작이면 `unsupported_checkpoint`, 빈 상태로 성공 금지 |

K03/K04의 수치 표현은 임의 0.001 반올림으로 전체 상태를 손실시키지 않는다. 기존 위치/방향은 현 코어 양자화 결과를 보존하고 에너지/열 나머지·타이머·원장의 정수 단위는 그대로 둔다. 플랫폼간 숫자 정규형의 실제 바이트 일치는 구현 인수 검사에서 확인해야 한다.

## 3. 초기 Snapshot C0 구체 계약과 운영 Snapshot 구별

‘Snapshot C0’는 초기화 원자 경계의 **필드 계약**이며 저장 파일 구현 완료를 뜻하지 않는다. 정의가 재생성 가능한 값도 비교/복원 책임을 표시한다. 아래 전체가 완성되지 않으면 I01 새 지속상태 생성은 막는다.

| S | C0 필드·타입/단위·초기값 | 정본/재구성·범위 |
|---|---|---|
| S01 | definition/instance ID:string, 각 version/hash:string, status=`initial` | 입력·실효manifest 정본. 지원목록/내용 hash가 일치해야 함 |
| S02 | seed:int 0~4294967295, hz:int10, tick:int0, clock_ms:int0, commit_seq:int0 | 입력+현 규칙 정본. `dt=1/hz` 파생. 별도 벽시계 없음 |
| S03 | last_applied_seq:int0, next_command_seq:int1, pending_commands:[] | 새로운 명령 envelope. 기존 command_log/_queue와 대응 책임을 지정하고 seq없는legacy로그를 몰래승격하지 않음 |
| S04 | next_id:int, next_event_id:int, form_counter:int | `_init`/`_spawn` 종료값 그대로. next_id를 항상1로 되돌리지 않음. 배치함대ID보다 커야 함 |
| S05 | ai_timer:int(ms), first_hit_tick:int-1, sub_ms:int0 | 모듈 초기화값 정본. C0에는 하위걸음 진행없음. 초기화가 event를 발생시켰으면 그 목록/ID도 보존 |
| S06 | fleets:ordered array, roster/runtime ID 대응·side/control·commander·formation·positions | 유일 ID/타입/참조 검사. `home/spawn`·그룹/전환·route·표적은 현재 초기화 결과를 포함. 표시용 캐시 제외에는 재구성 함수/검사 근거 필요 |
| S07 | comp0/stages/hull/max_hull·ships/max_ships/cost0·loss/heal누계 | 초기 전투 편성·손상 정본. 원편성부터 재생성하더라도 실제 C0와 대조. 초기화만으로 모든누계0을 가정하지 않음 |
| S08 | ammo/wch/next_fire·energy_m/rem·heat_m/rem·cooldown/charge·counter상태 | 무기별 기본값/초기사격분산은 `SalvoCombat.finish_setup` 결과. ‘탄약100%’ 한 값으로 축약 금지 |
| S09 | morale_bp/mstate/out·army_ev·모집단·지휘/특기/효과 상태 | enabled 모듈의 실제 초기값/사용량. 지휘·결집·강습 module config 참조 보존; 초기 모듈 부가상태는 BattleState만으로 대체 불가 |
| S10 | detect contacts, supply bases/배정/진행/재고, AI/decision 초기상태 | 활성 모듈은 typed object, 비활성은 explicit disabled+이유. module별 소유자/필드목록/기본값을 등록해야 C0수용 가능 |
| S11 | missiles:[], swarms:[], issued/applied effects/settlement keys:[] | 새 시도에서 비어있음을 검증. 이 값만으로 진행중공격 복원 지원을 주장하지 않음 |
| S12 | operation extension slots:시설/자원/임무/접촉/물류/사건/목표/원장 | ST09~18별 `deferred/not_initialized/active` 구분과 정의 참조. deferred는 구현불가 사유를 갖고 product작전 출격준비를 통과하지 않음 |
| S13 | over:false, win:false, end_reason:"", result:{}, end_tick/end_ms:-1 | 초기 활성 상태. 초기화 도중 종료 조건을 평가해 임의승패로 바꾸지 않음 |
| S14 | source/effective contract version, transform ledger:ordered array | 어떤 좌표/규칙이 어느 단위에서 몇 번 변환됐는지 보존. 원본hash 불변 |
| S15 | evaluation segment/run ID·벽시각·UI알림확인 | **별도 진단**. 코어 snapshot/hash/난수에 넣지 않음. 프로세스간 mono차감 금지 |

운영 Snapshot은 C0와 다른 범위다. Cn에서 S06~S12의 비초기 상태, 진행중미사일/함재기, issue 적용/queue/suffix 겹침, 소유 epoch·예약·배송/결산키·모든타이머와 모듈 나머지를 보존해야 한다. 현재 C0 목록은 모듈별 전체필드명을 다 확정한 사전이 아니므로 **운영 snapshot O07은 미해소**다. I01의 A06은 이 차이를 검사한다. C0생성/비교는 준비되더라도 운영 checkpoint를 입력으로 받으면 미지원으로 거부하고, 재개지원 전체PASS를 선언하지 않는다.

A06 원래 fixture의 ‘seq1/2포함 snapshot, seq3대기/후속, 활성투사체·처리키’ 검사는 유지한다. C0검사만 실행하고 이를 통과했다고 그 운영반례를 삭제하거나 NOT_READY를 PASS로 바꾸지 않는다. 이 의미의 **종합 I01은 운영필드/커밋 검증 전 NOT_READY**이며, 순수변환·C0만 별도 조각으로 진행하려면 범위·검사를 명시적으로 재분해해 독립 판정을 받아야 한다.

## 4. 허용 변경 후보와 불허 경계

다음은 **후속 사용자 승인에 제출할 allowlist 제안**이며 지금 쓰라는 지시가 아니다. 실제 파일 존재/새 경로충돌과 기준hash는 승인 작업트리에서 확인한다.

| 구분 | 제안 경로·허용 내용 |
|---|---|
| 신규 전용 코드 | `core/battle/operation_profile.gd`:입력검증/변환·manifest, `core/battle/operation_initial_state.gd`:C0필드계약 검증/보고. 아직 없는 후보 경로 |
| 신규 검사/fixture | `tests/i01_operation_readiness.gd`, `tests/fixtures/i01/valid_definition.json`, `invalid_definitions.json`, `initial_state_contract.json`:A01~06 runner/인라인fixture의 명시파일화 |
| 공유 최소 hunk | `scripts/FleetBattle3D.gd`:명시 opt-in 선택·동일builder호출·신규실패분기만. `core/battle/scenario_profile.gd`:중복 없는 공통읽기/변환도움이 꼭 필요할 때만 변경이유·전후diff 제출. 기존legacy함수의 규칙/배율·순서 변경 금지 |
| 상태 공유 | `battle_sim.gd`, `battle_state.gd`, `fleet_state.gd`의 변경은 현 제안에서 **자동 허용하지 않음**. C0조회에 꼭 필요한 API가 없다면 field접근/소유방식 근거와 별도hunk계약을 먼저 보강. 운영저장 구현은 후속 |
| 불허 | `project.godot`, `export_presets.cfg`, 기존dirty `bundle_layout.gd`/UI/검사·모든외부hunk, 적벽 scenario/정본base/기존combat 생성물, PC실험작업트리·전체병합, 원격/브랜치 변경·일괄정리 |

신규 단위검사 runner는 legacy호스트·헤드리스·재생 입력어댑터에서 같은 builder를 쓰는지 확인한다. 호스트 분기만 바꾸고 나머지 어댑터가 따로 확대/튜닝하면 FAIL. 새범위가 위 allowlist를 넘으면 먼저변경명세를 수정하고 검토한다. 현dirty를 가져와 공간기준으로 확정하거나 unknown소유를 기술기본값으로 결정하지 않는다.

## 5. PR01~06 추천 freeze manifest

다음은 산출될 manifest의 실제 필드 집합과 추천값이다. `REQUIRED_BEFORE_RUN`은 임의hash/기기를 넣지 않도록 한 결측값이며 freeze된 척하지 않는다. 후보내용을 바꾸면 `prereg_revision`과 새 run군 ID를 발급하고 이전결과를보존한다.

```yaml
prereg_revision: i01-r1-proposed
execution_status: not_authorized
scope: full_I01_including_space_and_state_boundary
baseline_commit: 93e60e6a957ffdb002a1cb06bc796c4c46496736  # 과거 로컬 감사값, 착수전 재확인
worktree_path: REQUIRED_BEFORE_RUN
approved_diff_hash: REQUIRED_BEFORE_RUN
rules_definition_profile_map_hashes: REQUIRED_BEFORE_RUN
canonical_format_version: i01-canonical-v1-proposed
contract_fixtures: [FX-L, FX-G, FX-S]
seed_list: [0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295]
adapters: [host_input, headless_input, replay_input]
fresh_build_repeats: 2
valid_config_build_comparisons: 60
invalid_variants: 8
invalid_adapter_checks: 24
first_repeat_order: [legacy, operation]
second_repeat_order: [operation, legacy]
source_bounds: [0, 0, 1000, 600]   # FX-G 산술, product공간아님
fixture_target_size: [2000, 1200]
fixture_seed: 20824
fixture_hz: 10
fixture_move_mul: 2
fixture_turn_mul: 3
product_space_contract_hash: REQUIRED_BEFORE_RUN
state_dictionary_commit_contract_hash: REQUIRED_BEFORE_RUN
hardware_engine_environment: REQUIRED_BEFORE_RUN
q67_applicability_record: REQUIRED_BEFORE_RUN
expected_invariants: [legacy_unchanged, reject_invalid, no_input_mutation, transform_once, same_logical_clock, state_references_valid]
game_balance_or_fps_acceptance: not_in_this_manifest
run_id: REQUIRED_BEFORE_RUN
```

| PR | 추천 freeze 규칙·oracle |
|---|---|
| PR01 | 기준commit+source/diff hash+소유/허용작업트리·engine를동결. 위옛commit은현재안전성증거아님. 외부dirty무단포함불가 |
| PR02 | F01~16/공간계약/모듈 C0사전/원천·변환버전을고정. FX-G는산술fixture로만사용. product좌표·서비스·최대진형은별도공간계약hash필수 |
| PR03 | seed10×adapter3×fresh2=60설정비교/invalid8×3=24거부. 두 반복순서를반대로하여입력변경·캐시영향검출. 결과를승률60판/사람표본으로해석하지않음 |
| PR04 | 동일기기/engine/옵션·명령입력·segment기록. 실제벽시간은진단만,이번I01성능합격선은없음. 게임후속Tg/Ta/Tp·배속/외부구간/불명판단은D09계획별등록 |
| PR05 | baseline/후보실효규칙·배치·roster순서·C0논리필드 동일성 비교. key canonicalization만허용,배열정렬금지. 기존양자화정책밖의차이에후허용오차추가금지 |
| PR06 | 파일무결→버전/타입→invalid거부→legacy보존→변환→공간→시계→C0/운영상태분리순서. missing=NOT_READY,명세위반=FAIL,사전환경오류=INVALID. 게임오류·실패seed는제외하지않음 |

전송훼손·명세밖engine·검증된기기장애만 사전 정의된 INVALID 후보이며 원자료/원인을보존한다. 코드오류·교착·조기패배·틀린재고/시간은FAIL이고 제외불가다. retry는새 run ID/parent run ID로 연결하고 기존 실패를삭제하지않는다. 설정비교 10seed는 Q67과무관하다. Q67적용이면신규지형활성화前B항등재+1000seed재측정,비적용이면실제변경범위·공유영향·제외근거를명시한다.

## 6. 예정 명령과 실패 상한 — 미실행

아래는 **승인된 작업트리에서만 나중에 실행할 명령**이다. 새 runner/fixture는 아직 없으므로 지금 실행하면안된다. 기준작업트리·Godot설치경로/engine버전·run출력경로를freeze하고 신규/legacy의같은규칙을쓴다.

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<승인된 작업트리>' --script tests/i01_operation_readiness.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<승인된 작업트리>' --script tests/data_rules.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<승인된 작업트리>' --script tests/terrain_display.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<승인된 작업트리>' --script tests/battle_flow.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<승인된 작업트리>' --script tests/pacing.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<승인된 작업트리>' --script tests/boundary.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<승인된 작업트리>' --script tests/battle_trace.gd
```

각검사는전체stdout/stderr·종료코드·입력/결과hash·최초실패ID를보존한다. legacy기준선차이는벽시각/절대출력경로등 명시진단메타만제외;실효규칙·편성·배치·결과/지문변경은별도근거/승인없이허용하지않는다. 동일문서/조각의5-a수정재시도 K=3권고,3회실패시멈추고책임자보고. 독립5-b반려는2단계스펙에반환,테스트를고쳐오류를숨기지않는다. Q67의1000seed실행명령·편성/정책은범위판정후별도freeze이며이명령목록으로충족했다고쓰지않는다.

## 7. readiness 판정·실제 다음 행동

| 항목 | 문서 준비 판정 | 실제 실행 판정·해소 책임 |
|---|---|---|
| 입력/변환·A01~03 | 권고규약과fixture/oracle 구체화 | baseline/경로hash freeze·allowlist·작업트리/실행승인 전 BLOCKED |
| A04 공간 | [공간 readiness](I01-SPACE-READINESS-20261026.md)의정적fixture/제품구분 반영 | product envelope/서비스/진입·퇴로·dirty진형 기준 선택 전 NOT_READY. FX-G산술PASS로대체불가 |
| A05 논리시계 | 초기0·누적clock보존·commit구분 구체화 | adapter/코어검사·실제종료하위걸음반례 미실행 |
| A06 상태 | C0필드·seq/커서·Cn경계·지원거부 구체화 | 활성모듈필드사전/커밋·운영snapshot반례는미완료. C0만으로종합PASS불가 |
| PRfreeze | 재현가능 추천manifest 값·invalid/제외 규칙 준비 | REQUIRED_BEFORE_RUN 필드와hash·기기·실행범위승인 전 NOT_FROZEN |
| O06 통합 | [기준 감사](I01-BASELINE-AUDIT-20261026.md)의직접/간접dirty·PC미확인보존 | 새/기존작업트리와기준commit/diff소유 결정필요. PC전체자동통합금지 |
| I01 전체 | 별도계획중첩아닌 첫조각계약이 마련됨 | **NOT_READY**. 공간/상태/소유의실질게이트를건너뛰어코드시작하지않음 |

최종 사용자 판단 후보는 최대2개다. ①아래 명시적 I01a/I01b 분해를 채택하고 I01a 신규파일·고정fixture 코드/검사만 시작할지, 또는 원I01 전체가 준비될 때까지 기다릴지. ②기존공유변경/PC작업트리를 보존하고, 재확인한 명시 baseline ref에서 dirty를복사하지않는 새작업트리를 사용할지. 둘 다 아직 미채택이며 승인 전 코드/검사·작업트리생성 금지.

새분해 권고는 아래처럼 구체화하며 기존 원I01 문서는 수정하지 않는다. 독립 검토·사용자 선택을 거치기 전 자동채택하지 않는다. 새로운 게임밸런스·지원약속은 추가하지 않는다.


공간 원문 §1~4를 직접 대조했다. baseline93e60e6의 ship_gap20·28슬롯점 반경 최대297.953016은 선체/생략함선/전환의 전체논리외곽이 아닌 기하 참고값이다. FX-G effective E/R 벽거리100은 가짜원형40+여유10에는맞지만 실제슬롯점최대에도못미친다. 따라서 fixture좌표를product배치로승격하지않는다. FX-G source자유중심[25,975]×[25,575]·effective[50,1950]×[50,1150],7노드9항로·서비스교집합은정적oracle로동결권고가능하다. 서비스원일부가world밖이어도 중심inside·자유중심교집합검사라는 `region_admission`을명시해야한다. region완전포함정책으로조용히바꾸면E/R은실패한다.

기존 legacy서비스180/140은`enlarge_field`에서배율되지않으며,FX-G의명시source-unit60만120으로변환한다. 효과rect는항로와겹치지않으므로effect감속·탐지의성능/시간검증fixture아니다. 단절음성례는E-J제거로고정한다(A-C만제거하면A-B우회가남음). 공간원문§5의넓은공유hunk허용후보는**원I01 제안 목록**이고 아래I01a의신규4파일allowlist와다르다. I01a선택시좁은목록만적용하며둘을합쳐공유파일을무단허용하지않는다.
## 7.1 명시적 재분해 권고 — I01a와 I01b, 미채택

원I01의 공간/운영상태 선행이 실제 부족하므로 이를 해결한 척 코드를 시작하지 않는다. 대신 한정된 입력변환 코드를 먼저 검증하는 **새 I01a**와 원래 runtime 경계를 담당할 **I01b**로 분리하는 안을 2/3단계 재분해 권고로 제출한다. 이것은 조율자/검토자만으로 채택할 범위가 아니다.

| 범위 | I01a 구성/완료 기준 | I01b에 보존되는 원I01 검사 |
|---|---|---|
| 코드 | 신규 `core/battle/operation_profile.gd` 1개: 순수 dictionary 검증/깊은복제/정의→실효설정/오류/manifest. 기존 ProfileLoader/ScenarioProfile 공개 읽기 API를 사용하되 기존파일은수정하지않음 | host/헤드리스/실제재생의공통경로 연결·BattleSim/C0/module 필드/직접지휘 초기화·제품공간/활성화 |
| fixture/검사 | 신규 `tests/i01_operation_config.gd`, `tests/fixtures/i01/valid_definition.json`, `invalid_definitions.json`만. FX-G 산술·graph 서비스 교집합,8invalid·canonical/원본불변을 검사 | 최대실운용진형/회전/퇴로/서비스/E-R·운영snapshot/issue-queue/suffix/active공격·거래원장·진짜같은Tg재생 |
| legacy | mode미선택 시 기존 공개 profile 생성의 논리출력과 신규wrapper를같은입력으로비교. 기존규칙JSON·편성/배치순서 불변 | legacy호스트 UI·실게임/재생/플랫폼·전투결과회귀는 b활성화 전에 별도유지 |
| 상태 | seed/hz/clock-unit/cursor-metadata는 **설정 값 검증**만. 신규 BattleSim/OperationState·C0runtime·저장파일·suffix 실행을 만들지않음 | A06 전체ST사전·원자커밋·복원/멱등성. a통과≠A06PASS, b게이트는보존 |
| 어댑터 | host/headless/replay의 **입력 envelope 형식 3종**을동일builder로보내 설정정규형만비교. 실제기존호스트/재생어댑터변경없음 | A05 실제정지/배속/논리시계·재개일치 및 realadapter연결. a의metadata검사로대체불가 |
| 공간 | 고정FX-G만 산술/기하oracle, geometry값출처를fixture로표시. 실제전장/카메라/최대진형값을정답으로고정하지않음 | A04 product 전체. 반경20/여유5의fixture만으로통행완료주장금지 |

I01a 전용 합격표는 `a01_legacy_config_unchanged`, `a02_invalid_rejected`, `a03_transform_once`, `a04_fixture_geometry_only`, `a05_envelope_metadata_consistent`, `a06_no_runtime_or_save_side_effect` 6항이다. 원래 A01~06와 식별자를 분리한다. a06은 기존C0/A06를 구현하는 검사가 아니라 **runtime/저장 부작용이없음**을 확인한다. 원A04/A05/A06의미실행/NOT_READY를 그대로 결과에 게시한다.

a측정은 위PRmanifest의 `scope=i01a_config_fixture_only`·`excludes=[product_geometry,runtime_snapshot,host_activation,gameplay]`로 새 revision을발급한다. seed10×입력envelope3×fresh2=60은설정비교,invalid8×3=24는거부검사다. 목적은순수변환/거부/동일성의정확성이며게임시간·완주율·성능표본아니다. 예정보조명령은승인작업트리에서 `Godot --headless --path <path> --script tests/i01_operation_config.gd`와 기존 `data_rules.gd`다. 신규파일만이라도 exactallowlist/engine/자료hash·정규형과fixtures를실행전freeze하고 종료코드0+모든a검사통과+원본불변+금지파일diff없음을제시한다. 전체게임회귀명령은b에게유지하며 a결과로실행했다고쓰지않는다.

I01a의쓰기허용은위4신규파일뿐이다. 기존`ScenarioProfile`/host/BattleSim/state/프로젝트/원천·생성물/기존dirty/PC파일은모두불허. 출력은검사stdout/stderr와승인된임시진단경로이며product user-save로쓰지않는다. 필요코드가이경계를넘으면확장하지말고스펙으로반환한다. Q67은이정확변경목록에대해 ‘신규지형활성화없음/공유경로변경없음’ 근거로비적용권고를작성할수있지만 자동면제하지않는다. b에서본체·공유코드활성화시다시판정하고 적용B항+1000seed를보존한다.

현재이분해는**CODE_AUTHORIZATION_PENDING**이다. 사용자채택+독립재분해수용+O06의정확새작업트리ref/소유경계가모이면a코드착수가능한선택이된다. 미해결productgeometry/운영snapshot 때문에원I01전체를계속정의서만늘려묶어두는대신,무엇을검증하고무엇을미루는지명시해실행여부를결정한다.
## 8. 자체5-a·인계

검사범위는K8/S15/PR6/readiness7행·seed10/설정60/거부24산술·링크·허용1파일·코드/시험미실행·실질NOT_READY유지다. 문서 K=3. 독립검토자는원문/현코드·반대근거와대조하고수용/조건부/반려를별도기록한다. 작성자가자기5-b를선언하지않는다. SPACE결과수신후링크·교차정합확인만보강하고범위를확장하지않는다.

자체5-a 최종 인계: K8/S15/PR6·readiness7행과 I01a/I01b분리·신규4파일allowlist·60설정/24거부 산술·링크6누락0·행말공백0을 확인했다. 첫 정규식이 K의 제목접미어와 readiness 첫행을 누락해 검사식을 고친 뒤 개수를 재확인했으며 문서내용/판정은 바꾸지 않았다(K=3 중 2회). 공간 원문의 source/effective 단위·최대슬롯점 한계·서비스반경 미배율·영역admission·E-J단절 반례를 대조했다. 원I01전체NOT_READY/I01a미채택·게임/검사/작업트리 미실행을 유지한다. 지정문서만작성했으며 독립검토에 인계한다.
