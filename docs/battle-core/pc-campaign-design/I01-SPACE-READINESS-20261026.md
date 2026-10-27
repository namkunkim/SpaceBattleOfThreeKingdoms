# I01 O03 — 공간 입력·접근 readiness

2026-10-26 / **FX-G 산술 입력 동결 권고·실제 함대/작전 공간 NOT_READY / 코드·게임 시험 미실행**.

기준은 [I01 F06~12/A04/FX-G](I01-ACCEPTANCE-PREREG-20261026.md), [독립 준비 검토](REVIEW-I01-PREPARATION-20261026.md), [기준 감사](I01-BASELINE-AUDIT-20261026.md), [D03](D03-SPACE-TIME.md), [H2](H2-DECISION.md)다. 이번 산출물 하나만 작성한다. 15개 dirty·PC checkout을 변경하거나 권한 조회를 재시도하지 않았다.

## 1. 실제로 확인·해소한 입력

모든 원문은 workdir 대신 **`git show 93e60e6:<path>`**로 읽었다. 이 ref는 로컬 관측 스냅샷이며 최신 원격을 뜻하지 않는다. Godot·프로젝트 검사 코드를 실행하지 않고 JSON 읽기와 PowerShell 순수 산술만 수행했다.

| 원문 | 확인값·제약 |
|---|---|
| `data/profiles/red_cliffs_rt.json` | base=`poc_corridor.json`, combat=`combat_m3.json`. 신규 fixture는 실제 적벽 편성의 대체 자료가 아님 |
| `poc_corridor.json` rules | world3400×2300, ship_gap20, edge40. 초기 기하 기준값이며 FX-G world1000×600과 별개 |
| `rules.gd` formation_offsets / `salvo.gd` _apply_shape·_show_target | 28슬롯을 중심 정렬. FORM_SHAPE=[7,5,4,8,1,9,2], 간격은 R.ship_gap. 현재/목표 진형이 별도 존재. 표시·발사 기하를 전체 논리 선체 외곽으로 일반화 금지 |
| `scenario_profile.gd` enlarge_field | 함대·효과rect·기지/탈출 중심을 확대하지만 ship_gap·보급 반경을 함께 확대하지 않음 |
| `combat_m3.json` supply / `supply.gd` sources·serviceable | 기지반경180/동시4, 보급함반경140, 정지주기60초. 중심거리≤반경·정지/동맹/서비스조건. 전 선체가 서비스 원 안에 있어야 하는 규칙이 아님 |
| `bundle_layout.gd` HEAD판 | 현재 f.form의 반경만 집계한 그룹 슬롯/경계 clamp. dirty판의 수별슬롯·form_t·전체축소 개선은 채택하지 않음. 그룹 전체 안전 외곽의 증명으로 사용 불가 |

ship_gap20에서 중심 정렬한 **슬롯점 반경**을 원문 수식으로 재계산했다. shape7=61.611687,5=234.825096,4=72,8=297.953016,1=297.953016,9=105.652691,2=67.082039 [좌표]. 선체폭·생략함선·느슨한 배치·전환/그룹 전체는 포함하지 않은 참고 하한/기하값이다. 반경20을 이 실제 기하의 최대값으로 쓰면 안 된다.

## 2. 첫 fixture FX-G의 동결 권고 입력

아래는 **가짜 원형 함대 한 개의 정적 기하 oracle**다. 실제 최대 진형·충돌·선회·AI·보급 성능을 수용하는 입력이 아니다. 필드명은 I01 후보 계약이며 실제 게임 파일을 생성하지 않았다.

