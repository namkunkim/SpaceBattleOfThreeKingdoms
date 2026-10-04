# M2 데이터 정본화: 구현 메모

2026-10-04, 구현 세션. 브랜치 `feature/battle-core-m2`. 설계 문서(`docs/battle-core/`)는 컨셉 세션이 맡으므로, 구현에서 나온 사실과 편차는 여기에 적는다.

## 1. 한 일

코어가 규칙 수치와 편성을 코드 상수가 아니라 JSON에서 읽는다.

```
data/profiles/poc_corridor.json   POC 프로필: rules(81개 키) + ally/foe/reinf 편성. M1 기준선과 같은 값
data/profiles/red_cliffs_rt.json  적벽 프로필 정의: 시나리오 경로, base 프로필, rule_overrides, 세력→진영 매핑
data/scenarios/red_cliffs_208_realtime.json   (컨셉 세션 소유. 생성기 tools/scenario/make_red_cliffs_208.py)
core/battle/rule_set.gd           RuleSet   규칙 수치 사전 rs.v, 규칙 함수(flank_mul, power …), 시나리오 데이터 rs.scenario
core/battle/scenario_profile.gd   ScenarioProfile  시나리오 + 프로필 정의 + 난이도 → BattleSim이 받는 프로필 사전
core/battle/profile_loader.gd     ProfileLoader    코어에서 파일을 여는 유일한 곳
core/battle/poc_setup.gd          PocSetup  POC 프로필 로더(편성 상수는 없다)
core/battle/rules.gd              BattleRules  단위 환산·순수 수학·진형 좌표만 남았다(규칙 수치 없음)
```

- `BattleSim.new(seed, hz, profile)`의 세 번째 인자가 프로필이다. 비우면 POC 프로필이라 기존 호출(호스트, 기존 테스트)은 그대로다.
- 규칙 값은 코어에서 `R.<키>`(= `rs.v`)로 읽는다. 키 이름이 `_bp`·`_ms`·`_n`으로 끝나면 정수, 아니면 실수로 읽는다(JSON은 숫자를 모두 실수로 주기 때문).
- 호스트(`scripts/FleetBattle3D.gd`)의 `ALLY_DEF`·`FOE_DEF`·`REINF_DEF`는 const에서 프로필을 읽는 var로 바꿨다. 화면 쪽 사용처(`deck_screens.gd`)는 그대로 동작한다.

## 2. 적벽 프로필이 하는 일

`ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", 난이도)`:

| 시나리오 데이터 | 코어에서 |
|---|---|
| `difficulty_policy.cao_scale_rule` | 조조군(`deploy_min_difficulty`가 있는 전대) 함종별 척 수 × `count_factor`, half-up(정수 연산), 원래 1척 이상이면 최소 1척. 난이도가 `deploy_min_difficulty`보다 낮으면 배치하지 않는다 |
| `alliance_rule` | 연합 편성은 난이도와 무관하게 7개 전대 |
| `difficulty_profiles.*.start_morale_bp` | 전대마다 `morale_group`별 시작 사기를 `FleetState.start_morale_bp`에 담는다(M4에서 쓴다) |
| `difficulty_profiles.*.ai` | `RuleSet.difficulty_ai()`로 읽는다(M6·M7에서 쓴다) |
| `deploy_delay_s` | 전대 정의의 `wait`(초)로 가고 `FleetState.wait`(틱)이 된다. 선봉 0, 주력 180, 후군 360 |
| `battlefield_bounds` | 전장 크기(1600×900). `rs.world` |
| `realtime_rules`(`status: "proposed"` 포함) | `RuleSet.scenario.realtime_rules`에 통째로 들어 있다. `rs.rt("a.b.c")`로 읽고(배열 인덱스는 숫자 경로), `rs.proposed_paths()`가 잠정값 노드를 모은다 |
| `factions[].control` | player·ai_delegate → 0진영, ai → 1진영(`side_by_control`) |

조조군 전대 수는 입문 4, 표준 5, 상급·극한 7이다(`tests/data_rules.gd`가 확인한다).

**G8-04 잠정값(포획 반경 120, 혼선 2단계 등)** 은 코드 상수가 아니라 `realtime_rules`에서 읽는다. 생성기에 키가 생기면 `rs.rt(...)`로 바로 읽힌다. M9까지 코어가 쓰지 않으므로 지금 할 일은 없다.

