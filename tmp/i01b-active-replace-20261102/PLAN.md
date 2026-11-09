# 제한 활성 owner의 runtime 교체 — 1~3 계획

2026-11-02 KST(클라이언트 날짜) / **독립 계획 심사 전, 구현 미착수**. 이름을 P2d로 고정하지 않는다.

## 0 맥락과 현재 동결

플레이북·CLAUDE·적용 AGENTS 검색 결과 및 이전 P2c 결과/체크리스트/독립 리뷰/HANDOFF를 따른다. 적용 AGENTS.md는 발견되지 않았다. 상위 정본 근거는 `docs/battle-core/CHECKLIST-OPEN.md`의 미완료 **I01b 후속 실제 통합**, H2-02의 상태+후속 명령 방향, D04 §4의 검증→재구성→참조/파생검증→원자 교체, I01 readiness K06~K08의 완료경계/실패보존이다. 외부 schema·전역 cursor·운영 Cn·게임 정책은 이 계획에서 확정하지 않는다.

실제 원본 branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 빈 상태다. `before.json`은 현재 dirty3879 경로 SHA를 새 동결한다. `resume-state-audit.json`은 이전 P2c zip SHA `99a4a1adca1bdc3bf7e56baa9112c1625ab6c6371bfaafa0482b3471903a2971`, 254항 CRC/각 SHA/목록 및 현재 payload 불일치0을 기록한다. P2c 주 runner attempt5/K6와 새 단계 주 runner 0/K6는 별도 이력이다. 기존 검사를 새 코드/실패 없이 재실행하지 않았다.

## 1 의도와 실제 소비자 조사

P2c의 static `OperationPrivateState.prepare(packet)`는 완성된 **새 owner를 반환**하지만 호출자가 보유한 활성 실행기 교체 책임은 남아 있다. 이번 조각은 기존 owner handle을 계속 소비하는 제한된 동기 실행 루프에서 packet으로 내부 runtime을 교체하고 실패 시 현재 runtime을 보존하는 실제 연결을 만든다.

기존 생산 진입점은 다음과 같다.

| 경로/진입점 | 실제 책임 | 이번 연결 여부와 근거 |
|---|---|---|
| `scripts/FleetBattle3D.gd:init_game` 약169~245행 | raw BattleSim 생성204행, 초기 수동제어, G/clock/vm/선택/카메라/trace/표시 초기화 | 변경하지 않음. 기본 적벽/stock POC는 P2c 지원 밖이며 sim 교체 한 줄로 UI/시계/표시 계약을 대체할 수 없음 |
| 같은 파일 `_process`, `update_sim`, `issue`, `_sync` | raw sim.step/issue와 화면 투영·사건 소비 | 변경하지 않음. 기존 raw sim 바인딩을 완료 owner 계약으로 가장하지 않음 |
| `scripts/world/auto_resolver.gd:_prepare/_loop` | 실제 적벽 프로필, raw sim, 작업 스레드와 progress 게시 | 변경하지 않음. 이번 동기 제한 owner는 스레드 안전성을 보장하지 않음 |
| `tests/autoresolve.gd:play/_play_rc`, `BattleSim.replay` | 별도 raw sim과 정책/명령 재생 경로 | 변경하지 않음. 공통 adapter 완성은 후속 |
| `OperationPrivateState`의 issue/queue/advance/drain/observe/capture | 이미 제한 프로필의 완료 경계를 소유하며 실제 명령·사건 소비가 가능 | **이번의 실제 좁은 소비자**. 기존 handle에서 capture→계속 진행→복원→동일 명령 suffix를 이어 수행 |

새 slot/facade/wrapper 클래스를 만들지 않는다. 기존 owner에 instance 메서드 `restore_completed(packet: Variant) -> Dictionary` 한 개를 추가한다. caller가 기존 owner handle을 계속 쓰며 교체 성공 때 내부 private sim identity만 바뀐다. 이는 실제 host의 owner 객체 참조 교체나 제품의 load UI 계약이 아니다.

## 2 스펙과 수용 테스트 이름

### 지원·호환 경계