| 입력·타입 | 고정 권고값/단위·검증 |
|---|---|
| fixture_id:string / artificial:bool | `FX-G` / true. product 또는 실제 편성 태그와 함께 사용하면 거부 |
| baseline_ref:string | `93e60e6a957ffdb002a1cb06bc796c4c46496736` 정적 원문. dirty 포함 없음 |
| bounds:number[4] / target_size:number[2] | [0,0,1000,600] / [2000,1200]. 유한·원점0·양수 크기·등방 비율2만 이번 fixture 지원 |
| coordinate_space:enum | source 입력, effective 출력. effective 재투입 거부 |
| envelope:{radius,safety,unit,kind} | {20,5,source-coordinate,synthetic-circle}. 유한 radius>0/safety≥0. 유효 결과40/10, 팽창 반경50 |
| nodes:{id,kind,position}[] | E/R=출입,J=분기,A/B/C/D=시설. source E(50,300),J(200,300),A(400,180),B(400,420),C(800,300),D(650,420),R(950,300) |
| edges:{id,from,to,bidirectional}[] | 아래9개, 모두true. 중복·미해결 참조 거부. A/B/C/D↔E와 R 접근의 연결 판정 |
| region:{node,radius,unit,shape}[] | A/B 서비스와 E/R 출입: source 반경60의 원. effective 반경120. 실제 legacy180/140를 자동2배하지 않음 |
| region_admission:enum | `center-in-world/intersect-free-centers` 권고. 원 중심은bounds 안, 사용 가능 영역은 원∩자유중심영역. 원의 일부가밖으로나가도 입력좌표를clamp하지않음 |
| obstacles:array / effect_rect:number[4] | 물리본체없음 / source[300,50,100,50]→effective[600,100,200,100]. 효과는 통과 가능. 병기제한·동적장애물은 미지원 |
| access_requirement | 한 원형 개체의 중심 경로·정지점·회전 불변 원형 외곽. 다중함대 대기/교대·스윕 충돌·회전 중 비원형 변형은 이 oracle 밖 |

전체 서비스 원이 world 안이어야 한다는 정책으로 바꾸면 E/R은 source x50±60 때문에 실패한다. 위 admission을 숨은 clamp로 대체하지 않는다. 해당 정책을 지원하지 못하는 구현은 `UNSUPPORTED_REGION_ADMISSION`으로 거부해야 하며 FX-G를 임의 성공 처리하지 않는다.

## 3. 산술 결과와 접근 oracle

source 자유중심 직사각형은 [25,975]×[25,575], effective는 [50,1950]×[50,1150]이다. 모든7노드가 들어가며 E/R의 최소 여유는 source25/effective50이다. 직사각형은 볼록하므로 두 내부 노드의 직선 구간도 그 안에 있다. 이것은 장애물 없는 단일 원의 기하 결과이며 실제 경로 탐색 실행 결과가 아니다.

| 항로 | source 길이 | effective 길이 |
|---|---:|---:|
| E-J | 150 | 300 |
| J-A | 233.238076 | 466.476152 |
| A-C | 417.612260 | 835.224521 |
| J-B | 233.238076 | 466.476152 |
| B-D | 250 | 500 |
| D-C | 192.093727 | 384.187454 |
| A-B | 240 | 480 |
| R-C | 150 | 300 |
| R-D | 323.109888 | 646.219777 |

길이는 sqrt(dx²+dy²), 2배 변환 결과를 표시용 소수6자리로 반올림했다. 실제 비교는 원래 수식/정수 좌표를 사용하고 이 표시값을 직렬화 정본으로 되쓰지 않는다.

- 연결 예: E-J-A-C, E-J-B-D-C와 역방향, R-C/R-D가 존재한다. E-J 제거는 E를 고립시킨다. 단순히 A-C를 지웠다고 전체 단절이라 판정하지 않는다(A-B 우회가 남음).
- 서비스 A/B 및 출입 E/R은 해당 중심점이 자유중심영역에도 있으므로 교집합이 존재한다. 원형 외곽40+여유10≤지역반경120이고 중심에서 정지·회전하는 기하 조건도 충족한다. 실제 서비스 처리량/재고/피격 안전은 별도다.
- 효과rect의 source y=50~100과 모든 항로의 y≥180은 겹치지 않는다. 이 fixture로 효과 감속·탐지 또는 전투 시간을 검증할 수 없다.
- 실제 HEAD 슬롯 반경297.953016은 effective E/R 벽거리100보다 크다. 따라서 이 좌표/원형40을 실제 함대의 유효 외곽이라고 대체하면 안전을 보증하지 못한다. 넓은 실제 진형의 배치·방향·전환을 검사하려면 별도 입력이 필요하다.

## 4. 경계·미지원 입력과 fail-closed