## 3. 이번에 일부러 하지 않은 것 (M3 이전이라서)

- **규칙은 POC 규칙 그대로다.** 적벽 프로필도 POC 규칙 엔진으로 돌아간다(화력식, 사거리, 이동 속도, CP, 미사일·함재기). 편성만 정본이다. 그래서 적벽 프로필의 전투 결과는 밸런스 판단 근거가 아니다. 돌아간다는 것(결정론, 투입 시각 준수)만 시험한다.
- 적벽 프로필의 전대 `ships`는 함종 척 수의 합이다. 함종별 성능(SHP-01~08)과 진형(FRM-01~07)은 본편 `data/`에 있는데 이 저장소에는 없다. M3 시작 전에 가져와야 한다(아래 §5).
- 전대 `spd`는 1.0, 초상 `p`는 0이다(데이터가 없다). 진형 슬롯은 POC 기하(`formation_offsets`)를 쓴다.
- 증원(95초 별동대)은 적벽 프로필에 없다(`reinf` 빈 목록). 제안서 §9.1 "증원 삭제"와 같은 방향이다. 증원 목록이 비면 증원 사건은 일어나지 않고, 적이 다 죽으면 곧바로 승리다.
- POC 적 AI가 투입 대기를 다루는 방식은 임시다. 기함은 `wait`를 무시하고, 대기 중이라도 가장 가까운 연합 전대가 700 안에 들어오면 교전한다. 대기 중 전진 속도는 `rule_overrides.ai_advance_speed = 0`으로 껐다(POC는 대기 중에 천천히 전진했다). 정식 투입 대기(거리대 유지 포함)는 M3·M6.
- 유비 선체 0 즉시 패배, 조조 전사·포로 즉시 승패는 M4.

## 4. 정적 검사 (완료 기준 "코드에 규칙 수치 0건")

`tests/data_rules.gd`:

1. `core/` 모든 소스의 숫자 리터럴이 구조 값(0·1·2·3·4·5, 0.5, 1e9, 1e-9, 1000, 10000, 0.001)뿐이다. 3~5는 난수 하위 번호다. 단위 환산 상수(`TICK_HZ`, `TICK_S`, `REF_DT`, `MILLI`, `BP`, `FORM_COUNT`) 정의 줄은 이름으로 허용한다.
2. 검사에서 빼는 곳과 이유: `battle_rng.gd`(해시 산술), `battle_fingerprint.gd`(지문 형식), `tick_clock.gd`(UI 감속 단계와 프레임당 틱 상한 — 시계 정책), `rules.gd`의 `formation_offsets`(진형 슬롯 기하 — M3에서 본편 진형 7종으로 교체).
3. 코어가 읽는 `R.<키>`가 POC·적벽 두 프로필에 모두 있고, 프로필에 안 쓰는 키가 없다.
4. 난이도별 편성·`count_factor`·`deploy_delay_s`·시작 사기·`realtime_rules` 조회·`proposed` 경로·적벽 프로필 결정론·투입 전에 움직이지 않음(대기 전대의 첫 이동 틱 1804 ≥ 1700).

`tests/boundary.gd`의 코어 클래스 목록에 `RuleSet`, `ScenarioProfile`, `ProfileLoader`를 더했다(화면 계층이 참조하면 실패).

## 5. 컨셉 세션에 묻거나 알릴 것

1. **함종·진형 데이터.** M3(피해 √플랫폼, 60초 일제사격, 열 냉각)에 SHP-01~08 성능과 FRM-01~07이 필요하다. 시나리오 JSON에는 ID만 있다. 본편 `data/`에서 가져오는 일(제안서 §9 M2 행의 "함종 8종, 진형 7종")을 이번 M2 범위로 두지 않았다. 본편 파일 위치를 알려 주면 `data/` 아래로 복사하는 별도 단계(M2b)로 하겠다.
2. 시나리오 JSON 변경이 필요하면 생성기를 고쳐 달라는 요청대로 JSON은 건드리지 않았다. 지금까지 필요한 변경은 없다.

## 6. 통계 동등성

POC 프로필의 규칙 수치와 편성을 옮겼을 뿐이다. 200시드 판정 수치는 M1-NOTES §7과 소수점까지 같았다(길이·손실 D, 종료 경로, 증원 시각). 1000시드 결과는 아래에 적는다.

(1000시드 결과는 이 단계가 닫힐 때 추가)
