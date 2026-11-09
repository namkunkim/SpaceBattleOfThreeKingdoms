# P03 단일 증원 시각 위조 복원의 원자 거부 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 이 조각은 제한 owner의 공개 `restore_completed`가 같은 context의 비정상 `view.state.reinf_ms` 하나를 거부하고 기존 owner를 유지하는지 검증한다. raw 증원 생성, 프로필 증원 거부, `reinf=true`, `_reinf_def` 조작, projectile, 전체 clock/RNG, 제품/P02, 운영 Cn 및 외부 스키마는 후속으로 분리한다. S1 172개 선언의 읽기 검증은 분리된 결과다.

## 동결 fixture와 독립 기대값

- Profile 키는 `profile_id="p03-reinf-ms"`, `rules=PocSetup.profile().rules.duplicate(true)`, `ally`, `foe`, `reinf=[]` 순서로 구성한다. seed 41, hz 10, controls []다. ally 한 행 `{name:"A",role:"line",ships:10,lv:1,x:500,y:500,p:0,flag:true,wait:1000}`, foe 한 행 `{name:"B",role:"line",ships:10,lv:1,x:1500,y:1000,p:0,flag:true,wait:1000}`. combat·scenario·ai 키는 없다. 초기 roster ID [1,2], sides [0,1], form_counter 2, next_id 3, next_event_id 1, tick 0, clock_ms 0, sub_ms 0, over false, reinf false, reinf_ms -1, projectile 배열 비어 있음. 최초 사건 두 건은 순서대로 `{tick:0,kind:"spawn",sq:1/2,other:-1,pos:Vector2.ZERO,value:null}`이다.
- 동일한 active A, 양성 B, 대조 C를 각각 create한다. 세 owner 모두 `BattleSim.command(0,[1],"stop")` 하나를 queue한다. 초기 pending command의 tick -1, side 0, ids [1], kind stop, target_id -1, point Vector2.ZERO, args {}다. command_log는 빈 배열이다. A의 `by_id(1)`과 `by_id(2)`를 불러 캐시를 따뜻하게 한다. B의 capture packet P를 공통 입력으로 쓴다. P의 두 초기 사건은 drain하지 않는다.
- 음성 M은 P의 독립 deep copy에서 `view.state.reinf_ms`를 정수 -1에서 정수 0으로 한 번 바꾼다. 타입·키·삽입 순서와 나머지 값은 동일하다. 검증 runner의 독립 recursive comparator로 차집합이 정확히 그 경로 하나인지 확인한다.
- 기대 분기와 정확 결과는 `operation_private_state.gd:316–327,361–373,429–430`의 공개 restore → 준비 → 후보 _restore의 `unsupported_reinforcement`다. `_fail`의 정확 오류 사전 `{"ok":false,"error":"unsupported_reinforcement"}`을 비교한다. `_packet_error(M)`이 빈 문자열을 반환하는 것도 별도 확인하여 더 앞선 구조 거부와 구분한다.
- A의 실패 직전/직후 `_sim`, `st`, fleet 1·2 객체 identity, warm `_idx`의 사전 identity, 키 순서 [1,2], 각 매핑의 객체 및 `_idx_n=2`, `_ready=true`, `_busy=false`를 비교한다. capture packet과 입력 M의 별도 복사본, pending 및 raw events는 소비 없이 exact 비교한다. 서비스 모듈은 fixture에서 null로 고정하고 서비스 packet을 capture 비교에 포함한다.
- B에 원본 P로 동일 공개 restore를 실행한다. 정확 `{"ok":true}`, sim·st·fleet 1·2 객체 교체, 새 객체의 by_id 연결 및 재캡처 P의 exact 일치가 양성이다. B의 객체 비교는 재결합 제어이며 별도 활성 기능으로 범위를 확대하지 않는다.
- A·B·C를 각 1회 advance한다. 숫자 oracle은 tick 1, dt 0.1 / REF_DT 0.05 → 2 substeps, sub_ms 50, clock_ms 100, over false, reinf false, reinf_ms -1, roster ID [1,2], queue 빈 배열, command_log는 위 stop에서 tick만 0으로 바꾼 한 건이다. 사건 배열은 최초 spawn 두 건 뒤에 stop이 내는 `{tick:0,kind:"say",sq:1,other:-1,pos:Vector2(500,500),value:"stop"}` 한 건을 덧붙인 순서다. 이후 A·B의 capture 전체와 C를 exact 비교한다. 전체 비교는 Variant 타입, Dictionary 키 타입/삽입 순서, typed Array/Dictionary built-in/class/script, Array 순서 및 동일한 float 값을 포함한다. 수기 oracle의 논리 시간은 모두 정수로 비교하며 0.1/0.05는 분할 근거로만 사용한다. 이 조각에서 RNG 값을 표본 채취하지 않는다.

