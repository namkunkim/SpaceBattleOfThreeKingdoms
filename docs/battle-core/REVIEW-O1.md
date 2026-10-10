# O1 리뷰: 코어 편성 모듈

대상: 커밋 0c61aa9(병합 bd7a47b). 리뷰어: 구현과 다른 모델. 코드는 고치지 않았다.
판정: **조건부 수용**. 사용자 승인 전에 아래 "조건" 3개를 처리하거나 O2로 명시 이월한다.

## 범위
- 읽은 것: `core/battle/organization.gd`, `tests/organization_rules.gd`, `tests/autoresolve.gd` diff, `core/battle/command.gd`, `salvo.gd init_fleet`, `scenario_profile.gd`, 시나리오 JSON, 목업 `autoFill()/errs()/tier()`, BATTLE_DECISIONS §T·§T-1.
- 커밋 파일 목록: organization.gd, organization_rules.gd, autoresolve.gd(+`--org auto`), 문서 2개. `ScenarioProfile`·`BattleSim`·`command.gd`는 **변경 없음**(기본 경로 불변 확인).

## 실행한 테스트 (Godot 4.7.2 headless)
| 테스트 | 결과 |
|---|---|
| organization_rules | ORGANIZATION_RULES_OK (84초) |
| roster | ROSTER_PASS |
| data_rules | DATA_RULES_PASS |
| core_rules | CORE_RULES_PASS |
| commander_ai | COMMANDER_AI_PASS |
| victory_rules | VICTORY_RULES_PASS |
| succession_rules | SUCCESSION_RULES_PASS |
| autoresolve `--profile red_cliffs --org auto --policies attack --runs 2` | 완료, 승률 1.0, 종료 cao_morale_collapse, t_mean 476s |

주의: 처음 실행에서 organization_rules가 `Parse Error ... inferred from Variant`(line 69)로 실패했다. 원인은 `.godot/global_script_class_cache.cfg`에 새 `class_name Organization`이 없어서다(커밋 문제 아님). `godot --headless --import` 한 번 뒤 통과. 새 클래스를 추가한 조각을 받는 쪽은 먼저 import를 해야 한다.

## 스펙 대조 (이상 없음)
- 직책: 제독1·부제독1·참모 최대3, 보직 무력/지력/정치 맞음(`POSTS`).
- 한도: `limit_base 120 + limit_per_command 6 × 통솔` = (40+통솔×2)×3. 데이터에서 읽음. `command.gd limit_tier`와 같은 비용 기준(ship_types.cost).
- 자동 편성: 제독(기함 고정) → 전 함대 부제독 → 함대 순서대로 강습·공성·보급. 목업 `autoFill`과 같은 순서·MIX·고속정 채움. 동점은 ID 오름차순(목업은 입력 순서라 구현이 더 결정적).
- 고속정: 장비 포함 비용은 `ship_types.SHP-08.cost`(장비 비용 없음)로 계산. 목업과 같음. 장비는 정찰 고정(열린 항목).
- 검증 사유 10종 모두 테스트에서 개별 확인.