| 변형 | 판정·원인 |
|---|---|
| 접선: 중심의 x=25(source),다른축유효 | 반경25가world경계에닿음. 닫힌경계로허용 권고. 25보다작으면 `OUTSIDE_FREE_CENTER` 거부, epsilon으로몰래완화금지 |
| 서비스 중심(0,0),source반경10 | 자유영역까지 최단거리 sqrt(25²+25²)=35.355339>10, 교집합없음. effective거리70.710678>20로같은결과. `NO_SERVICE_INTERSECTION` |
| E-J 제거/없는 끝 Z/중복ID | E고립=`REQUIRED_ROUTE_DISCONNECTED`; 미해결참조/중복은구축전거부. 자동연결생성X |
| radius/safety누락·NaN·음수 | `MISSING_ENVELOPE`/`INVALID_GEOMETRY`. 20/5나legacy edge40으로대체X |
| 비등방·nonzero원점·본체/태그통로 | 첫fixture미지원. 각각명시적unsupported. 영역/선분변환을추정하지않음 |
| synthetic=false인데20을최대R로제시 | `NOT_READY_PRODUCT_ENVELOPE`: 편성/진형/전환/선체외곽의근거부재. FX-G산술성공으로A04실제입력을통과시키지않음 |
| 원형한개를다중함대·동적진입으로확대 | `NOT_READY_MULTI_FLEET_ACCESS`: 대기/회피/동시배치·R봉쇄의정책/입력없음. 공간겹침을무적으로숨기지않음 |

필요 product 입력 이름: `roster_hash`, `formation_rule_version`, `logical_hull_extent_by_ship_type`, `formation_offsets_all_logical_ships`, `transition_swept_envelope`, `loose_formation_policy`, `group_layout_version/envelope`, `service_admission`, `entry_waiting_regions`, `exit_completion_region`, `position/heading_set`, `safety_margin`이다. 현재 28개 표시점·render mesh만으로 이 입력을 채웠다고 보지 않는다. 미제공 필드는 정확 경로와 NOT_READY 이유를 보고한다.

## 5. 현재 게이트 해소·변경 경계

**해소 가능:** FX-G의 타입/좌표공간/등방비율·가짜R·영역 admission·7노드9항로 길이·자유중심/교집합·단절 반례는 동결 권고할 수 있다. 이 자료를 읽기 기반 fixture 인수 스펙으로 넘긴다.

**계속 차단:** 실제 최대논리외곽·product접근, 동적이동/충돌·다중함대 통행·성능·서비스량·A06상태. I01을 순수변환만으로 축소해 이 게이트를 제거하지 않는다. 실제게임검사/프로필변경은 미승인이다.

후속 코드 작업 권고는 **별도 baseline checkout을 local93e60e6에서 생성**하고 기존15dirty 및PC실험을 그대로 보존하는 것이다. 지금 생성하지 않았다. PC실험 통합은보류한다. 경로별 허용 후보는 신규 `core/battle/operation_profile.gd`, `data/profiles/operation_i01_fixture.json`, `tests/operation_profile.gd`와 기존 `core/battle/profile_loader.gd`, `core/battle/scenario_profile.gd`, `core/battle/rule_set.gd`, `scripts/FleetBattle3D.gd`의 검토된 최소 hunk다. 신규 경로는 존재/생성을 주장하는 것이 아니라 변경 목록에 제시할 정확한 후보이며, 실제 코드 쓰기 허용은 아직 아니다. dirty `bundle_layout.gd/tests/bundle_layout.gd/project.godot` 및기존정본은허용집합에자동포함하지않는다. 코드착수전사용작업트리·소유·실제필드/O07·Q67 적용판정을별도확인해야한다.

## 6. 자체 5-a·인계

K=3. 원문ref·입력표·7노드/9항로·서비스양성/음성·미지원·product구별·링크/공백을확인한다. 첫PowerShell 슬롯산술의괄호안if구문오류로shape1/8값을폐기했고 분기부호를분리해다시계산했다(297.953016). 잘못된126을결과에쓰지않았다. 순수데이터계산이며프로젝트검사실행이아니다. Godot/게임·AI·저장·통행·성능·1000시드·사람플레이시험은모두미실행. 외부검토자는동결권고와남은차단의경계를별도로판정한다.
