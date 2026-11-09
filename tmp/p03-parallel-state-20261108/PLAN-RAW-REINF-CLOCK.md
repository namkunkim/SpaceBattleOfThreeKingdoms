# P03 raw sim 시각 증원 경계 검증 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. raw BattleSim의 시간 증원 한 건만 실행한다. 제한 owner, C0/Cn 복원, 적 전멸 증원 분기, 운영 host/P02 및 기본 95초 시나리오 전투는 별도다. 계획 독립 수용 전 runner/실행을 보류한다.

## 고정 입력과 독립 시간·상태 oracle

- seed 41, hz 10. profile_id p03-raw-reinf-clock, combat/scenario/ai 없음. rules는 PocSetup.profile().rules의 깊은 복제에서 `reinf_ms=100` 정수 하나만 바꾼다. 이는 raw sim용 의도적 규칙 오버라이드이며 제한 owner의 허용 입력으로 보지 않는다.
- ally와 foe는 기존 projectile 조각의 A/B 각 한 기함 정의를 사용한다. `{name:"A"/"B",role:"line",ships:10,lv:1,x:500/1500,y:500/1000,p:0,flag:true,wait:1000}`. reinf 배열은 `[{name:"R",role:"line",ships:7,lv:1,x:2100,y:1400,p:0,flag:false,wait:1000}]`. AI 첫 평가는 적 기함이 거리 밖이라 대상 -1만 설정한다. 새 증원 생성은 두 번째 틱 첫 하위 걸음이고 그 틱에는 다음 AI 평가가 없다. 입력을 실행 중 바꾸거나 debug 훅을 호출하지 않는다. `BattleSim.new(...)` 후 실제 `step()` 3회다.
- 첫 step은 50ms/100ms에 도달한다. 증원 조건은 `clock_ms > R.reinf_ms`라 100ms에서 발동하지 않는다. 둘째 step 첫 하위 걸음인 150ms에 증원이 생성되고, 이후 200ms까지 진행한다. 셋째 step이 같은 조건을 넘어서도 st.reinf가 true라 재발동하지 않는다. 적 기함이 살아 있으므로 적 전멸 분기는 성립하지 않는다.

| 경계 | tick | clock_ms | sub_ms | reinf | reinf_ms | roster IDs | next_id / form_counter | 미소비 사건 |
|---|---:|---:|---:|---|---:|---|---|---|
| 생성 | 0 | 0 | 0 | false | -1 | [1,2] | 3 / 2 | spawn(1), spawn(2), tick 0 |
| 첫 step, 정확히 문턱 | 1 | 100 | 50 | false | -1 | [1,2] | 3 / 2 | 동일 |
| 둘째 step, 문턱 초과 | 2 | 200 | 50 | true | 150 | [1,2,3] | 4 / 3 | 기존 두 건 뒤 spawn(3), reinforcements, tick 2 |
| 셋째 step, 재발동 없음 | 3 | 300 | 50 | true | 150 | [1,2,3] | 4 / 3 | 동일 |

- 생성 직후와 셋째 step의 증원 객체는 ID 3, side 1, name R, role line, ships/max_ships/shown=7000, lv 1, form_id 2, flag false, pos/home/spawn=(2100,1400), wait=10000, dead=false. 둘째 step이 끝난 시점부터 비교한다. 기본 이동 명령 없음과 거리 조건으로 초기 좌표 유지가 예상된다. 모든 위치는 타입 포함 exact. heading처럼 양자화되는 실수는 수기 오라클에 포함하지 않는다.
- 사건 4건은 `{tick,kind,sq,other,pos,value}` 순서의 키를 비교한다. spawn은 sq 해당 ID, reinforcements는 sq -1이며 모두 other -1, pos Vector2.ZERO, value null이다. 기존 두 fleet의 객체 identity와 증원 객체 identity는 이후 step에서 동일해야 한다. by_id는 생성 직후 1·2를 읽어 캐시를 먼저 warm하고, 첫 step 후에도 3은 null, 둘째 이후는 3이 새 roster의 세 번째 객체에 연결돼야 한다. queue/log 및 투사체 배열 비어 있음, 종료 false 및 각 진영 살아 있는 기함을 경계마다 비교한다.

## 5a 및 사후 5b

명명 3개 `threshold_is_strict`, `timed_spawn_at_150ms`, `no_second_spawn`. 승인 이후 전용 `raw-reinf-clock/`에 runner/Job 호출기를 작성한다. 실제 Godot 본시험 exit 0, 검사기의 독립 타입 불일치 대조 exit 1 및 각 정확 단일 marker를 요구한다. parser/엔진 오류·경고/누수와 의도적 실패를 구분한다. 실제 객체의 BattleSim/BattleState/FleetState canonical script 경로를 확인한다. 엔진 PID 및 console/본체, timeout 60초·전용 Job active 0을 기록한다. 새 조각에 중첩 projectile guard는 없다.

실행 직전 고정 manifest에 HEAD, Git 상태, console 및 본체·Python·PowerShell·project.godot·class map, core/battle 전체 GDScript, POC/bundle JSON과 실제 의존 입력, 승인 계획·리뷰 및 runner·호출기의 정규 경로·크기·SHA를 기록한다. manifest SHA를 별도 고정하고 경로 누락/중복, 해시 변경을 실패로 처리한다. canonical repo headless만 사용하며 import/editor 호출은 없다. 실행 뒤 SHA/HEAD/Git 상태를 재확인하고 P02 및 동시 세션을 구분한다.

```powershell
$ErrorActionPreference = 'Stop'
$python = (Get-Command python -CommandType Application | Select-Object -First 1).Source
& $python 'tmp/p03-parallel-state-20261108/raw-reinf-clock/run_gate.py' --manifest-sha256 <frozen-sha> --attempt 1
exit $LASTEXITCODE
```

K=3. 재시도마다 이전 원문/로그·실제 exit 보존. 사용량 제한 시 즉시 보고하고 반복 중단. 사후 5b는 비-Astra 독립 검토자가 분기, 100→150→200 손계산, 고정 입력, 사건 순서, runtime/Job·해시 원문을 대조한다.
