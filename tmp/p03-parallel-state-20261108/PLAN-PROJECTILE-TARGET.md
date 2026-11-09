# P03 미사일 target ID 단일 변이 복원 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 이 조각은 제한 owner의 공개 restore에서 POC 미사일 하나의 잘못된 target ID를 거부하고, 정상 패킷은 새로운 roster 및 투사체 객체로 같은 논리 참조를 이어가는지 관측한다. src ID는 양성 참조로 확인한다. 별도 src 위조, Swarm, 명중 피해, 실제 플레이 발사와 운영 복원은 후속이다. 독립 계획 수용 전 runner 작성·실행을 보류한다.

## 입력과 고정 기대값

- 이전 reinf-ms 검증의 POC 두 기함 profile, 좌표 (500,500)/(1500,1000), seed 41, hz 10, controls [], 규칙과 fleet 정의를 사용한다. profile_id는 p03-projectile-target로 고정한다. A(음성), B(양성), C(무처리)를 같은 context로 생성한다. queue/log를 비우고 각 sim의 `debug_fire_missiles(1,2)`를 tick 0에서 한 번 호출한다. debug 훅은 테스트 fixture에만 쓴다.
- 발사 oracle은 BattleState.next_event_id가 1에서 8이 되고, 배열의 여섯 missile id가 [2,3,4,5,6,7], src_id가 모두 1, target_id가 모두 2, side가 모두 0, age가 모두 0, dead가 모두 false다. 미소비 사건은 tick 0의 spawn(1), spawn(2), `{tick:0,kind:"missile_launch",sq:1,other:2,pos:Vector2(500,500),value:null}` 순이다. 최초 발사 ID 1은 RNG launch의 주소이고 각 투사체 ID는 그 다음 ID라는 별도 규칙을 대조한다. 근거 battle_sim.gd:214–216,320–334, battle_state.gd:101–104, POC missile_count_n 6.
- B의 capture packet P를 기준으로 M의 `view.missiles[0].target_id` 정수 2만 999로 바꾼다. 999는 현재 roster에 없다. 독립 재귀 exact comparator로 정수 타입 및 정확한 단일 경로 차이를 기록하고, `_packet_error(M)`은 빈 문자열을 기대한다. `restore_completed(M)`의 정확 사전은 `{"ok":false,"error":"projectile_reference"}`다. 예상 거부는 `operation_private_state.gd:316–329,361–373,437–445`의 후보 _restore에서 ID와 타입 검사를 지난 다음이다.
- 음성 A에서 restore 직전과 직후 sim, state, 두 fleet 및 여섯 missile 객체 identity가 같고, warm by_id cache의 identity/키 [1,2]/매핑/길이 2, ready=true/busy=false가 유지된다. A의 전체 packet, 원본 입력 M, events·queue·log를 비교한다. 서비스는 비활성이고 서비스 packet은 전체 비교에 포함한다.
- 양성 B에서 원본 P를 공개 restore하면 정확히 ok true, sim/state/두 fleet/여섯 missile 객체가 교체된다. by_id(1/2)가 새 roster 객체를 반환하고 각 새 투사체의 src/target ID가 이 객체로 해석되어야 한다. 동일 ID의 기존 객체를 보존하는 것으로 해석하지 않는다. 복원 후 P 전체는 exact다.
- A/B/C를 각각 한 틱 advance한다. tick=1, clock_ms=100, sub_ms=50, next_event_id=9, 여섯 배열 ID·src/target·side는 유지, age=100, dead=false. 이 시작 거리는 두 하위 걸음 동안 미사일이 표적에 도달할 수 없으므로 사건은 위 세 개 그대로다. 각 속도는 발사 직후 같은 ID의 값에 `(v + 6.0) + 6.0`을 적용한 float다(120 × 0.05 두 번). 위치는 각 투사체가 전진한 값이며 손으로 만든 exact 좌표 oracle로 주장하지 않는다. 전체 packet과 위치는 원본/복원/무처리 대조의 exact 비교에 포함한다. Variant 타입, typed metadata, 키/배열 순서 및 같은 float 값을 요구한다. POC 적 기함은 거리 조건 때문에 공격하지 않으며 첫 AI 평가가 next_event_id를 8→9로 한 번 늘린다.

## 실행과 독립 심사

명명 3개 launch_and_exact_candidate / positive_rebind / atomic_reject_and_advance. 별도 의도 실패 프로세스 하나를 포함해 Godot 실제 exit 0/1, 각 정확한 단일 marker 및 오류/누수 진단 0을 요구한다. 의도 실패는 검사 helper가 수치 타입 불일치를 검출해 실제 비정상 exit가 나는 대조다. parser 실패는 이 대조를 충족하지 않는다. 5b는 구현 독립 비-Astra 모델이 입력·정확 변이·양성/음성·참조·손계산·실제 종료를 대조한다.

전용 projectile-target/만 사용한다. 수용 후 reinf-ms·clock-rng의 exact 및 Windows Job 호출기 패턴을 재사용한다. 동일 canonical repo의 headless script만 호출하고 import/editor 호출을 하지 않는다. 객체 resource_path로 OperationPrivateState, BattleSim, BattleState, FleetState, 중첩 Missile의 원본 스크립트 경로를 확인한다. 실제 engine PID/본체·console 확인, timeout 60초와 전용 Job active 0, timeout exit 124, 불완전 marker 오류를 기록한다.

최초 실행 직전 manifest에 repo/HEAD/Git status, PowerShell/Python, engine과 console, global class cache, project.godot, core/battle GDScript 전체, POC/bundle JSON과 실제 의존성, runner·호출기·승인 계획과 리뷰를 정규화 경로·크기·SHA256으로 고정한다. 경로 누락/중복을 실패로 처리하고 manifest SHA를 별도로 기록한다. 실행 후 SHA/HEAD/status를 재검증하며 P02 및 동시 경로를 분리한다.

```powershell
$ErrorActionPreference = 'Stop'
$python = (Get-Command python -CommandType Application | Select-Object -First 1).Source
& $python 'tmp/p03-parallel-state-20261108/projectile-target/run_gate.py' --manifest-sha256 <frozen-sha> --attempt 1
exit $LASTEXITCODE
```

K=3. 실패한 조각만 원인 근거를 남겨 재시도하고 모든 실제 종료와 로그를 보존한다. 사용량 제한 시 즉시 보고하고 반복을 중단한다.