## 5a와 독립 5b

실제 본시험 명명 3개는 `setup_and_exact_input`, `positive_replacement`, `reject_is_atomic_and_can_advance`다. 셋을 한 프로세스에서 실행하고 성공할 때만 고유 결과 marker 1개와 quit(0)을 낸다. 검증 helper는 누적 실패가 하나라도 있으면 quit(1)로 종료한다. 독립 대조 프로세스 `-- --force-gate-failure`는 전용 플래그에서 의도적인 기대값 불일치 하나를 내고 quit(1), 실패 marker 1개 및 성공 marker 0개를 요구한다. 파싱 실패/누락 marker는 기대된 의도적 실패로 집계하지 않는다. 예상 실제 코드 분모는 본시험 0과 고장 대조 1, 총 2호출이다.

파일은 이 전용 폴더 아래 `reinf-ms/`에 둔다. 승인 이후 새 runner/Job 호출기와 실제 입력을 작성한다. 실행 직전 canonical 원본 repo, HEAD와 Git status, PowerShell/Python, console와 Godot 본체, class map, project.godot, core/battle의 GDScript 전부, POC/bundle JSON과 실제 데이터 의존성, fixture, 호출기, 승인 계획 및 리뷰를 절대 경로·크기·SHA256으로 동결한다. slash/대소문자 정규 경로 중복과 누락을 실패로 처리하며 manifest 자체 해시를 별도 기록한다. 실행 후 같은 목록/HEAD/status를 다시 확인하고 P02/동시 변화와 구분한다.

승인 후 작성할 전용 호출기에서 이전 `p03-active-unsupported-20261108/windows_job.py`를 동결 사본으로 사용해 Windows Job을 격리한다. 최대 60초, timeout이면 해당 Job만 종료하고 timeout 124 및 active=0을 보존한다. Godot은 `--headless --path C:/WorkSpace/SpaceBattleOfThreeKingdoms --script res://tmp/p03-parallel-state-20261108/reinf-ms/reinf_ms.gd`로 순차 실행한다. 프로젝트 import/editor 호출 없이 기존 global class map을 읽고 앞뒤 SHA를 확인한다. 스크립트 시작에서 실제 객체 `get_script().resource_path`로 OperationPrivateState, BattleSim, BattleState, FleetState를 canonical 경로에 대조한다. UID/cache·공유 프로젝트 파일을 편집하지 않으며 실행 중 class map 또는 동결 입력이 바뀌면 해당 결과를 무효화한다. SCRIPT ERROR/ERROR·경고·누수와 의도적 fixture 실패 marker를 구분한다.

```powershell
$ErrorActionPreference = 'Stop'
$python = (Get-Command python -CommandType Application | Select-Object -First 1).Source
& $python 'tmp/p03-parallel-state-20261108/reinf-ms/run_gate.py' --manifest-sha256 <frozen-manifest-sha256> --attempt 1
$actual = $LASTEXITCODE
exit $actual
```

호출기는 자식 실제 exit, stdout/stderr, 판정 JSON, Job 통계, 입력 전후 SHA를 각 시도의 새 폴더에 보존한다. 재시도 상한 K=3, 근거가 있는 해당 조각만 재시도한다. 사용량 제한은 즉시 보고 후 반복을 중단한다. 지금은 계획 독립 수용 대기 단계다. 이후 별도 비-Astra 모델이 실제 입력·대조·원자성·source/HEAD 보존을 검토한다.
