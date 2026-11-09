# 행 19~21 분모와 비교 계약 보강

상태는 독립 검토 대기다. 정적 원문 및 보존 로그만 읽었다. 기존 산출물과 제품 소스는 유지했다. 아래 수식의 범위는 성공 경로다. 실패 뒤 미도달한 assertion은 채우거나 건너뛰지 않는다. 성공 종료·필수 사례·필수 순서·기대 Boolean·출력 파일 모두 필요하다.

## 행 19

| Suite | 정상 경로 분모 및 유한 정지점 |
|---|---|
| worker | `14 + 3×14 + 3 = 59` source check. 정상의 다섯 joined 호출은 adapter 거절, post-create 거절, 성공 fixture 셋이다. 각 호출은 0개 이상 running poll 다음 terminal 한 건. running record는 정확한 두 키와 bool/string 유형을 요구하고 result 키는 금지한다. poll 경로별 ID와 순번을 사용하고 scheduler 의존 frame 수는 lane equality 조건에서 제외한다. 이전 실측의 0/양수는 새 lane에서 그대로 요구하지 않는다. Join 순서와 정상 terminal, barrier 및 runner deadline으로 유한하게 닫는다. |
| replay | case 순서 commands/reordered/removed/defaults/one-tick/natural/direct/delegate와 late/order/policy/limit/rows/commands-shape. 성공마다 factory1/status1/typed details3/closed2/second factory를 통과한 controls1, 실패 예상마다 factory1/status1/exact rejection1/closed2, 그리고 oracle cross-check7 = 101. 첫 factory 실패는 즉시 해당 case helper가 반환하므로 오류. 두 번째 factory 실패는 원문에서 check 없이 controls 생략하므로 각 case ID의 controls 단언 미도달도 오류. replay result 실패에서 typed 3개가 생략될 때도 오류. oracle 파일 열기 실패 또는 dictionary key 누락은 run error. |
| viewer | E01~E14 순서 기대 횟수는 `[8,8,9,9,19,11,13,5,9,9,9,9,11,17]`이고 양 끝 class/row 검사가 하나씩 있어 148. make_owner마다 create1+stop2, compare마다 DTO1+typed equality1. E05 owner 3개, E06는 두 salvo 마스크 각 1 및 단일 loss의 조건부 2를 요구한다. E14는 pre/post capture의 내부 원문 4 및 nested alias 1이 필수다. factory null이나 advance 실패의 guard를 통과시키지 않는다. |
| I01b private | 순서 projectile/resource/memory/pending/post/damaged/terrain. _roundtrip 1개는 `17+2N+B+T`. N=110(projectile) 또는 65(나머지), B=4/9/2/1/1/1/2, T=1/1/0/1/1/0/0. 합계 per seed `242+157+149+149+149+148+149=1,143`, 10 seeds. _negative 120은 초반 4+33×2+stable1+empty_form2×4+object/cycle2×2+combat create1+nested7×2+unsupported morale2+public malformed7×2+guard6. _run 후속 3을 더해 11,553. create/capture/restore/negative clone/empty-form stable의 guard가 실패하면 기대 분기를 누락한다. _advance()는 원문에서 단언을 호출하지 않는다. |
| I01b service | _capture 2, _suffix `3N`, _restore `6+F+I_supply+(4+C0+C1)×I_detect`. F는 준비 target fleet 수, C0/C1은 양쪽 record 수다. inactive 8+13=21(PoC 6+7), _refusals 108(4+33×3+5), tail3. per seed detection 두 종류는 각각 `6+4+2×(12+C0+C1)+33`으로 둘 다 suffix 11, supply pending 26, post 39. 따라서 전체는 `2122 + 2×Σ(C0+C1)`이며 합산은 20 detection segment에 걸친다. 2,202 역사 합계와 일치하려면 합이 40이어야 한다. 수용 observations는 side 0 대상 record와 suffix만 저장하므로 양쪽 기록 개수를 seed별로 독립 확정할 수 없다. Detection each side 정확 record ID/typed payload를 native fixture에서 양쪽 별도 관측하고 restored target의 record 단언 순번과 결합해야 한다. _refusals의 실패 코드 33개와 두 malformed side-size branch를 누락시키지 않는다. |
| I01b active | per seed PoC `1+5+26+4+440+1=477`, services `1+1202+26+18+280+2=1529`. _advance는 1/2 단언 per tick, 서비스 사전 599 tick 및 4분기 단언, suffix 각각 110/70×4. _retired와 _bindings 각 2번을 통해 PoC는 module 0 및 fleet2, services는 module3 및 fleet3의 identity를 요구한다. _negative 35와 _run 4(초기 canonical fixture, 완료 분모2, output open)를 더해 20,099. normal owner null/prepare 실패, negative different seed 또는 controls null의 누락을 오류로 둔다. |
| headless | canonical guard1, micro `Σ(3+actual_rows+reference_rows)=61`, timeout 2×8, negative 26×2 + 20, tail3. 각 normal은 `15+2M+6T+6·I(T>1)+2·#{5,10,15<T}+Q`. M은 close 시 소유 module 수(0/3), T는 independent raw terminal tick 또는 1200, Q는 매 tick 정책에서 queue한 실제 command rows의 합이다. 8개 관측 T=16,2,1200,621,16,1,154,154 및 체크포인트 수 3,0,3,3,3,0,3,3을 수용 observations에서 직접 확인했다. 최종 command log는 queue 호출과 동치라는 별도 증명이 없어 Q 대용으로 쓰지 않는다. Q는 independent raw projection에 reference_commands를 적용한 per-tick 길이와 순번으로 검증한다. 역사 합계 13,417는 Q를 역산해 주입하는 oracle로 쓰지 않는다. factory 조기 반환, pure normalize 분기 누락, output open 실패는 lane 실패다. |