- 기존 P2c와 동일한 제한 프로필/명령/reinf=[]/정본 class guard를 재사용한다. packet의 profile/seed/hz/initial controls가 현재 owner의 원 입력과 정확히 같은 경우만 허용하는 **국소 동일-context 교체**다. 비교는 Variant 타입/값, Dictionary 키 타입·삽입순서, Array 요소순서와 typed builtin/class/script metadata까지 포함한다. script metadata는 실제 typed script identity를 비교하며 타입을 erase하거나 JSON으로 변환하지 않는다. `[]` 초기 controls와 명시적인 delegate 배열은 결과 제어가 같더라도 원입력이 달라 불일치다. 기존 Service._same은 Array metadata를 비교하지 않으므로 그대로 충분하다고 주장하지 않고 신규 owner 안의 작은 전용 재귀 비교를 사용한다. 기존 Service/P2b를 수정하지 않는다. 다른 작전/규칙 전환 정책을 발명하지 않는다. 차이는 `replacement_context_mismatch`로 거부한다.
- 기존 `_guard`를 먼저 적용하여 busy는 `busy`, closed/unprepared owner는 각각 기존의 `unprepared_owner`로 prepare와 swap 전에 거부한다. 외부 live sim 또는 외부 owner를 입양하는 API는 추가하지 않는다.
- `Private.prepare` 전체 검증과 exactness를 재사용한다. 새 prepare 실패는 원래 명명 오류를 보존하며 packet/source/활성 runtime을 바꾸지 않는다. context 불일치는 candidate를 정리하고 현재 owner를 보존한다.
- 호출 순서는 현재 owner `_guard` → 현재 `_busy=true` → candidate `prepare` → context exact 검사 → 이전 sim을 국소 변수로 보유 → 현재 `_sim`에 candidate sim을 한 번 이전 → candidate의 `_sim=null`로 소유해제 → candidate.close(이미 소유 sim 없음) → 이전 sim의 Salvo/Detection/Supply module.sim만 retire → 현재 `_busy=false` → 성공 반환이다. 현재 owner 객체 identity/ready/원 입력은 유지한다. 현재 owner.close()를 호출하여 새 sim을 닫는 경로는 금지한다.
- guard 실패는 아직 busy를 바꾸지 않았으므로 그대로 반환한다. prepare 실패는 현재 busy를 반드시 원복하며 이전 sim을 닫지 않는다. candidate 완성 후 context 실패는 candidate만 close하고 현재 busy를 원복한다. 모든 정상 오류 반환 뒤 현재 owner는 다음 정상 public 호출이 가능해야 한다. 동기 경로에 signal/callback/await/스레드 hook은 없다. 기존 prepare가 수행하는 `_code` FileAccess SHA와 `_profile_error`의 ProfileLoader.read_json 등 **기존 read-only 코드/설정 읽기**는 재사용한다. 신규 파일쓰기·로그쓰기·저장 I/O는 추가하지 않는다.
- 이전 sim은 성공한 swap 뒤 기존 close의 module.sim 분리 방식으로 정리한다. 새 sim의 module.sim은 새 sim 자신에 결합되어야 한다. 실패 때 이전 sim과 모듈 참조를 닫거나 바꾸지 않는다. 준비 중 candidate와 이전 owner가 외부에 동시에 게시되는 API는 없다. runtime 예외까지 트랜잭션으로 복구한다거나 멀티스레드 close와 경합해도 안전하다는 보장은 하지 않으며, 정상 지원 입력의 예외는 테스트 실패로 처리한다.
- issue/queue/advance/drain의 의미를 바꾸지 않는다. packet의 pending은 복원 중 미실행이며 다음 advance에서 단 한 번 소비한다. **packet 시점에 이미 drain된 사건은 빈 상태로 복원**한다. packet 시점 미소비 사건은 packet 후 원래 timeline에서 소비했더라도 되감은 runtime에 다시 존재하므로 한 번 drain되는 것이 정확 복원이다. 외부 소비자에 이미 전달한 효과의 전역 중복억제는 구현/주장하지 않는다. 전역 command cursor·commit 번호·checkpoint 수명·외부 스키마 태그는 추가하지 않는다.
- underscore reflection이나 외부에서 보유한 raw `_sim` 참조의 생존, 멀티스레드 원자성은 지원하지 않는다. 폐기된 sim을 이용한 입력은 public API가 아니다. 기존 close의 공개 반환형도 바꾸지 않는다.

