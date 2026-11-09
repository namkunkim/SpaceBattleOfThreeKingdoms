# P03 fresh replay 부분 처리 경계 — 계획 심사안

2026-11-08. 상태: 계획만 작성, 독립 심사 대기. 실행·검사 코드 미작성. 역할/모델 배정 한계는 MODEL-VERIFICATION-20261108.md 참조. HEAD와 시작 status는 START-HEAD.txt, START-GIT-STATUS.txt; 읽은 핵심 입력 SHA-256은 READ-INPUT-SHA256.json. status 열거 시 P02의 긴 경로 2건에 접근 실패 경고가 발생했으므로 이 목록은 원자적 전체 스냅샷이나 완전한 보존 증거가 아니다. tracked dirty 중 tests/autoresolve.gd, scripts/world/auto_resolver.gd, scripts/world/battle_outcome.gd 및 미추적 tests/p02_*와 tmp/p02-*는 P02/동시 작업 가능성이 있는 별도 입력이다. 소유를 추측해 수정하지 않는다. 동시 변경은 실행 직전과 직후 해당 입력을 재해시하고 시작 기준과 별도 기록하며 차이가 나면 그 실행을 보류·재동결한다.

## 정본과 현행 경계
- H2-02는 현재 전체 상태와 이후 명령, 초기 동일 규칙 재개 방향을 채택하고 필드/커서/원자 커밋/스키마는 미결. D04 ST02·ST18 및 §4는 시간·적용·예정·효과·게시를 구분하며 T02는 동일 suffix 후 상태·사건 비교를 요구한다. I01 K05~K08은 권고이고 A06의 seq1/2 반영, seq3 pending/suffix 한 번 적용 및 거부 시 active 불변은 전체 미완료 인수다. 현 코드의 행 번호나 log 길이를 전역 seq로 승격하지 않는다.
- operation_private_state.gd:189–229: 구조 검증 뒤 detached 복사; queue 성공은 접수이고 issue는 즉시 적용, advance는 step 호출 성공이다. battle_sim.gd:142–180은 issue와 step 내 queue 각각 현재 tick으로 log 후 적용한다. 전술적 rejected 사건이 나와도 구조 수용과 구별한다. 효과 완료 및 외부 게시 성공을 API 성공이나 log로 단정하지 않는다.
- operation_replay.gd:32–70, 98–142는 모든 행을 먼저 구조/순서 검사한 다음 같은 tick 행을 차례대로 queue, advance 성공 뒤 지역 consumed 갱신, raw drain 후 summary를 읽는다. 완료 전 종료하면 최초 미소비 행 path로 오류; 정상 반환에서만 지역 consumed를 meta에 실는다. _play_and_close는 정상 반환형 성공·실패에서 fresh owner를 닫는다. raw/filtered는 같은 파괴적 event queue이며 외부 소비 ack나 효과 완료와는 다르다.
- 같은 tick에 I가 이미 적용, Q가 packet pending, B가 후속이면 tick >T는 B를 놓치고 >=T는 I를 중복한다. 같은 Q 두 접수는 둘 다 의미가 있다. packet의 pending은 재주입하지 않아야 하며 적용 prefix/pending/suffix의 권위와 절단점은 운영 계약으로 미결. 결함을 탐지할 기준을 제시하는 것이지 정책을 정하지 않는다.

## 작은 조각과 기존 검사와의 차이
목표: P02 fresh replay에서 선행 명령을 실제 처리한 뒤 자연 종료로 후속 행이 남을 때 오류가 실패 전 처리/파괴적 drain까지 되돌렸다는 뜻이 아님을 계측한다. 기존 P03 suffix attempt-05는 같은 tick issue/Q/Q/S/B/R·실제 restore/suffix 비교를 이미 수행했고, P02 tests/p02_replay_adapter.gd는 late commands[0]의 exact error 및 close와 reorder/removal을 검사했다. 여기서는 최초 미소비 index가 1 이상인 정상 구조 입력과, 같은 자리에 구조 오류가 있을 때의 전체 사전검증 우선순위를 대조한다. 관측 범위는 fresh 내부 owner만이며 운영 host 원자성, durable ledger, 재개 구현을 증명하지 않는다.

