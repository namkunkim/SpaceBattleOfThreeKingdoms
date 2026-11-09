# P03 적용 로그·대기 명령·활성 미사일 동시 절단점 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 목표는 제한 owner에서 실제 command_log의 적용 항목 두 개, 아직 대기 중인 한 명령, 활성 미사일이 같은 packet에 들어간 경우의 정상 복원과 다음 틱 한 건이다. A06 운영 조합 전체와는 범위를 분리한다.

## 차별성과 의존 경계

- 기존 제한 suffix 및 remaining-cursor probe의 원문은 즉시·대기·suffix 명령과 사건을 교차 확인하지만 fixture에서 활성 missile/Swarm을 생성하지 않는다. [suffix 원문](../p03-command-suffix-20261107/command_suffix.gd), [cursor 원문](../p03-parallel-cursor-20261108/remaining-cursor-drain/probe.gd).
- 기존 미사일/Swarm fixture는 양성 재결합과 다음 advance까지 비교했으나 queue와 log가 빈 fixture다. [미사일 결과](projectile-target/RESULT.md), [Swarm 결과](swarm-point/RESULT.md). 따라서 고정한 증거 범위에서 세 요소가 함께 존재하는 상태의 복원은 미검증이다.
- [A06 조합 인수표](boundary-closure/A06-ACCEPTANCE.md)의 독립 미결에는 외부 처리 키가 포함된다. 현재 제한 packet에는 운영 command_seq/last_applied_seq, commit_seq, durable cursor/처리키, 외부 효과 ack를 실을 승인된 필드·소유자·정책이 없다. 세 명령은 실제 배열 항목·논리 fleet ID로만 식별한다. 새 필드, 진짜 외부 키, 배송 ack, 사용자 저장 스키마, 실제 제품 발사/host 게시를 만들지 않는다. 외부 seq/ack/schema 합의를 전제하지 않아 이 조각은 독립 실행 가능하다.

## 고정 fixture와 독립 oracle

1. 승인된 미사일 fixture의 POC A/B 두 기함, (500,500)/(1500,1000), seed 41, hz 10, controls [], 지원 profile을 사용한다. profile_id만 p03-combined-cut으로 변경한다. A와 B 두 owner를 생성한다. 초기 사건 두 spawn을 drain하지 않는다. A에서 공개 issue로 side 0 ids [1]의 stop, 이어서 move(point=(600,500))를 각 한 번 호출한다. 둘 다 입력 tick -1, target -1, args {}이며 적용 log는 입력과 같되 tick 0이다. move 적용 직후 f.control=direct, has_move=true, move_to=(600,500), pos=(500,500)다.
2. A의 테스트 훅 debug_fire_missiles(1,2) 한 번으로 실제 BattleSim 발사 상태를 만든다. 이어서 side 0 ids [1] stop을 공개 queue에 한 번 넣는다. 대기 stop은 입력 tick -1, target -1, point Vector2.ZERO, args {}이며 아직 적용되지 않는다. 이 조각에서 발사를 명령 log에 넣지 않는다. P의 log는 [stop@0,move@0], pending은 [stop@-1], 미사일은 ID 2–7, src 1, target 2, age 0, next_event_id 8이다. tick/clock/sub 0/0/0. 초기 spawn(1), spawn(2) 뒤 say(stop), say(move), missile_launch가 순서대로 있다. 모두 tick 0. say 두 건의 sq=1, other=-1, pos=(500,500), value는 명령 이름이며 missile_launch의 sq=1, other=2, pos=(500,500), value=null이다. 동일 tick이므로 배열 순서가 구분 근거다.
3. B에 A가 capture한 P를 공개 same-context restore한다. B는 이전 빈 상태의 sim과 roster가 새 객체로 바뀌어야 하고, 여섯 실제 미사일의 논리 src/target이 B의 새 roster에 연결돼야 한다. 미사일 Script는 canonical enclosing BattleState의 Missile 상수 identity로 확인하고 실제 nested resource_path는 그대로 기록한다. B의 즉시 capture와 A/P는 동일 Variant 타입, typed metadata, 삽입·배열 순서 및 값으로 exact 비교한다. 두 applied 명령이 이미 만든 상태와 사건을 다시 issue하지 않는다.
4. A와 B를 각 한 번 advance한다. 독립 기대값은 tick/clock/sub=1/100/50, log [stop@0,move@0,stop@0], pending [], 위치 (500,500) 유지, has_move=false. 최초 다섯 사건 뒤에 queued stop의 say 한 건이 추가된다. 이유는 queue를 tick 증가 전에 적용하기 때문이다. 두 기함은 거리 밖이고 첫 AI 평가가 다음 ID를 8→9로 한 번 증가시킨다. 미사일 6개의 ID/참조·순서 유지, age 100, 속도는 각 초기값에 +6.0을 두 번 적용하고 위치는 전진한다. 미사일의 초기·최종 좌표의 수기 수치는 분모 밖이며 두 전체 capture의 exact 비교에 포함한다. 명령을 한 번 더 apply했는지는 3개 log 및 6개 사건의 정확 수·순서로 판정한다.

원문 anchor는 battle_sim.gd:142–179,214–216,320–334,504–508,684–724,923–989,1172–1190 및 operation_private_state.gd:206–229,285–293,361–477이다. 이미 수용한 미사일 및 suffix와 겹치는 숫자는 회귀 대조이고 새 인수는 packet 내 공존과 동일 전진이다.

## 5a·독립 5b

명명 3개 combined_cut / restore_active_pending / advance_once_in_order, 별도 Variant int/float 강제 실패 1개. Godot 본시험 actual exit 0, 강제 대조 actual 1 및 각 정확 marker, canonical 클래스와 실제 engine PID·본체, 진단 0, Windows Job active 0을 요구한다. timeout은 60초, 전용 Job만 종료하고 actual child exit와 gate 124를 보존한다. 파싱 오류는 강제 실패 성공으로 집계하지 않는다.

수용 후 전용 `combined-cut/`에 승인된 exact comparator·Job 패턴으로 작성한다. 최초 실행 전 정규 경로/크기/SHA manifest와 별도 manifest SHA를 만들고 승인 계획 및 리뷰, runner/호출기, Python/PowerShell, Godot console/본체·project/class cache·core/battle 전체 GDScript, POC/bundle 및 실제 입력을 동결한다. HEAD/Git status를 기록하고 실행 전후 해시·경로 중복/누락을 검사한다. 동일 canonical repo에서 import/editor 없이 headless 실행하며 P02·동시 경로 상태 차이를 구분한다.

```powershell
$ErrorActionPreference = 'Stop'
$python = (Get-Command python -CommandType Application | Select-Object -First 1).Source
& $python 'tmp/p03-parallel-state-20261108/combined-cut/run_gate.py' --manifest-sha256 <frozen-sha> --attempt 1
exit $LASTEXITCODE
```

K=3, 실패 원문·실제 exit 보존. fixture 기대값 또는 guard 조건 변경은 독립 재수용 뒤 실행한다. 사용량 제한은 즉시 보고·중단. 독립 계획 수용 전 구현 및 실행을 보류한다. 사후 5b는 계획 작성·실행과 독립된 비-Astra 모델이 공존 분모·exact oracle·실제 실행 및 보존을 대조한다.