## 발견 사항
| # | 심각도 | 위치 | 내용 | 권고 |
|---|---|---|---|---|
| 1 | 중간 | `command.gd:31-36`, `221-250 organization.gd:apply` | 함대 승계(`_successor`)는 시나리오 `fleet_groups[].vice_admiral`(예: FLT-01 = CHR-0134)을 쓰고, 편성한 부제독(`fl.vice`)을 보지 않는다. apply는 `fleet_groups`를 갱신하지 않는다. 그래서 편성을 바꾸면 Q74의 "부제독 → 참모" 승계가 편성이 아니라 옛 시나리오 부제독 기준으로 돈다. 그 장수가 다른 함대로 옮겨졌거나 끈 함대에 있으면 `commander_id == v` 탐색이 빗나가 레벨·통솔 순 후보로 떨어진다. 전대 내부 승계(`_substitute`: f.vice → f.staff[0])는 정상 | O2에서 `fleet_groups` 제거할 때 승계가 함대 vice/staff를 쓰도록 같이 바꾸거나, 그 전까지 apply가 `p.scenario.fleet_groups[].vice_admiral`을 편성 부제독으로 덮는다. 최소한 이월 항목으로 CHECKLIST에 기록 |
| 2 | 중간 | `organization.gd:216-253` | `apply`가 validate를 호출하지 않는다. 잘못된 편성(제독 "" 또는 세력 밖 ID)이면 `pool[fl.admiral]`에서 런타임 오류. 문서 주석은 "validate가 빈 배열인 편성만"이라 호출자 책임이지만 O4 화면·재생 헤더(외부 입력)가 경로에 있다 | apply 첫 줄에서 validate 실행, 비면 `{}` 반환 + push_error. 재생 헤더 입력은 특히 필요 |
| 3 | 중간 | `organization.gd:240-250` | 원본 승계 요소가 편성과 어긋남: 참모 순서가 승계 순서(`f.staff[0]`)에 쓰인다. 자동 편성은 `[강습, 공성, 보급]` 고정이고 빈 칸은 건너뛰어 앞당긴다(보직 정보는 `post`에만). 기본 편성은 원래 순서를 유지해 불변이지만, 보직과 승계 순서를 사양에 명시하지 않았다 | 사양에 "참모 승계 순서 = 배열 순서"를 적거나 강습→공성→보급 순으로 정렬한 것을 테스트 |
| 4 | 중간 | `organization.gd:60-110` | 검증 누락: (a) `mission_equipment_id` 모르는 값, (b) 같은 함종 중복 항목, (c) 출전 함대가 프로필에는 있으나 org에 없는 경우(그 함대는 원본 장수 그대로 남아 중복 가능), (d) `count` 정수 아님/키 없음. 모두 크래시 또는 조용한 이상 동작 | (c)를 `unknown_fleet`류로 막기(프로필 전 함대가 org에 있어야 함). (a)는 `FAST-EQ-*` 목록 검사 |
| 5 | 중간 | `organization.gd:177-191`, `autoresolve.gd` | 자동 편성 뒤 조조 함대는 `count_factor`가 무시되고 전부 한도까지 찬다(난이도별 규모 차이가 사라짐). Q82/O2에서 함대 수 목표로 바뀔 예정이라 의도된 것으로 보이지만 O1 단독으로 `--org auto` 기준선은 난이도 간 변별이 약해진다. 또 조조 SHP-08의 `FAST-EQ-INTERCEPT`가 `FAST-EQ-RECON`으로 바뀐다 | O3 전에 문서화. 장비 선택은 T-1 열린 항목 그대로 |
| 6 | 낮음 | `organization.gd:166-169` | 장수가 모자라면(`pick`이 "") 해당 직책이 조용히 비고 뒤 함대가 참모를 못 받는다(보직별이 아니라 함대 순서 우선이라 앞 함대 편중). 현재 조조 7함대/71명으로는 문제 없으나 O2에서 함대가 늘면 발생 | O2 인수 조건에 "가용 장수 ≥ 함대수×5" 추가, 또는 부족 시 사유 코드 |
| 7 | 낮음 | `organization.gd:233`, `d.level = 1` | 제독이 바뀌면 레벨 1로 리셋. 의도로 보이나 사양 문서에 없음. 기함 제독은 고정이라 비기함에만 영향 | 사양 §3에 한 줄 |
| 8 | 낮음 | `organization.gd:239` | `d.traits = a.get("traits")`가 시나리오 사전의 배열을 그대로 공유(깊은 복사 아님). 전투 중 traits 수정 코드가 없어 실제 문제는 없음 | `.duplicate()` |
| 9 | 낮음 | `organization.gd:177` | 기함 제독이 세력 `available_officers`에 없으면 `pool[...]` 키 오류. roster 테스트가 데이터 쪽에서 보장하지만 방어가 없음 | `.get` + 건너뛰기 |

