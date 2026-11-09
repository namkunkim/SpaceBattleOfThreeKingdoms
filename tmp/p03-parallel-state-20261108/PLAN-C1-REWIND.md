# P03 비초기 완료 경계 되감기·재실행 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 정본 K07이 권고하는 완료 경계 가운데 **step 반환 이후, 같은 tick의 즉시 issue가 적용·기록·사건 생성을 끝낸 지점**을 기존 제한 메모리 owner로 검증한다. 운영 계약 채택을 전제하지 않는다. 이 조각은 원래 owner가 더 진행한 뒤 과거 동일 context packet으로 교체되고 동일 suffix를 수행하는 한 건이다.

## 차별성과 정책 경계

- [combined-cut](combined-cut/RESULT.md)은 tick 0에서 적용 두 건·pending·발사 직후 미사일을 캡처하고 아직 전진하지 않은 두 번째 owner에 복원했다. 새 조각은 실제 전진한 **미사일 age 100 및 양자화 위치**, tick 1의 즉시 적용 경계, **같은 active owner가 이미 tick 2까지 진행한 상태의 되감기**를 동시에 확인한다. pending/외부 순번을 별도로 추가하지 않는다.
- [clock/RNG](clock-rng/RESULT.md)의 비초기 packet은 새 동일 context owner의 정상 교체이며 명령·투사체가 없다. 기존 [suffix](../p03-command-suffix-20261107/RESULT.md)에는 적용·복원·suffix가 있지만 활성 투사체가 없다. 새 인수는 이 세 부분의 교차 지점이다.
- [K07](../../docs/battle-core/pc-campaign-design/I01-READINESS-DECISION-20261026.md)의 단계 완료/즉시 명령 완료 권고와 현 core의 반환을 연결한다. commit_seq·global cursor·오염/과거 packet 허용 정책, external idempotency/ack/저장은 별도다. 실제 제품 rewind, 이전 UI 보존, WorldLink 및 정책/소유 의존은 [정책 원장](policy-ownership/RESULT.md)과 [UI 경로](ui-callpaths/RESULT.md)에 남긴다. 이 조각은 테스트 owner의 같은 context 정상 복원 한 건이므로 P02 배선이나 공유 변경 없이 수행할 수 있다.

## 고정 fixture와 기대값

- 승인된 미사일 fixture와 같은 POC A/B 기함 위치 (500,500)/(1500,1000), 함선 10, flag true, wait 1000, seed 41, hz 10, controls [], 정본 POC rules, reinf [], module config 없음. profile_id만 p03-c1-rewind다. 제한 owner A 하나를 공개 생성한다. tick 0의 test hook debug_fire_missiles(1,2) 한 번 뒤 공개 advance 한 번. queue/log는 비어 있고 drain하지 않는다.
- 첫 advance 직후 tick/clock/sub/AI timer/next_event_id=1/100/50/450/9. 미사일 ID 2–7, src 1/target 2/side 0, age 100, dead false. 첫 AI는 기함 하나의 주소만 소비한다. 발사 후 값 대비 각 미사일 속도는 `(v + 6.0) + 6.0`이며 위치는 전진한다. 사건은 spawn(1), spawn(2), missile_launch(1,2) 모두 tick 0이다.
- tick 1에서 공개 issue move(1,(600,500))를 호출하고 즉시 P를 capture한다. command log [move@1], 대기 [], owner는 direct, has_move true, move_to (600,500), pos (500,500). 마지막 사건은 `{tick:1,kind:"say",sq:1,other:-1,pos:Vector2(500,500),value:"move"}`. 시계·투사체는 이 명령 때문에 전진하지 않는다. P의 별도 사본을 둬 후속 조작과 restore가 기존 packet을 변경하지 않는지 비교한다.
- suffix는 공개 issue stop(1) 1회와 공개 advance 1회다. A에서 먼저 실행하여 Q를 캡처한다. tick/clock/sub/AI/next_event_id=2/200/50/350/9. log [move@1,stop@1], 대기 [], pos (500,500), has_move false. 사건은 P의 네 건 뒤 tick 1 say(stop) 한 건, 다른 값은 move 사건과 동일하다. 여섯 미사일은 같은 ID/참조로 age 200, P 대비 속도 +6.0 두 번, 위치가 전진한다. 독립 위치 수치는 분모 밖이며 전체 capture exact 비교에 들어간다.
- A에 P를 공개 restore한다. 성공 사전, 이전 Q의 sim/state/fleet과 missile 객체가 교체되고 논리 ID는 새 객체로 해석된다. A 재캡처는 P와 exact이고 Q와 달라야 한다. tick 1 시점의 명령 의도/미사일 진행 및 사건 수를 수기값으로 다시 대조한다. P의 입력 사본이 그대로인지 확인한다. 이 되감기를 제품 host 호출로 세지 않는다.
- 동일 suffix를 같은 공개 진입점으로 재실행한다. 다음 tick 수기값과 log/사건 순서가 위 Q의 독립 기대값을 만족하고 전체 capture가 Q와 exact 일치한다. Q 이후 명령 로그가 중복되거나 age가 300으로 진행하면 실패한다. Variant 타입·메타데이터·Dictionary 삽입 및 배열 순서·float 값까지 exact다. 앞선 P와 Q가 테스트 종료 후에도 보존되는지 검사한다.

## 5a·5b 및 전용 경로

명명 3개 `capture_noninitial_issue_boundary`, `restore_earlier_on_same_owner`, `replay_suffix_after_rewind`. 본시험 실제 Godot exit 0과 고유 성공 marker 하나, 별도 int/float 비교 의도 실패 실제 exit 1과 실패 marker 하나를 요구한다. 실제 engine PID와 본체, canonical OperationPrivateState/BattleSim/BattleState/FleetState, 중첩 Missile은 이전 승인과 동일한 canonical outer member Script identity 및 실제 raw path를 기록한다. Job active 0, 오류·경고·누수 별도, 60초 timeout에서 해당 Job만 종료하고 actual child exit와 124를 보존한다.

승인 후 전용 `c1-rewind/`에만 fixture, runner, 호출기, 동결 manifest와 로그를 만든다. 계획·리뷰, 기존 guard 승인 근거, 실제 runner/입력, Python/PowerShell, console/본체, project/class map, core/battle 전체 GDScript와 실제 데이터 의존, POC/bundle JSON을 정규 절대 경로/크기/SHA로 동결한다. 중복/누락 거부, 별도 manifest SHA, 실행 전후 HEAD/해시/Git 상태 비교 및 P02와 동시 경로 분리를 요구한다. canonical repo headless만 사용하고 import/editor/공유 변경은 없다.

```powershell
$ErrorActionPreference = 'Stop'
$python = (Get-Command python -CommandType Application | Select-Object -First 1).Source
& $python 'tmp/p03-parallel-state-20261108/c1-rewind/run_gate.py' --manifest-sha256 <frozen-sha> --attempt 1
exit $LASTEXITCODE
```

K=3. 실행·실패 원문을 보존한다. 범위, oracle 또는 guard 변경은 독립 재심 뒤 실행한다. 사용량 제한은 즉시 보고·중단한다. 독립 계획 수용 전 구현과 실행을 보류한다. 사후 5b는 비-Astra 독립 모델이 P/Q·재실행 수기값, canonical 객체 근거, 실제 종료, 보존 및 운영 정책 미결을 대조한다.
