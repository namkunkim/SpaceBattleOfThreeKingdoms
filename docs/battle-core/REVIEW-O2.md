# O2 리뷰: fleet_groups 제거·함대 안 승계·Q82 조조 함대 수

대상: 커밋 22f7e81(병합 eb177be, 28파일). 리뷰어: 구현과 다른 모델(Sonnet). 코드는 고치지 않았다.
판정: **조건부 수용**. 코어·데이터는 스펙(Q73·Q74·Q82)대로 동작하고 테스트는 전부 통과한다. 다만 조건 3개(아래)를 사용자 승인 전에 처리하거나 명시 이월한다. 가장 큰 위험은 기본 경로 난이도 약 2배(발견 1)다.

## 범위
- 읽은 것: `command.gd` 전체(변경 전후), `victory.gd`·`assault.gd`·`scenario_profile.gd`·`organization.gd` diff, `battle_projection.gd`·`battle_view_model.gd`·`battle_source.gd`·`scenario_roster.gd`·`roster_screen.gd`·`command_deck.gd`·`FleetBattle3D.gd` diff, 생성기 diff와 생성된 JSON, 테스트 diff 7개, BATTLE_DECISIONS §T·§T-1, 제안서 §4.1 승패표·§4.14, REVIEW-O1 발견 1·5, REVIEW-O1b #3, REVIEW-O5 #2.
- 잔존 참조 grep(`fleet_groups|group_id|vice_admiral|flagship_squadron_id|cmd.groups|group_view|groups_of|flag_sq`): 코어·뷰·HUD·스크립트·테스트·생성기에는 없다(주석 2곳과 테스트의 "없음" 확인뿐). 남은 곳은 본편 원본 `data/scenarios/base/red-cliffs-demo-setup.json`(POC 데모 setup, 읽는 코드 없음)과 `.claude/worktrees/*` 사본.
- 코어 참조가 지워진 경로: 투영(`fleet_groups`, `group_id`), `FleetView.group_id`, `battle_source.detail().group`, `command_deck` 라벨, 기본 그룹 1~n, 지문(`fingerprint`), 이벤트 `succession`(소비자 없음 확인: hud·view·scripts·core grep에서 `succession` 이벤트 구독 없음). 깨진 경로는 찾지 못했다.

