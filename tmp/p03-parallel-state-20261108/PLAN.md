# P03 미분류 상태 원장과 제한 경계 검증 계획

상태 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 현재 단계는 읽기 조사와 계획이다. 생산 코드, 공유 체크리스트, Git 및 P02 경로는 변경하지 않는다. 이 파일의 이전 증원 초안은 PLAN-PREVIOUS.md에 보존했다.

## 기준선과 조사 결과

- 시작 HEAD `fb660cea69207fd332e26128643007694910a253`. 실제 작업 트리 파일 해시는 source-freeze.json. START-GIT-*는 조율자 기준선이다. 시작부터 바뀐 `scripts/world/auto_resolver.gd`, `scripts/world/battle_outcome.gd`, `tests/autoresolve.gd`, `scripts/FleetBattle3D.gd` 및 UI/프로젝트 파일은 P03 변경에 귀속하지 않는다. 후속 HEAD/해시 차이는 경로별로 분리한다.
- `p03-state-checkpoint-20261105/STATE-AUDIT.md`의 ST 분류와 31파일·294개 선언 oracle은 선언 기준선이다. Detection 6+5, Supply 7+10 및 완료 4묶음, Chain 20+5, Skill 7+3, Decision 8+3과 host 원장은 재조사 중복에서 제외하고 각 경계의 입력·출력만 교차 참조한다.
- `operation_private_state.gd:10–16,268–293,384–477`은 BattleState scalar 23개와 FleetState 121개를 이름 목록으로 관측한다. 배열 `fleets/missiles/swarms`는 순서 있는 별도 행으로 capture하며 `_idx/_idx_n`은 제외 후 초기화한다. fleet은 새 roster의 위치별 객체에 데이터 복사, projectile은 새 객체를 만들어 append, Supply 필드 및 Detection은 서비스 복원에 위임한다. 런타임 복원은 객체 ID가 아닌 논리 ID를 비교한다.
- `battle_state.gd:58–69,83–87,101–104`와 `battle_sim.gd:218–258`에서 fleet ID와 form_counter는 생성 때 각각 증가, _idx는 배열 길이 변화 때 첫 동일 ID를 취하며 live_target은 dead를 제외한다. owner는 `target_id,pursue_id,fire_id,sup_first`에 -1 또는 현재 roster ID를 요구한다. dead ID의 존재와 실제 소비 가능성은 별개다.
- `battle_sim.gd:172–179,923–989`에서 queue 적용 뒤 tick 증가, 각 하위 걸음에서 clock_ms 증가, ai_timer 감소·보충 및 AI 평가, 최초 하위 걸음에서 salvo 등 tick 모듈을 실행한다. dt는 분할 중 임시 변동 후 복구, sub_ms는 반올림값이다. 시간 제한·증원과 terminal은 실제 경로로 구분한다. TickClock의 hz/speed/acc/dropped는 host 누산이고 `advance`와 `alpha`가 소비한다. P02 host 원장의 UI/worker 소유와 대조한다.
- `battle_rng.gd:9–30`의 profile_id는 생성 시 고정하고 derived 검증으로 대조한다. SHA256 입력은 profile_id, tick, event_id 및 0이 아닌 sub다. 별도 추첨 커서 대신 BattleState.next_event_id와 소비 호출 순서를 검사한다. RNG의 ID 공간과 fleet의 ID 공간을 구분한다.
- `battle_sim.gd:218–258,949–989`에서 profile.reinf에서 온 _reinf_def가 시각 조건 또는 적군 전멸 분기에 쓰인다. reinf, reinf_ms, 새 roster/ID/배치와 spawn→reinforcements 사건을 각각 센다. raw sim과 owner의 profile/restore 거부는 별도 관측이다.
- FleetState `comp0,stages,ammo,wch,wmax,next_fire,supp,stats`는 제한 복원에서 원본 key 배열과 비교된다. `stages` 5단계, stats 정수, supp 문자열과 ammo 등 resource 정수 조건을 각각 기록한다. `ranges,fired,vice,staff,fx`는 이 고정 key 배열 검사와 다른 분기다. 선언, capture, key 검증, 소비 직전 안전성은 각각 별도 열로 판정한다.
- `battle_state.gd:6–26`의 Missile 10, Swarm 8 선언 및 Swarm.pts `pos/a/r/w` 4키는 별도 분모다. `battle_sim.gd:320–356,1172–1212`에서 생성→참조 탐색→이동/피해→제거를 추적한다. next_event_id보다 작은 고유 공격 ID, 기존 src/target ID, side, age/life 범위와 좌표 키 검증은 owner의 구조 규칙이다.
- `command.gd:19–103`의 stats 4키, `assault.gd:13–139`의 stats 3키·각 시도/성공 2칸, `morale.gd:11–185`의 rally_uses·side별 crisis 및 비용·역병 캐시, `victory.gd`의 결산 키가 미분류 후보다. owner의 UNSUPPORTED 거부와 실제 갱신/소비를 분리하고 활성 복원 coverage는 0으로 둔다. Salvo의 `C/terr/terrain_class/sim`은 재생성 및 참조 검증, FleetState 사격·손상 데이터는 값 복구라는 다른 책임이다.