## 결정론·재생
- 사전 순회: `pool`·`n`(함종 카운트)은 삽입 순서 사전이고, 선택은 능력치+ID 비교로 순서 무관, 함종은 `keys.sort()`로 정렬. 비결정 요소 없음. 테스트가 JSON 문자열 동일을 확인.
- 재생: `profile.organization`에 편성 사본이 남고, `apply(새 프로필, 헤더 편성)` 결과가 같은 지문(1000틱, 시드 7)임을 테스트. 헤더에는 난이도가 profile 안에 있어 같이 저장됨. `scn` 의존: 재생 시 같은 시나리오 파일이어야 함(버전 해시 없음, 낮음).
- 기본 편성 `apply(prof, default_org)`가 380초(3800틱) 지문 동일. 단 시나리오 부제독·참모 사전이 `available_officers` 항목(politics·charm 포함)으로 바뀌고 참모에 `post` 키가 추가된다. 현 코드는 id·command·might·intellect·traits만 읽어 영향 없음.

## 기본 경로 불변
- `ScenarioProfile`, `BattleSim`, `command.gd` diff 없음. `Organization`은 호출하지 않으면 아무것도 바뀌지 않음(`class_name`만 추가). 기존 테스트 전부 통과가 그 증거.

## 승계·끈 함대·다른 코어
- 끈 함대: `p.ally/foe`에서 제거. victory·commander AI 테스트는 기본 편성만 돌려 이 경로를 검증하지 않음. `command.gd`는 그룹의 기함 전대가 없으면 그룹을 건너뛰고(`flag == null`) 멤버 `_by_sq`가 null이면 건너뛰어서 크래시는 없음. 단 기함 아닌 전대를 끄면 그 그룹(FLT-02 기함 SQ-03)은 사라져 소속 함대 승계·혼선이 없어진다(의도 확인 필요). 기함 함대는 끌 수 없음(flag_off).
- 지휘 한도: `d.command` 갱신 → `cmd_stat` → `limit_tier`가 새 통솔로 계산됨(테스트로 확인).
- `d.ships`·`composition` 갱신, `hull` 등은 `init_fleet`이 composition에서 계산해 일관됨.

## 테스트 빈 곳
1. 끈 함대 + 자동 편성 + 전투 완주(victory·commander AI 포함) 사례 없음. autoresolve `--org auto`는 끈 함대 없음.
2. 승계: apply 뒤 제독 격침 → 부제독/참모 승계 시나리오 없음(발견 1을 못 잡음).
3. apply에 잘못된 편성 넣기(발견 2), org에 없는 프로필 함대(발견 4c), 장수 부족(발견 6) 사례 없음.
4. 동점 ID 순서를 직접 확인하는 사례 없음(결정론 동일 입력 비교만).
5. 재생 지문이 1000틱·시드 1개. 종료까지 또는 시드 여럿 없음.
6. 조조의 자동 편성 비용이 한도 이하인지는 전체 루프로 확인됨(좋음). 고속정 장비가 `f.equip`에 반영되는지 확인 없음.

## 조건 (처리 후 수용)
1. 발견 1을 O2 인수 조건 또는 이월 항목에 명시(승계는 편성 부제독 기준). 가능하면 apply에서 `scenario.fleet_groups[].vice_admiral` 덮어쓰기.
2. 발견 2: apply에서 validate 실행(또는 호출 규약을 O4·재생 입구에 강제).
3. 발견 4(c) 막기와 테스트 2종(잘못된 org apply, apply 뒤 승계) 추가.

나머지(5~9)는 O2·O3에서 처리해도 된다. 사용자 승인 단계(5-b)에서 위 판정 근거로 제시한다.