### 명명된 수용 시나리오

신규 `tests/i01b_active_replace.gd`에 다음 테스트 이름과 정확한 완결 guard를 둔다. seed는 이전 10종을 그대로 쓰고 제한 POC projectile와 Salvo/Detection/Supply 두 fixture 계열을 사용한다. 정본 입력값을 새 제품 수치로 승격하지 않는다.

| 테스트 이름 | 실제 시나리오와 oracle |
|---|---|
| `replace_completed_keeps_owner_handle` | owner가 실제 issue/advance로 비초기 상태를 만든 뒤 packet을 capture, 더 진행한 active 상태에서 restore_completed. owner identity 유지/new sim identity 분리와 packet 시점 상태 exact 복원을 별도 script-property oracle로 검사. POC는 actual nonempty missile/swarm와 cooldown>0을 capture 전 assert |
| `replace_then_public_suffix_matches_fresh_reference` | 별도 정상 prepare reference와 active 복원에 같은 public queue/advance/drain suffix 적용. 매 step typed 값·순서·명령로그·자원·사건을 직접 비교. 단순 자기 capture 비교만 oracle로 쓰지 않음 |
| `pending_consumed_once_after_replace` | capture 시 pending queue를 포함하고 active는 이미 그 명령을 소비한 뒤 복원. restore 자체는 pending 미실행, 다음 advance에 정확히 한 번, 그다음 추가 효과 없음 |
| `packet_event_boundary_restored_exactly` | drain 뒤 capture한 packet을 복원하면 drain 빈값. drain 전 packet을 capture하고 원 timeline에서 소비 후 복원하면 그 packet의 사건이 정확한 기존 순서로 한 번 drain되어야 함. packet 후 외부 소비까지 중복제거한다고 해석하지 않음 |
| `replace_retires_old_bindings` | 성공 뒤 보유해 둔 이전 sim의 Salvo/Detection/Supply module.sim이 해제됐고 새 모듈은 새 sim에 결합, 새 by_id cache는 새 fleet identity. alias 변조가 packet/새 active/reference에 누출되지 않음 |
| `late_bad_form_preserves_active_and_packet` | P2c의 마지막 fleet.form.clear() 반례를 복원 요청에 넣어 `fleet_empty_form` 거부. 기존 sim identity/모든 직접 oracle/packet typed stamp/이후 정상 public 입력의 성공을 함께 확인 |
| `context_mismatch_preserves_active` | 각각 유효한 다른 profile/seed/controls packet을 prepare 가능한 상태로 만들되 replacement는 `replacement_context_mismatch` 거부. profile 비교는 typed metadata 차이만 있는 유효 자료도 포함해 Service._same만 쓴 잘못된 구현을 검출한다. controls는 []와 명시 delegate 배열의 원입력 차이를 실제 거부. hz는 기존 P2c가 TICK_HZ만 지원하므로 다른 hz를 유효 candidate로 만들지 않고 `unsupported_hz` 선행 거부를 별도 검사. packet/현재 sim identity·관측 불변과 candidate 미게시 확인 |
| `busy_closed_unprepared_fail_before_swap` | 완료 경계가 아닌 상태와 닫힌 owner에서 명명 거부·무변이·새 sim 미게시. busy 거부 뒤 busy를 복구한 정상 호출은 가능해야 함. prepare 실패/유효 candidate context 실패 각각 현재 owner busy가 false이고 다음 정상 issue/restore가 가능한지도 검사 |
| `repeat_restore_has_no_duplicate_effects` | 동일 packet 두 번 교체해도 각 복원 직후 동일 상태이고 명령/보급/사건 효과 추가 실행 없음. 이후 같은 suffix 동일 |

