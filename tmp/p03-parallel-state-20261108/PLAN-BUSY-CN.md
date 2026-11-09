# P03 비초기 Cn busy 우선순위와 무변이 거부 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 대상은 제한 owner 공개 restore 한 경로에서 **동일 비지원 Cn 후보가 busy이면 busy, busy가 풀리면 정확 비지원 오류**를 내고, 기존 상태와 다음 전진을 보존하는지 확인하는 한 사례다. busy는 시험에서 직접 설정한다. 실제 thread·callback 재진입, 제품/host, 운영 오류 정책 및 외부 저장은 별도다.

기존 tests/i01b_active_replace.gd:259–265는 정상 packet의 busy 거부, tests/i01b_private_state.gd:370–373은 valid command 및 기타 busy guard, tests/p02_viewer_events.gd:232–237은 잘못된 side와 busy 우선이다. lifecycle 원장은 잘못된 packet과 busy 조합을 정적으로 추적했다. reinf-ms 시험은 준비된 owner에서 비지원 시각 거부만, C1은 비초기 정상 복원만 실행했다. [lifecycle](../p03-parallel-cursor-20261108/remaining-cursor-drain/lifecycle-readonly/LIFECYCLE-LEDGER.md) · [reinf-ms](reinf-ms/RESULT.md) · [C1](c1-rewind/RESULT.md). 새 분모는 비초기 상태의 같은 비지원 후보를 두 guard 상태에서 비교하는 런타임 사례다.

## 고정 입력과 기대값

- POC 두 기함 A/B, 위치 (500,500)/(1500,1000), role line, ships 10, lv 1, flag true, wait 1000, seed 41, hz 10, controls [], reinf [], 정본 POC rules, module config 없음. profile_id p03-busy-cn. A(대상), B(무처리 대조)를 같은 context로 만든다. 둘 다 한 번 공개 advance한 후 공개 queue에 side0 ids [1] stop 한 건을 넣는다. 입력 command tick -1, target -1, point Vector2.ZERO, args {}다. raw 사건을 drain하지 않는다. 투사체는 비어 있다.
- P는 A의 최초 캡처다. tick/clock/sub/ai/next_event=1/100/50/450/2, reinf=false/reinf_ms=-1, log [], pending [stop@-1], roster ID [1,2], 미소비 사건 spawn(1),spawn(2), 둘 다 tick 0. A의 by_id(1/2)를 읽어 warm cache를 만들고 기존 sim/state/fleet/cache 및 매핑 객체를 보관한다. B의 초기 P 일치 및 별도 deep copy로 비교한다.
- M은 P deep copy에서 `view.state.reinf_ms`만 정수 -1→0으로 바꾼다. 정확 단일 diff, _packet_error(M) 빈 문자열, P 및 M의 각 입력 사본을 보존한다. 이 변이는 정상 packet 구조를 통과하나 _restore에서 unsupported_reinforcement다.
- A._busy=true를 fixture에서 직접 설정하고 공개 restore_completed(M)을 호출한다. 기대 정확 사전 {ok:false,error:"busy"}. 테스트는 그 직후 busy=true/ready=true, sim/state/fleet/cache identity 및 cache 키·매핑·길이와 raw log/queue/사건이 그대로인지 확인한다. busy 중 capture는 사용하지 않고, fixture가 busy를 false로 되돌린 뒤 capture가 P와 exact인지 확인한다. 강제 busy 자체를 자연 경합 도달 증거로 세지 않는다.
- 동일 A와 M으로 busy 해제 뒤 공개 restore를 호출한다. 정확 {ok:false,error:"unsupported_reinforcement"}. busy=false 및 기존 객체·warm cache·ready·전체 P와 M, raw log/pending/events가 보존돼야 한다. 정상 P의 양성은 독립 근거로 기존 C1/reinf-ms를 인용하며 이 조각에서는 A의 동시 두 실패 전후 비교를 흐리지 않도록 추가 restore를 하지 않는다.
- A와 B가 각각 공개 advance 한 번. 수기값 tick/clock/sub/ai/next_event=2/200/50/350/2, reinf=false/-1, log [stop@1], pending [], 좌표 (500,500)·has_move=false. 초기 두 spawn 뒤 tick 1 say(stop) 한 건, sq 1, other -1, pos (500,500), value stop. A와 B의 전체 capture exact 일치, 기존 P와 M 입력도 유지돼야 한다. 타입, typed metadata, Dictionary 삽입·배열 순서 및 float 값을 모두 비교한다. 정본 근거 operation_private_state.gd:165–168,223–229,285–293,316–329,361–373,429–430 및 battle_sim.gd:172–179,504–508,923–989.

## 5a·5b

명명 3개 `busy_precedes_unsupported_cn`, `unbusy_rejects_same_candidate`, `progresses_after_both_rejections`. Godot 실제 본시험 exit 0, 별도 Variant 타입 강제 실패 actual 1, 단일 성공/실패 marker, canonical owner/sim/state/fleet 경로, 실제 engine PID/본체·console, 진단/누수 0과 전용 Windows Job 종료 active 0을 요구한다. parser 오류는 실패 대조 통과로 세지 않는다. timeout 60초, 해당 Job만 종료하고 124 및 actual child exit를 기록한다.

독립 수용 이후 전용 `busy-cn/`에서만 fixture, exact comparator·Job 호출기, manifest 및 결과를 작성한다. 실제 실행 직전 runner/호출기, 승인 계획과 리뷰, Python/PowerShell, Godot console/본체, project/class map, 전체 core/battle GDScript, POC/bundle 및 실제 데이터 의존을 정규 경로·크기·SHA로 동결한다. manifest 별도 SHA, 입력 중복/누락 실패, 실행 전후 SHA/HEAD/status, P02 및 동시 경로 분리. canonical headless만 사용하며 import/editor와 공유 변경은 없다.

```powershell
$ErrorActionPreference = 'Stop'
$python = (Get-Command python -CommandType Application | Select-Object -First 1).Source
& $python 'tmp/p03-parallel-state-20261108/busy-cn/run_gate.py' --manifest-sha256 <frozen-sha> --attempt 1
exit $LASTEXITCODE
```

K=3. 기존 실패 로그를 보존한다. 범위/oracle/guard 변경은 독립 재심 뒤 실행한다. 사용량 제한이면 즉시 보고·중단한다. 독립 계획 수용 전 구현·실행 금지. 사후 독립 비-Astra 모델이 기존 근거 중복, 정확 우선순위, 전후 객체·입력 불변 및 실제 종료·보존을 대조한다.