## 독립 조각과 인수 기준

| 조각 | 고정 분모와 산출물 | oracle와 성공 조건 |
|---|---|---|
| S1 기본 상태·FleetState | BattleState 최상위 28, FleetState 121, 별도 참조 4, 고정 Dictionary 8, 추가 key 후보 5묶음. 각 선언을 초기화·갱신·소비·복구 책임에 연결한 원장 | 선언 oracle은 기존 31/294와 비교하고 현재 원문의 변수 선언을 별도로 수기 대조. 각 행에 파일:행, 읽기/쓰기, 현재 capture/restore 분기 또는 비대상 근거를 기록. 주석 hit나 fingerprint 생략은 판정 근거에서 제외 |
| S2 clock/RNG | clock 4 필드, RNG 1 필드+입력 4개, 논리 시간·ID·하위 걸음 6축. 실제 전진→복원→전진 3입력(일반, 비정수 dt 분할, 1차 하위 걸음 종료) | 순수 산술 tick/sub_ms 표, 외부 Python hashlib의 독립 RNG 기대값, 전진 원본과 복원 후 관측의 exact 순서 비교. 기존 terminal 기록은 기준값으로 보존 |
| S3 ID·증원·투사체 | roster 캐시 warm 1, 지원 프로필 1, 제한 증원 거부 3(비어 있지 않은 profile, reinf, reinf_ms), raw sim 2(시각과 전멸 분기), Missile 10+Swarm 8+point 4. 투사체 진행 양성 1과 src/target/공격 ID/point 4 음성 | 새 roster 객체 및 논리 ID, 별도 손계산 증원 시각과 사건 순서, 실패 후 기존 active identity·packet·events·다음 step exact. raw sim 2건은 owner 복원 성공에서 제외 |
| S4 나머지 모듈·동적 효과 | Command stats 4, Assault stats 3, Morale 가변/파생 필드 8, Salvo 인스턴스 4, Victory result의 literal 및 동적 키. 기존 5개 원장과의 참조점 | 동결 소스에서 literal/동적 producer와 direct lookup의 양방향 대조. 배열 순서·키 타입과 삽입순서·참조/만료를 분리. 미확인 경로는 UNCLASSIFIED. 제한 owner에서 비지원 모듈 관측은 활성 복원 증거와 별도 |
 
S1과 S2/S4의 읽기 원장은 병렬 가능하다. S3은 S1 ID 분류와 S2 시간 oracle을 인수한 뒤 fixture를 고정한다. 실제 runner와 운영 정책은 독립 계획 수용 후 다음 단계에서 다룬다. 기존 5b와 반복되는 fixture는 회귀 분모로 따로 기록한다.

## 5a 및 외부 심사

현재 계획 5a는 repo 루트에서 아래를 실행하고 0 exit와 빈 mismatch를 요구한다. 선언 분모가 어긋나면 계획을 보정하고 5b 전에 확정한다.

```powershell
$m = Get-Content tmp/p03-parallel-state-20261108/source-freeze.json -Raw | ConvertFrom-Json
if ((git rev-parse HEAD) -ne $m.head) { throw 'HEAD drift' }
foreach ($f in $m.files) {
    if ((Get-FileHash -LiteralPath $f.path).Hash -ne $f.sha256) { throw "source drift $($f.path)" }
}
if (@(Select-String '^var ' core/battle/battle_state.gd).Count -ne 28) { throw 'BattleState declaration denominator' }
if (@(Select-String '^var ' core/battle/fleet_state.gd).Count -ne 121) { throw 'FleetState declaration denominator' }
if (@(Select-String '^var ' core/battle/tick_clock.gd).Count -ne 4) { throw 'TickClock declaration denominator' }
if (@(Select-String '^var ' core/battle/battle_rng.gd).Count -ne 1) { throw 'BattleRng declaration denominator' }
```

런타임 5a는 S2/S3 조각별 승인 뒤 Godot console `--headless --path <canonical repo> --script <승인된 전용 runner>`를 사용한다. 실행 직전 console/engine/class map/입력·runner의 SHA를 동결하고 canonical resource_path guard, 실제 exit, 예상 분모, SCRIPT ERROR/ERROR/누수 및 기존 종료 진단의 별도 집계를 요구한다. 원장 5a와 runtime 5a는 결과를 합산하지 않는다. 5a 실패는 해당 조각의 원문·명령·stdout/stderr·실제 종료코드를 보존하고 근거 있는 조각별 재시도 최대 K=3. 사용량 제한 시 즉시 보고하고 반복을 중단한다.

계획 5b는 구현과 독립된 다른 비-Astra 모델이 SHA, 분모, 독립 oracle 및 비대상을 수용해야 한다. 런타임 5b는 사후 별도 심사로 before/after·원자성·반례를 확인한다. 5b 반려 시 스펙으로 돌아간다. 결과와 감사·인계는 이 전용 폴더에 남긴다.