실제 분모는 10seed×2계열=20개 정상 교체/suffix 사례이며 각 사례에 pending/drain/identity/retirement/repeat 검사를 포함한다. Salvo-D/S 각 사례는 실제 nonempty remembered contact, sup_src/sup_prog>0의 진행과 완료 뒤 supplied 증가·보급함 재고 차이를 assert하고, suffix가 실제 평가/보급 완료 경계를 넘도록 한다. 상태를 직접 써서 효과가 있었다고 주장하지 않는다. 진행/완료 경계는 한 사례 안의 세부 구간이며 정상 분모를 늘리지 않는다.

명명 거부는 `busy`, `closed`, `unprepared`, `late_empty_form`, `different_profile`, `different_seed`, `unsupported_hz`, `different_controls`의 정확히8개를 별도 집계한다. 다른 정상 profile/seed/controls는 기존 prepare를 먼저 독립 성공시켜 거부원인이 context임을 확인한다. normal20/각 category10/거부명8 완결은 runner가 assert하며 count를 낮추어 맞추지 않는다. 독립 심사가 분모 보완을 요구하면 구현 전 이 계획을 수정하여 수용받는다.

## 3 분해·허용 경로·5a/5b·6

1. 조율자가 계획/범위를 확인하고 구현 비참여 **다른 모델**에게 독립 계획 심사를 요청한다. 반려는 2단계로 돌아간다. 수용 전 구현하지 않는다.
2. 허용 생산 hunk는 기존 신규 `core/battle/operation_private_state.gd`의 instance restore_completed 및 그 전용 최소 helper만이다. 전체 필드 codec/기존 APIs를 재작성하지 않는다. 신규 검사는 `tests/i01b_active_replace.gd`. 새 production facade는 없다. 기존 tests/P2b/core/데이터/host/HTML은 수정하지 않는다. UID가 생기면 자기 신규 검사 UID만 소유로 분리한다.
3. 실행 전 새 helper/test·원입력·정본 class cache·엔진 SHA, 기존dirty3879 보존 baseline과 허용 diff를 동결한다. 신규 주 runner는 **새 단계 attempt1/K6**부터 시작하며 P2c attempt5/K6와 혼용하지 않는다. 출력은 이 신규 증거 폴더에만 기록한다. editor import를 하지 않는다.
4. 5a는 신규 runner의 실제 exit0/예정분모·명명거부/로그 SCRIPT ERROR·ERROR0 및 종료진단을 확인한다. 실제 코드 변경이 생겼으므로 관련 회귀로 P2c70사례 runner를 OUT-only 복사하여 원문 역치환 SHA를 입증하고 core_rules/data_rules를 실행한다. 원래 P2c attempt5 관측·zip을 덮어쓰지 않는다. 기존 data 종료 리소스 진단은 별도 기록한다. 새 실패/미해결 없으면 그 밖의 통과 검사를 반복하지 않는다.
5. 기존3879 경로와 P2c 마감254항 중 허용 helper 변경만 분리하고 다른 SHA를 전량 대조한다. source35/격리77/HTML 및 원브랜치/HEAD/index를 보존한다. `git diff --check`, 신규 소유파일 공백/정본경로 검사를 수행한다.
6. 구현 비참여 다른 모델이 source diff·실제 소비자/API 경계·late 실패 원자성·정상20 suffix·identity/cleanup·원문 로그/SHA/보존을 최종5b 심사한다. 수용 뒤에만 결과/체크리스트·상위 필요한 행·최종 감사/압축 인계를 기록한다.

코드 재시도는 신규 주 runner K6를 넘기지 않는다. 최종5b 반려는 스펙으로 반환한다. 사용량 제한이 다시 발생하면 즉시 조율자에게 보고하고 반복하지 않는다. HTML 기능·다운로드 QA/새worktree/커밋/푸시/main 병합은 금지다.

**완료해도 제한 owner 내부 runtime 교체 구성요소만 완료한다.** 실제 host/headless/replay 공통 연결, 모든 캠페인 모듈·ST01~18·운영 Cn/global cursor·외부 저장파일/schema·제품 공간/화면/Android/성능/사람플레이는 계속 미완료이며 전체 I01b/A04~A06 NOT_READY·외부 schema UNCLASSIFIED를 유지한다.
