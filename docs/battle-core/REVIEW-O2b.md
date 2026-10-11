# REVIEW-O2b — O2b(95c9ba8) 리뷰

리뷰어: Sonnet(구현은 Opus). 코드 수정 없음, 커밋 없음. 2026-10-11.

## 1. 범위
커밋 95c9ba8: Q83(기본 경로 세 세력 자동 편성), Q84(제한적 승리 = 유비군 출전 함대 전부 도달 + 테스트 4a 복구), 제안서 정정, 지문 테스트 갱신. 기준은 `CHECKLIST-OPEN.md` §8 "O2 리뷰" 항목과 `BATTLE_DECISIONS.md` §T Q83·Q84.

## 2. 실행한 테스트
`--headless --path . --import` 후 각 `-s tests/<이름>.gd`.

| 테스트 | 결과 |
|---|---|
| data_rules | DATA_RULES_PASS (Q82 비율 4난이도 통과, 극한 2.140 확인) |
| roster | ROSTER_PASS |
| victory_rules | VICTORY_RULES_PASS (sec 4, 4a 포함) |
| battle_flow | BATTLE_FLOW_PASS |
| smoke | FLEET_3D_SMOKE_PASS |
| organization_rules | ORGANIZATION_RULES_OK (시드 3판 종료까지 약 20분, 다른 Godot 프로세스와 겹치면 10분 한도를 넘는다) |
| succession_rules | SUCCESSION_RULES_PASS |
| world_link | WORLD_LINK_PASS |
| ui_flow | UI_FLOW_PASS |
| autoresolve `--profile red_cliffs --policies none --runs 1 --rows 1` | AUTORESOLVE_RC_DONE (표준, 연합 사기 붕괴 패배, 1059s, 348s 소요. `--org` 기본값 auto 경로가 돈다) |
| boundary | 기존 실패라 실행하지 않음 |

종료 시 ObjectDB 누수·리소스 경고는 기존과 같다.

## 3. 항목별 검토

### 3.1 Q83 전투 시작 경로
- 게임 직접 지휘: `scripts/FleetBattle3D.gd:151` `Organization.load_auto`. 천하 지도 자동 해결: `scripts/world/battle_brief.gd:43` → `auto_resolver.gd:30`에서 빈 사전이면 `error`를 세팅하고 `false`로 끝나 크래시하지 않는다.
- 테스트용 진입(`battle_flow`, `world_link`, `ui_flow`, `smoke`)은 모두 `FleetBattle3D.init_game`을 거쳐 같은 편성이다. 재생은 `battle_flow.gd:100`이 `load_auto`로 같은 프로필을 만든다. 데이터 비율 검사(`data_rules.gd:121`)도 같은 함수다.
- 본 코드에는 `profile.organization`을 읽어 재생하는 경로가 없다(`grep organization core scripts`는 `organization.gd` 밖에서 0건). 재생 헤더 방식은 `organization_rules.gd:157`(`Organization.apply(load_profile, pa.organization)`)만 검증한다. 즉 "재생이 load_auto를 다시 부르지 않고 기록된 편성을 쓴다"는 요구는 **구현된 재생 경로가 없어 확인할 대상 자체가 없다**. `battle_flow`는 `load_auto`를 다시 불러 같은 지문을 얻을 뿐이라, `auto_fill`이 결정적이라는 가정에 기댄다.
- 이어하기·저장 경로는 이 저장소에 없다(grep 결과 `load_profile`·`BattleSim.new` 호출처는 위 셋과 테스트뿐).
- 남은 `load_profile` 직접 호출은 `hud/ui_kit/org_screen.gd` 계열(편성 화면, 의도적), `tests/*`의 정사 편성 단위 테스트다. 의도된 사용이다.

### 3.2 Q84 판정
- `core/battle/victory.gd:107-118` `_alliance_escaped`. 기함이 `out == ""`이고 `arrived`일 것, 같은 `side 0`·`anchor_faction`(유비) 함대 중 `sunk`·`surrender`이거나(`out == ""` 이고 미도달)이면 실패. `escaped`(탈출 완료)는 통과, 손권군은 `faction` 필터로 제외, 끈 함대는 `apply`가 `sim.st.fleets`에서 빼므로 제외된다. 제안서 §4.12 승패표(556행)와 일치한다.
- 테스트 `victory_rules.gd` sec 4(일부만 도달 → 아님, 전부 도달 → `alliance_escaped`·`limited`)와 sec 4a(격침 함대 + 나머지 도달 → 제한적 승리 아님) 확인.

### 3.3 제안서 정정
§4.12(사용자 말의 "§4.1" 표)와 §4.14의 정정은 Q73·Q74·Q84와 맞다. 정본 문서 안에서 남은 옛 문구는 아래 발견 사항 #5.