Service의 위 상수는 `21+108+3+10×(67+67+26+39)=2122`다. P2B diagnostic JSON의 checks_before_file_open=2201 및 exit 0 marker는 마지막 output-open 단언 포함 2202와 대응한다. 거절 코드와 fixture별 historical observation payload를 별도 원본 SHA로 묶되, 비교에는 log의 단일 합계가 아니라 branch identity를 쓴다.

## 행 20

- BattleFlow before/after 각각 TestCheck.ok 23개 순서. 첫 false에서 조기 반환, 성공은 BATTLE_FLOW_PASS + exit 0. 약 10tick의 2개 값만 각각 9..11 허용, 프레임 cap은 8 정확, paused delta는 0 정확이다. 재시작 새 seed의 동치 조건 및 replay fingerprint 비교는 각 lane 내부 타입·값 비교다. 예전 replay 독립 5-b에서 최종 attempt3은 SCRIPT ERROR 0, WARNING 1, ERROR 1과 보존된 stderr 종료 4행 **정확 비교**를 했다. 153 ObjectDB, 18 resources와 해당 cleanup/clear 위치다. 다른 시점 161/22 로그는 동일 accepted attempt의 허용치가 아니다. 숫자 범위의 사전 승인은 미확인이다.
- Legacy AutoResolve V5 argv는 baseline 인자가 없다. default none/attack5/charge30 각각 200 seeded rows, 총 600개; compare branch 0개, overall marker 1개다. exit 0/AUTORESOLVE_PASS만으로 저장 실패를 식별할 수 없으므로 격리 user://autoresolve.json 생성, meta, 정확한 3개 policy 이름, 배열 내 200개 row/fingerprint의 순서와 summary를 요구한다. seed는 play(i, ...)의 i이고 원본 JSON에는 별도 seed 필드가 없다. 타입을 엄격하게 비교하고 누락·추가·순서 변경·중복 키를 거부한다. JSON에는 엔진 int/float provenance가 사라질 수 있어 정수/실수 typed semantic 증명은 별도 원시 기록이 필요하다. 비교용 기존 accepted CLI 1-run before/after와 새 200-run 계약을 혼동하지 않는다. --baseline을 추가하면 3 policy별 통계 분기와 허용치 및 실행예산이 달라지므로 현재 V5에는 추가하지 않는다.