사전 조건: 기존 P02 natural fixture와 동결 원문 oracle을 읽어 max_ticks 안에서 자연 종료 tick E가 있음을 확인하고 E보다 뒤이면서 max_ticks 미만인 tick F가 실제 존재해야 한다. 존재하지 않으면 fixture/범위를 심사에 돌리고 임의 예상값을 합격으로 쓰지 않는다. command A는 tick0에서 구조적으로 유효하고 log에 실제 남는 명령, B는 tick F의 유효 명령이다. 독립 raw BattleSim 또는 수기 예상 log/event로 oracle을 구성하고 입력과 예상값을 실행 전 동결한다. fixture 생성/runner는 심사 통과 후 전용 tmp에만 둔다.

명명 검사와 분모(4개 독립 시나리오, 각 예외 조건은 명시 실패):
1. `prefix_then_terminal_unconsumed`: A,B를 Replay._play로 호출. 정확한 실패 `replay_unconsumed_command`, path `commands[1].tick`; observe/summary에서 A 1건 log, B 부재, 실제 종료 tick/clock 확인. _play는 owner를 닫지 않으므로 관측 후 finally에 해당하는 정리로 close. 해당 tick마다 raw drain이 실행된 후 실패하므로 종료 후 즉시 raw drain이 비어 있음을 확인하되 외부 소비 ack로 해석하지 않는다.
2. `invalid_late_prevalidates_all`: A와 같은 자리의 잘못된 B(예: unsupported kind)를 사용. 정확한 `unsupported_replay_command`, `commands[1].kind`; 선행 A 미적용, tick/clock/log/queue/event가 시작 관측과 같음을 확인. 고의로 유효성 검사 단계에서 틀린 필드만 바꾼다.
3. `prefix_only_control`: A만 실행해 정상 종료; A가 한 번 적용되고 지역 commands_consumed=1, ordered events 및 terminal tick/clock이 독립 oracle과 일치. 1과 처리된 log/상태를 비교해 실패 전 실행이 실제 발생했음을 대조한다. 이벤트는 _play 결과가 버려지는 1에서는 owner 내부 잔여와 별개이므로 동일 이벤트를 반환했다고 주장하지 않는다.
4. `closed_error_public_path`: 동일 A,B를 새 owner에 넣어 _play_and_close를 호출; 1과 동일 오류/path 및 이후 owner.summary의 `unprepared_owner`, sim 분리 확인. 성공 결과나 출력 DTO가 없음을 확인한다. CLI 파일 출력 차단은 기존 P02 범위로 두며 별도 실행하지 않는다.

관측은 packet 전체 또는 observe의 실제 제공 필드와 타입·순서로 정하고, 접근 불가 필드는 미검증으로 명시한다. 정규 owner 구조를 훼손하거나 private 상태를 조작하지 않는다. fixture 종료가 불안정하거나 일치 oracle을 만들 수 없으면 실패로 남기고 계획을 재심사한다. 정상 비교는 상태·log/queue·tick·clock과 반환된 ordered raw 사건을 구분한다. 다른 same-tick prefix/pending/suffix 운영 인수 및 A06은 기존 증거와 미결로 남는다.

