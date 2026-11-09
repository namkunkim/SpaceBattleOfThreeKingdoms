# P03 Swarm 점 숫자 타입 단일 거부 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 제한 owner가 Swarm 점의 반경 타입 하나를 거부하고 기존 상태를 보존하는지 확인한다. Swarm 발진은 test debug 훅, 복원은 공개 정상 진입이다. 실제 플레이 발진·명중 피해, 점 키 누락/순서 변이, src/target 음성, 운영 복원은 범위 밖이다. 독립 수용 전 runner·실행을 보류한다.

## 입력과 기대값

- 기존 projectile-target 조각의 A/B 기함 좌표 (500,500)/(1500,1000), 함선 10씩, role line, flag true, wait 1000, seed 41, hz 10, controls [], PocSetup 규칙을 재사용한다. profile_id는 p03-swarm-point, reinf는 빈 배열, combat/scenario/ai 키 없음. 같은 context A(거부), B(양성), C(무처리)를 각각 생성하고 tick 0에 각 sim.debug_launch_fighters(1,2)를 한 번 호출한다. 명령과 drain 없음.
- 수기 초기 oracle은 Swarm 1개(id=1, src_id=1, target_id=2, side=0, life=9050, striking=false), next_event_id=2, pts 22개다. 각 점의 키 순서는 `pos,a,r,w`, 타입은 Vector2,float,float,float. POC 설정의 r0/r_rand를 근거로 r은 [20.0,70.0)이다. 초기 미소비 사건은 spawn(1), spawn(2), `{tick:0,kind:"fighter_launch",sq:1,other:2,pos:Vector2(500,500),value:null}`다. 발진 RNG 위치·각도·속도의 개별 숫자는 독립 수기 오라클 분모 밖이며 세 capture exact에 포함한다. 근거 battle_sim.gd:336–355, POC swarm_life_ms/swarm_points_n/swarm_r0/swarm_r_rand.
- B가 capture한 원본 P의 깊은 복사 M에서 `view.swarms[0].pts[0].r = int(P.view.swarms[0].pts[0].r)` 한 필드만 바꾼다. 수치의 정수 절삭도 같은 경로에만 해당한다. 원본 TYPE_FLOAT, 변이 TYPE_INT, 키/순서 동일, 나머지 값·타입·메타데이터 그대로. 독립 exact comparator가 단일 경로만 보고해야 한다.
- 공개 restore 이전 `_packet_error(M)`이 빈 문자열이어야 한다. A의 공개 restore는 정확 사전 `{"ok":false,"error":"swarm_point_number"}`다. 같은 점의 pos, a, w와 상위 ID·life·side는 원본과 같으므로 예상 거부 위치는 operation_private_state.gd:446–453의 float 검사다.
- 거부 직전·직후 A의 sim/state/두 fleet/Swarm 객체, 첫 pts Dictionary 객체, warm by_id 캐시 identity·키 [1,2]·매핑·길이 2, ready=true/busy=false, 전체 capture 및 M, raw 사건과 빈 queue/log를 비교한다. 모듈은 비활성이고 서비스 packet은 exact capture에 포함한다.
- 양성 B는 원본 P 공개 restore 성공, 새 sim/state/fleet/Swarm/첫 점 객체, by_id를 통한 src/target 연결, 전체 capture P와 exact 일치를 기대한다. canonical OperationPrivateState/BattleSim/BattleState/FleetState resource_path를 실제 객체에서 확인한다. 중첩 Swarm은 이전에 승인된 Missile 기준과 같은 원리로 실제 canonical outer BattleState 스크립트의 상수 `Swarm`과 runtime·prototype Script identity가 모두 일치해야 한다. 실제 nested resource_path를 빈 값이어도 그대로 로그로 남긴다. 문자열 형식의 기대값은 지정하지 않는다.
- A/B/C를 각각 한 틱 advance한다. tick 1, clock_ms 100, sub_ms 50, next_event_id 3, life 8950, id/src/target/side 및 point 수 유지, striking false, 사건 세 건 유지. 적 기함은 거리 밖에서 첫 평가에 ID 하나만 소비한다. 초기 점이 발사 전대 부근에 있고 보간 두 번으로 표적 120px 안에 닿지 않는 것은 거리와 goal k 0.11×2에 근거한다. 첫 점의 a는 `(a + w * 0.05) + w * 0.05`, r과 w 그대로이고 pos는 변한다. 좌표의 정답은 세 전체 capture exact로 대조한다. Variant 타입/typed metadata/키 삽입 및 배열 순서/float 동일 값을 요구한다.

## 5a와 독립 검토

3명명 `launch_and_point_candidate`, `positive_swarm_rebind`, `reject_point_and_advance`. Godot 본시험 exit 0, 별도 int/float 의도 실패 exit 1 및 정확 marker, 실제 PID/console/본체, Job 총/active, 진단 0을 검사한다. 각 명명과 probe는 실제 exit를 보존한다. 파싱 오류는 의도 실패 성공으로 집계하지 않는다.

승인 이후 전용 swarm-point/에 runner 및 Job 호출기를 둔다. 실제 입력·runner·Python/PowerShell·engine/console·project/class map·전체 core/battle GDScript·POC/bundle 데이터·승인 계획과 리뷰·정상 선행 guard 기준과 리뷰를 정규 경로/크기/SHA로 고정하고 manifest SHA를 별도 기록한다. 실제 canonical repo에서 import/editor 없이 headless 실행한다. 실행 뒤 같은 파일/HEAD/Git 상태를 검증하고 P02·동시 세션 상태를 구분한다. 60초 timeout에서 전용 Job만 종료하고 124 및 실제 child exit를 보존한다.

```powershell
$ErrorActionPreference = 'Stop'
$python = (Get-Command python -CommandType Application | Select-Object -First 1).Source
& $python 'tmp/p03-parallel-state-20261108/swarm-point/run_gate.py' --manifest-sha256 <frozen-sha> --attempt 1
exit $LASTEXITCODE
```

K=3. 실패 원문/명령/실제 exit 보존. 기대값 또는 guard 변경이 필요하면 새 변경안을 독립 수용하기 전 실행하지 않는다. 사용량 제한은 즉시 보고하고 반복 중단한다. 사후 5b는 구현 독립 비-Astra 모델이 변이·거부·보존·재결합·사후 SHA를 대조한다.