## 행 21

- WorldLink 각 lane에서 일반 실행의 정적 분모 43은 `_data=8 + _contracts=6 + _rules=8 + _determinism=4 + _screen=6 + _round_trip=11`이다. 여기에 Z0/카드/전장 결과/결과 카드 각각의 enabled visible button 수에 `TouchMetrics.TOUCH_DEVICES=3`을 곱해 합산한다. 각 stage별 visible enabled button의 고유 NodePath 및 device index를 독립적으로 정해 반복 ID에 대응시켜야 한다. 현재 역사 원문은 4개 리스트와 개별 반복을 저장하지 않았다. 총합을 로그에서 역산하지 않는다. wrong/missing battle 또는 null return screen의 조기 반환과 이후 누락을 오류로 둔다.
- 기존 clean은 격리 user dir 초기 파일 0에서 before/after 둘 다 exit 1, WORLD_LINK_FAIL 1 및 exact `ERROR: TEST_FAIL 천하에서 오면 브리핑부터 (prologue)`. Stack은 `_check :16 → _round_trip :239 → _frames :20`. false 한 개만, 나머지 모든 required true. 기존 편차로 기록하며 기능 PASS 분자에 합산하지 않는다. returning은 BOM 없는 30-byte 설정 `[progress]\nprologue_seen=true\n` SHA c8b752aba9f5015889c00c5a45db9fef916af2a1e1be3e68d49b8121b2db721b 한 파일만 가지고 시작한다. before/after 모두 exit 0, WORLD_LINK_PASS, false 0.
- 제5조각 v3 실제 before/after의 clean/returning stderr에서 ObjectDB 154/resources 20이 동일했다. 독립 수용된 비교기는 딱 두 패턴의 선행 숫자만 정규화했고, WARNING/ERROR 타입·문구·cleanup/clear 위치 및 다른 stderr 내용은 그대로 비교했다. 이는 역사 비교 규칙이고 숫자 증가의 안전 범위 증명이 아니다. K6에 이전 규칙을 채택하더라도 raw 숫자와 증감을 별도로 보고하고, type/position/count가 달라지는 다른 진단은 실패다. V5의 wrapper overlay로 인해 stack source path/line이 달라지면 원문과 overlay SHA 및 위치 매핑을 독립 수용하기 전에는 진단 동등성을 확정할 수 없다.

## 완료 경계와 이관

다음 심사의 입력은 이 문서, 기존 함수·호출 색인, 그리고 sources JSON의 원본 SHA다. 완료에 필요한 미정 항목은 headless Q의 case/tick oracle, service C0/C1의 seed/restore identity, WorldLink 4개 stage button 경로/3-device 순서, AutoResolve의 결과 typed 및 결정적 bytes 기대치, 허용 overlay에 대한 원본/변형 hash와 손실·중복·false 반례다. 수용된 관측 기록이 저장하지 않은 수치를 사전 확정하지 않았다. 독립 검토 없이 실행 fixture, K6 명령, 사용자 화면 입력을 개시할 근거가 없다.


## AutoResolve 오프라인 판정기

`legacy_autoresolve_oracle.py BEFORE_JSON AFTER_JSON`은 JSON 중복 키와 비유한 수, 3 policy × 200 ordered rows, 정확한 schema 및 pair equality를 확인한다. win rate와 reason totals는 run rows로 다시 계산한다. 반올림된 평균은 현재 수치 필드와 두 lane 간 동치까지만 판정한다. 엔진 내부 variant 타입 및 독립 native 기준선과의 완전한 값 대조는 별도다. 합성 equal 1개와 invalid 6개를 로컬 Python으로 검증했으며 Godot 산출물을 사용하지 않았다. 결과는 legacy-autoresolve-synthetic.log다.