## 실행·보존·판정 게이트
- 독립 Sol 계획 심사 통과 전 어떠한 runner/fixture/검사 코드도 작성하지 않는다. 반려 시 스펙으로 돌아간다. 공통 생산 코드·공유 체크리스트는 읽기 전용이며 전용 tmp 디렉터리만 작성한다.
- 실행 직전 runner, fixture, 예상 원문, 정본, project.godot, class map, 의존 스크립트/데이터, 실제 Godot console과 본체의 SHA-256·경로·크기를 고정하고 canonical resource_path guard를 둔다. 기존 suffix의 51개 목록을 출발점으로 현재 preload/자원 의존성을 다시 확인하고 누락 또는 변경이면 중단한다. 전후 같은 파일별 해시, 별도 전체 tracked/untracked 상태, P02 동시 변경을 기록한다. 시작 목록 경고는 보존하고 누락을 0이라 주장하지 않는다.
- 실제 프로세스 exit code와 4개 명명 결과·각 단언 분모, stdout/stderr 및 최초 실패를 보존한다. SCRIPT ERROR, ERROR, 누수 및 기존 종료 진단을 각각 분류한다. 실제 엔진 본체 종료를 보장하는 기존 Windows Job 방식의 제한시간을 검토해 재사용하고 timeout은 exit124로 실패, child/PID 회수 검증을 별도 기록한다. 무한 대기 금지.
- 5-a는 exit0, 4/4 명명 통과, 모든 명시 단언 통과, 신규 SCRIPT ERROR/ERROR/누수 0, 입력 전후 SHA 일치 및 범위 외 변경 미발생을 모두 요구한다. 기존 P2c diff --check exit2는 신규 결과와 구분한다. 코드 조각 재시도 K=6(기존 실패 로그 보존), 환경/사용량 제한은 즉시 중단·보고하며 반복하지 않는다. 5-b는 별도 Sol 역할이 결과·원문·전후 diff와 반례를 독립 심사한다. 검사가 통과해도 운영 수용이 아니다.
- P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED 유지. 외부 cursor/commit/idempotency/ack 정책을 새로 정하지 않는다.

## 독립 심사 반영 v2 — 이 절이 위 시나리오·전제보다 우선

2026-11-08, 심사 `REVIEW-PLAN-REPLAY-PARTIAL-20261108.md`의 세 지적에 대한 사전등록. 기존 `natural.json`, `late.json`, `oracle.native`, `oracle.gd`, `oracle.stdout` 및 원본 `tests/fixtures/p02/worker-services.json`을 P02-ORACLE-INPUT-SHA256.json에 실제 해시로 동결했다. P02 `oracle.gd`는 worker-services 원문을 읽어 ally ships=4, foe ships=40, 양측 lv=1/p=0/command=70/start_morale_bp=10000, ally composition=1/1/2, foe composition=40으로 변경하고 seed0/hz10, delegate/delegate, limit18000으로 raw BattleSim을 돌린다. natural.json은 그 profile을 담고 명령 없음, late.json은 같은 경계의 B를 담는다. 이후 비교할 때 전체 profile·입력 동등성을 먼저 검증하며 동등하지 않으면 실행 실패다.

기존 P02 무명령 oracle.stdout의 실제 관측: next-loop summary.tick E=1221, 별도 end_tick=1221, clock_ms=end_ms=122050, over=true, 마지막 battle_end tick1221/value flagship_lost. 이는 A를 넣은 결과가 아니다. F=17999, max_ticks=18000으로 사전등록하여 과거 무명령 관측은 1221<17999<18000을 만족한다. 현재 코드 및 A 추가 후에도 정확한 값이 유지되는 것은 미검증 가설이다. 심사 후 실행할 독립 raw BattleSim oracle은 A를 포함하고 over=true, terminal battle_end, E=1221, end_tick=1221, clock_ms=end_ms=122050, E<F<max_ticks 및 원문 기대 A log를 모두 확인해야 한다. 하나라도 다르면 실패하고 스펙 재심사하며 F를 사후 조정하지 않는다. oracle 출력과 SHA를 대상 검사 전에 동결하고 출처·실행 exit·엔진 및 전후 입력 SHA를 별도 기록한다. 이 oracle 생성도 심사 통과 전 금지다.