## 실행한 테스트 (Godot 4.7.2 headless, import 먼저)
| 테스트 | 결과 |
|---|---|
| data_rules | DATA_RULES_PASS. 출력: 입문 8함대 1.070 / 표준 12함대 1.590 / 상급 16함대 2.140 / 극한 16함대 2.140 |
| roster | ROSTER_PASS |
| organization_rules | ORGANIZATION_RULES_OK |
| succession_rules | SUCCESSION_RULES_PASS |
| victory_rules | VICTORY_RULES_PASS |
| stratagem_rules | STRATAGEM_RULES_PASS |
| commander_ai | COMMANDER_AI_PASS |
| core_rules | CORE_RULES_PASS |
| ui_flow | UI_FLOW_PASS |
| ui_wording | UI_WORDING_PASS |
| smoke | FLEET_3D_SMOKE_PASS |
| autoresolve `--profile red_cliffs --org auto --policies none --runs 1 --rows 1` | 정상 종료(160초). 표준·none 1회: 연합 패배(alliance_morale_collapse), t=1059s, 조조 함대 12개 모두 합류. 정책 none(플레이어 명령 없음)이라 승률 지표로는 쓰지 않는다 |
| boundary | 기존 실패라 실행하지 않음 |
SCRIPT ERROR 로그는 위 실행에서 0건(O5 #6의 `battle_source.gd:47`도 이번 로그엔 없음). ObjectDB 누수 경고는 기존과 같다. 구현자 정정에 따라 salvo_compare 기본 100회는 1200초 시간 초과, `--runs 2`는 정상이며 그 조건 B(기본 경로 표준)는 2/2 연합 사기 붕괴 패배다(발견 1에 반영, 직접 재실행하지 않음).

## 발견 사항
| # | 심각도 | file:line | 내용 | 권고 |
|---|---|---|---|---|
| 1 | **높음(밸런스)** | `scenario_profile.gd:63-70`, `tests/salvo_compare`(구현자 보고) | 기본 경로(자동 편성 없음)에서 조조 비용 비율이 입문 2.36 / 표준 3.27 / 상급 4.17이다(JSON 계산으로 확인: 연합 1458, 조조 앞 8·12·16함대 비용 합 대비). 이전 1.09/1.65/2.14의 약 2배. 조조 척 수는 입문 158→372, 표준 232→504, 상급 339→636. `cao_last_fill_bp`는 `auto_fill`에서만 쓰이고 `Organization`은 `scenario_profile.gd` 외 게임 흐름에서 호출되지 않아(O4 전) 지금 플레이어가 받는 전투는 이 기본 경로다. 구현자가 보고한 salvo_compare 조건 B(기본 경로 표준) 2/2 연합 사기 붕괴 패배가 같은 원인이다. 즉 O4 전에 이 main을 APK/PC로 배포하면 모든 난이도가 사실상 한 단계 이상 어려워진다 | 승인 조건. (a) O4 완료까지 main을 플레이 빌드에 쓰지 않는다고 명시, 또는 (b) 기본 경로가 `default_org` 대신 3세력 `auto_fill`을 거치게 임시 연결, 또는 (c) 기본 경로 한정으로 추가 함대를 `cao_fleets` 아래 기존 7개로 제한하는 임시 값. 선택은 사용자 결정. CHECKLIST에 "O4 전 빌드 금지"를 적는다 |
| 2 | 중간(규칙) | `victory.gd:107-110` | **기본값 ②** 제한적 승리 조건이 "유비 기함 + 함대 `RC-LIU-FLT-01` 전체 도달"(제안서 §4.1 승패표 :558, G8-04)에서 "유비 기함 함대만 도달"로 바뀌었다. Q73·Q74는 상위 묶음을 없앨 뿐 승패 규칙을 바꾸는 결정이 아니다. 이전 조건은 기함+제갈량 함대+조운 고속정이었다. 이제 기함 하나만 달아나도 제한적 승리라 난이도가 낮아지고 기존 테스트 4a(격침 전대가 있으면 아님)가 삭제됐다 | 사용자 확인 사항으로 올린다. 대안: 유비군 출전 함대 중 생존한 것 전부(격침·항복 제외 규칙은 4a 방식). 최소한 제안서 §4.1 표와 victory.gd:9 주석(여전히 "함대 전체")을 정한 규칙에 맞춘다 |
| 3 | 중간(문서) | `PROPOSAL-realtime-battle-core.md` §4.14(:611-617), §4.1(:558) | 제안서 v0.3이 갱신되지 않았다. 여전히 "함대 다섯", "부함장이 비기함이면 그 전대가 새 기함", "RC-LIU-FLT-01". CLAUDE.md상 제안서가 우선하므로 구현과 충돌한다. BATTLE_DECISIONS §T에 Q73 정정이 있으나 제안서 본문엔 없다 | §4.14·§4.1·`REVIEW-M9` 인용에 "Q73으로 대체" 표기 또는 본문 수정(문서 세션) |
| 4 | 중간 | `command.gd:78-100`, 데이터 `staff:[]` | 기본 경로의 추가 함대 SQ-08~16은 부제독·참모가 없다. 제독이 중상이 되면 승계자가 없어 **끝까지 혼선**(불이익 2단계 영구)이다. 기본 경로 조조 23함대 중 최대 11개(SQ-02,04,06,07 포함)가 부제독 없음. 오류는 아니지만 AI 조조가 기존보다 약해진다(발견 1과 반대 방향의 영향). 자동 편성 경로는 모두 부제독을 갖는다 | 의도 확인. 기본 경로는 O4 전 임시이므로 기록만 |
| 5 | 중간 | `organization.gd:210-216`, 생성기 assert | 장수 부족(발견 6 처리): 상급·극한 16함대는 제독 16 + 부제독 16 + 참모 최대 48 = 80이 필요하나 조조 가용 71명이라 참모 9칸이 빈다. `pick`이 ""이면 건너뛰므로 **크래시 없음**, 함대 순서대로 채워 마지막 3함대(SQ-14~16)가 참모 0이다(부제독은 모두 있어 승계 가능). 생성기 assert는 `>= 2×함대수`(제독+부제독)만 보장한다. `validate`가 "참모 최대 3"만 보고 최소는 요구하지 않는 것도 확인(organization_rules 통과). 후속: 참모 0이면 강습·공성·보급 보정(`commander_mul` 등)이 없어 마지막 함대가 조금 약함 | 안전. 마지막 함대가 참모 부족임을 O3 기준선 해석에 적는다. 앞 함대가 참모를 독점하므로 보직별 분배로 바꿀지는 O3 때 결정(낮음) |
| 6 | 낮음 | `scenario_profile.gd:62-68,95-101` | `is_cao`를 `sq.has("morale_group")`로 판정. 조조 슬롯 순서에 의존(`cao_last` = 마지막으로 배치된 조조 함대). `cao_fleets=1`이면 기함이 "마지막"이 되어 fill_bp가 기함에 걸린다(현재 데이터 8~16이라 문제 없음). 결정론: 정수 연산뿐이라 문제 없음. 순서 의존이므로 배치 순서가 JSON 배열 순서임을 문서화 | 주석 한 줄 |
| 7 | 낮음 | `tools/scenario/make_red_cliffs_208.py`(추가 슬롯) | 추가 슬롯 9개 위치: 격자 x 1240~1560, y 80~820이고 전장 `battlefield_bounds [0,0,1600,900]` 안, 다른 함대와 90 이상, 조조 탈출 지점 (1600,300)에서 150 이상. 실측: 가장자리 최소 여유 x 40(1560), y 80, 탈출점 최근접 SQ-12 (1560,560)=263. `deploy_delay_s` 360 전원. `historical:false`는 생성기에서만 쓰이고 `ScenarioRoster.officers`가 걸러낸다. `historical_basis` 문장 "Q82 추가 함대: ... 게임 수치"가 있어 화면 노출 시 구분 가능. 이상 없음 | 없음 |
| 8 | 낮음 | `hud/ui_kit/roster_screen.gd:104-106` | 결산·재생 reveal에서 조조 16함대 카드 16×58px + 머리 약 140px ≈ 1070px. 스크롤이 없다. 1280×720에선 아래가 잘릴 가능성(화면 확인 필요). 이전 최대 7장 | 로컬 화면 확인. 필요하면 2열 |
| 9 | 낮음 | `organization.gd:221-225` | 장비 유지: 같은 함종 `FILLER` 항목에서 `mission_equipment_id`를 읽고 없으면 정찰. validate가 `""`을 허용(O1b #3 처리 확인, `organization.gd:112`). 단 `c.has("mission_equipment_id") and != ""`이면 `""`은 통과하나 `equip[...] = ""`이 되어 auto_fill 결과의 고속정 장비가 ""(장비 없음)로 남는다. 정찰로 대체하는 쪽이 의도라면 어긋남 | 의도 확인(`""`도 "없음"으로 유지해도 무방) |
| 10 | 낮음 | `succession_rules.gd` | 테스트 빈 곳: ① 기함 아닌 함대의 승계 후 60초 뒤 혼선 종료 ② 승계자(부제독)가 다시 지휘 불능이 되는 경우(상태가 이미 severe라 두 번째 `_substitute`는 호출되지 않음, 즉 이중 승계 없음 — 의도로 보임) ③ 승계 중 `stats.succession` 집계. 투영 `commander_sub`는 유지됨 | 낮음, O3 때 보강 |

## 스펙 대조
- **Q73**: `fleet_groups`·`group_id`·`CommandCore.groups`·`group_view`·투영 키 모두 제거. 시나리오 JSON도 키 없음(23 squadrons). 일관됨.
- **Q74 / §4.14 승계**: 순서 부제독 → 첫 참모(`staff[0]` = 강습 → 공성 → 보급, O1b ④와 일치). 승계 즉시 `cmd_stat`·`stats`·`traits`가 바뀌고 지휘 한도는 `limit_tier`가 새 통솔로 다시 계산(`recompute_command_limit`). 60초 혼선은 **승계한 함대만**(`_substitute`에서 `f.confuse_until`). 이을 사람이 없으면 `FOREVER`(전투 끝까지, §4.14 지휘 공백). 격침·항복 함대는 `_worsen`의 `f.out == ""` 조건으로 승계하지 않는다(함대가 사라지므로 정상). 중상 → 사망 전환에서 두 번째 승계는 일어나지 않는다. 범위가 맞다.
- 이전 동작과 차이(의도): 옛 구조에서는 비기함 함대의 중상이 혼선 없는 능력치 이음이었고 혼선은 함대(그룹)에만 걸렸다. 이제 모든 함대의 지휘 불능이 그 함대의 60초 혼선이다. 제안서 §4.14 문구("승계 뒤 60초 혼선")와는 오히려 맞는다.
- **Q80/Q81**: 세력 예산 필드 없음, 함대 한도까지 채움. 확인.
- **Q82**: 비율이 data_rules 실행값으로 정확히 1.070/1.590/2.140/2.140(허용 ±0.05, 오차 0.000). 계산식은 정수 연산과 정렬(통솔 내림, ID 오름)뿐이라 결정론이다. 생성기는 `auto_fill`의 선택 순서(제독 통솔 순)를 따로 구현해 두 구현이 일치해야 하는데 data_rules가 실제 `auto_fill` 결과로 검증하므로 괴리가 생기면 즉시 잡힌다(좋음). 한계: 비율은 임무장비 비용을 뺀 `cost_of` 기준이며 세 세력 자동 편성 기준이다(Q81·Q82 보충과 일치). 기본 경로엔 적용되지 않는다(발견 1).
- **REVIEW-O1 발견 1**(옛 `vice_admiral` 승계): 해소. **발견 5**(`count_factor` 무시): `count_factor` 폐지로 해소, 고속정 장비 RECON 고정은 해소(발견 9 제외). **O1b #3**: 해소. **O5 #2**("함대 %s" 라벨): 라벨 삭제로 해소(⑤).
- **REVIEW-O1 발견 6**(장수 부족): 발견 5 참조.

## 기본값 ①~⑤ 판정
| # | 기본값 | 판정 | 근거 |
|---|---|---|---|
| ① | 기함 진입 표적 = 승패 기함(`is_flag`)뿐 | **수용** | `is_flag`는 유비·손권(주유)·조조 3척에 켜져 있다(JSON `flagship`: RC-LIU-SQ-01, RC-SUN-SQ-01, RC-CAO-SQ-01). 제안서 §4.11은 "기함 진입"을 정의할 뿐 "함대 기함"을 요구하지 않고, Q73이 함대 상위 개념을 없앴다. 이전에 표적이던 형주 수군(문빙)·강하군은 일반 함대 강습(unit)으로만 가능. 승패 판정표(G8-04)는 건드리지 않는다. 다만 이전에 가능했던 표적이 줄어드는 점은 사용자에게 알린다 |
| ② | 제한적 승리 = 유비 기함 함대만 도달 | **조건부(사용자 확인 필요)** | 발견 2. 승패 규칙 변경이며 제안서 표와 충돌한다. Q73이 허용한 범위를 넘는다고 읽힌다 |
| ③ | 기본 그룹 1~n = 아군 세력별(1 유비, 2 손권) | **수용** | UI 편성이고 코어 상태가 아니다. 이전 3그룹(유비 전단·강하군·주유 수군)이 2그룹이 된다. 그룹 선택 UX는 `SelectionSet`이 맡으므로 문제 없고 `selection_groups` 테스트 영향 없음 |
| ④ | 정본 편성 화면은 함대를 순서대로 나열 | **수용** | `roster_screen.gd` 변경이 단순. 카드 수가 늘 때의 높이는 발견 8 |
| ⑤ | command_deck "함대 %s" 라벨 삭제 | **수용** | O5 #2의 처리 방향 중 하나이고 `ui_wording`·`ui_flow` 통과. 정보 손실은 없다(상위 묶음 이름만 사라짐) |

## 결정론·재생
- `profile.fill_bp`와 `cao_fleets`는 프로필에 들어가고 `apply`가 편성 사본을 헤더에 남기는 구조는 그대로다. `fingerprint`에서 그룹 항이 빠졌으므로 O2 이전 재생 헤더의 지문은 다르다(알려진 호환 단절, 문서화 필요: 낮음).
- 같은 입력 같은 결과: organization_rules가 통과.

## 판정: **조건부 수용**
조건(사용자 승인 전):
1. 발견 1: 기본 경로 난이도 2배를 인정하고 O4 전 배포 금지를 기록하거나 임시 조치를 정한다. 구현자 salvo_compare 조건 B 2/2 패배를 근거로 제시한다.
2. 발견 2: 제한적 승리 조건(기본값 ②)을 사용자가 확정하고 제안서 §4.1과 `victory.gd:9` 주석을 맞춘다.
3. 발견 3: 제안서 §4.14·§4.1을 Q73 기준으로 정정(문서 세션).
나머지(4~10)는 O3·O4에서 처리해도 된다.