### 3.4 지문 테스트 갱신
- `battle_flow.gd:100`: 기대값을 덮어쓴 것이 아니라 재생 프로필을 호스트와 같은 생성 경로로 바꾼 것이다. 라이브와 재생의 지문 동일 검사는 그대로 살아 있다. 정당하다.
- `roster.gd:80`: 기대 함종 숫자를 정사 `RC-LIU-SQ-01`에서 `battle.ALLY_DEF`(실제 편성)로 바꿨다. 정당하나 화면 쪽과 같은 프로필에서 기대값을 뽑으므로 검사력은 "투영이 프로필과 일치한다" 수준이다.
- `data_rules.gd:119-132`: 비율 계산을 `auto_fill` 직접 호출에서 `load_auto` 결과의 `ally`/`foe` 합으로 바꿨다. 허용 오차 ±0.05는 그대로이고 `p.has("organization")` 검사가 추가됐다. 회귀를 숨기지 않았다.
- `smoke`는 변경 없이 통과.

## 4. 발견 사항

| # | 심각도 | file:line | 내용 | 권고 |
|---|---|---|---|---|
| 1 | 중간 | `scripts/FleetBattle3D.gd:151,161` | `load_auto`가 실패하면 빈 사전을 돌려준다. `BattleSim.new`는 빈 프로필이면 POC로 대체하지만(`battle_sim.gd:40`), 바로 뒤 `profile.ally`·`profile.foe`는 빈 사전이라 키 접근 오류를 낸다. 호출부에 빈 사전 방어가 없다. 변경 전 `load_profile`에도 있던 결함이지만 `load_auto`는 실패 지점이 늘었다(`auto_all` 검증 실패). 천하 지도 경로(`auto_resolver.gd:30`)는 방어가 있다 | `init_game`에서 `profile.is_empty()`면 오류 표시 후 중단하거나 POC로 일관되게 대체 |
| 2 | 낮음 | `core/battle/victory.gd:111,116` | `arrived`는 한 번 닿으면 유지되는 플래그(`morale.gd:176`)라, 탈출점을 스친 뒤 벗어난 함대도 "도달"로 센다. 기함(`lf.arrived`)은 이전부터 같다. Q84 문구 "탈출점에 도달"에 맞지만 "머무름"은 요구하지 않는다 | 의도라면 주석에 한 줄. 아니면 `at_exit`로 현재 위치 검사 |
| 3 | 낮음 | `tests/victory_rules.gd:218-238` | 테스트 4·4a는 정사 편성(`_sim`이 `load_profile`)만 쓴다. 자동 편성(게임 기본 경로)에서 유비군 함대 수가 달라질 때의 제한적 승리는 검사하지 않는다. 항복(`surrender`)·끈 함대 제외·손권군 제외도 단독 케이스가 없다(4a는 `sunk`만) | 4b로 `Organization.load_auto` 프로필 1건 + 항복 1건 추가(낮음, 대기열) |
| 4 | 낮음 | `tests/battle_flow.gd:100` | 재생 지문이 `load_auto`를 다시 불러 맞추는 방식이라 "기록된 편성(`profile.organization`)으로 재생"을 검증하지 않는다. 재생 헤더 경로는 `organization_rules.gd:157`에만 있다 | 재생 기능이 생기면(O4 이후) `battle.sim`의 `profile.organization`을 `Organization.apply`로 돌려 지문을 비교하는 검사 추가 |
| 5 | 낮음 | `docs/battle-core/BATTLE-CORE-HANDOFF.md:596`, `DATA-CROSSCHECK.md:181`, `docs/battle-core/SESSION-HANDOFF.md:264` | 옛 문구 잔존: "필수 전대", "함대 `RC-LIU-FLT-01` 전체", "제한적 승리 = 유비 기함 함대 도달만"(264행은 같은 줄 끝에 O2b 정정이 있어 앞뒤가 모순). `PROPOSAL`에는 옛 문구가 없다(`fleet_groups`·"함대 다섯"은 정정 설명으로만 남음). `data/scenarios/base/red-cliffs-demo-setup.json`의 `RC-LIU-FLT-01`은 본편 데모 데이터(정본, 수정 대상 아님) | 위 세 곳에 "Q84로 대체" 주석 또는 문구 교체 |
| 6 | 정보 | `tests/autoresolve.gd:266-268` | 기본 `--org`가 auto로 바뀌어 기존 M4 기준선(`m1_baseline` 등 정사 편성 수치)과 직접 비교하면 어긋난다. 정사 비교는 `--org historical`을 명시해야 한다 | O3 기준선 문서에 기본값 변경을 명기 |
| 7 | 정보 | `organization_rules` 실행 시간 | 시드 3판 종료 재생으로 단독 10분 이상, 병행 시 20분. 다른 세션 실행과 겹치면 외부 타임아웃에 걸린다 | 필요하면 시드 수 축소 또는 단계 분리(낮음) |

## 5. 판정
**수용.** Q83·Q84가 사용자 결정대로 구현됐고 모든 대상 테스트와 autoresolve가 통과했다. 지문 테스트 갱신은 회귀를 숨기지 않는다. #1(빈 프로필 크래시)은 변경 전부터 있던 결함이지만 `load_auto`로 실패 지점이 늘었으니 O4 전에 고치는 것을 권한다. #2~#7은 대기열 수준이다.