A는 `{tick:0,side:0,ids:[9999],kind:"stop",target_id:-1,point:[0,0],args:{}}`. 존재하지 않는 id에 대한 전술 거부를 의도하며 JSON point는 파싱 후 Vector2(0,0), log는 tick0 및 나머지 필드 정확 보존을 기대한다. `no_selection` 거부 사건과 자연 종료는 독립 raw oracle의 필수 전제이며 기존 무명령 결과만으로 확정하지 않는다. B는 late.json 원문 `{tick:17999,side:0,ids:[1],kind:"move",target_id:-1,point:[720,510],args:{}}`; 변형 B-invalid는 kind만 `unsupported_for_probe`로 바꾼다. 동일 구조를 따르는 사본을 각 실험에 입력한다. F에서 실제 실행할 것을 기대하지 않는다.

검사는 각각 정확히 8개 독립 단언, 4개 이름/총 32개다. 아래 묶음의 한 번호는 조건이 여러 개인 경우에도 한 번의 명시적 Boolean 단언이다. 검사 시작/종료 이름 및 1~8 고유 ID를 기록하고 정확히 한 번씩 실행한다.

1. `prefix_then_terminal_unconsumed` (8): ① owner 생성 성공 ② A 포함 raw oracle의 위 자연 종료·정확 E/end/clock 및 terminal event/부등식 전제 ③ _play 결과 정확 `{ok:false,error:replay_unconsumed_command,path:commands[1].tick}` ④ 관측 성공 및 log가 정확히 A 하나 ⑤ pending 비어 있고 B 부재 ⑥ summary over/tick/end_tick/clock_ms/end_ms가 A 포함 raw oracle과 같음 ⑦ 즉시 raw drain 성공·빈 배열 ⑧ owner close 후 unprepared_owner. ④⑤는 capture_completed packet view의 실제 공개 관측값을 사용하며 지원 불가시 PASS가 아니라 실패로 처리한다.
2. `invalid_late_prevalidates_all` (8): ① owner 생성 ② 시작 packet/summary 캡처 성공 ③ 결과 정확 `{ok:false,error:unsupported_replay_command,path:commands[1].kind}` ④ 후속 packet/summary 캡처 성공 ⑤ tick/clock 동일 ⑥ log 동일·비어 있음 ⑦ queue 동일·비어 있음 ⑧ packet event 배열 원형 동일 및 close 성공. 초기 spawn 사건을 무조건 빈 배열로 가정하지 않는다.
3. `prefix_only_control` (8): ① owner 생성 ② A 포함 raw oracle 전제 충족 ③ _play 성공 ④ commands_consumed 정확히 1 ⑤ summary 전체와 타입을 raw oracle에 비교 ⑥ 순서 있는 events 전체와 타입을 raw oracle에 비교 및 terminal event 포함 ⑦ 캡처 성공·log 정확히 A 하나·pending 비어 있음 ⑧ 1번의 해당 log/summary와 일치 및 close 성공. 1번의 반환 이벤트가 보존된다는 주장은 하지 않는다.
4. `helper_close_error` (8): ① 새 owner 생성 ② _play_and_close 결과 오류 DTO 전체가 1번과 동일 ③ ok=false ④ error 정확 ⑤ path 정확 ⑥ 성공용 summary/events/meta 키 부재 ⑦ 이후 summary의 `unprepared_owner` 정확 DTO ⑧ sim null. 중복 비교라도 각 단언 ID를 별도 기록한다. `_play_and_close`는 내부 helper이며 공개 `Replay.run`이나 CLI 계약을 이번 네 검사로 주장하지 않는다.

중간 분기에서 실패하거나 단언 미실행·중복·카운트 불일치가 생기면 누락을 별도 기록하고 runner nonzero 종료한다. 비정상 종료·스크립트 예외로 runner 자체 집계가 불가능하더라도 외부 게이트는 actual exit=0, 정확한 네 이름 각각 8개 고유 단언과 총 32개, 전부 PASS, 시작/종료 마커, 진단 검사 및 hash 일치가 모두 있어야만 성공한다. 타임아웃/런처 실패/결과 파일 부재도 실패다. 한 상황에서 조건 검사를 끝까지 수행할 수 없으면 강제로 PASS를 채우지 않는다.
