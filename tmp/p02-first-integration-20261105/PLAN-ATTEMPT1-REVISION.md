# P02 attempt1 반례 — 스펙 복귀 및 최소 보완계획

2026-11-05 KST. 계획 담당 `/root/plan_revision`. **독립 수용 전 구현·Godot 재실행 금지.** 이 문서만 신규 작성하며 수용된 PLAN v2, REVIEW-PLAN/V2 및 attempt1 source·입력·로그·관측·exit를 그대로 보존한다. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED 유지.

## 1 관측과 원인

`attempt1-exit.json`은 actual_exit=1, attempt=1, limit=6이다. captured log SHA256 `8aaa1cb043f763b3ad730c8b2b507ee3d23dcef3a5e946950e6c9dda1217571b`, SCRIPT ERROR 8112개와 별도 `ERROR: P02_ADAPTER_FAIL timeout retains actual clock/end` 1개다. 마지막 runner 집계 cases=8/checks=16804/rejections=32/natural=6/timeout=2는 **실패 시도 관측**이며 수용된 정상/거부 완료 실적이 아니다. 최초 조사에서 너무 넓은 rg가 같은 로그의 반복 오류를 과다 출력했으나 파일/실행에는 영향이 없었다. 이 계획 작업은 Godot 실행이 아니며 attempt2를 소비하지 않는다.

현재 원문 라인으로 확인한 반례는 다음과 같다.

- `tests/autoresolve.gd:190` 기존 policy_commands는 197에서 모든 squadron의 `s.dead`를 직접 읽는다. 새 run_operation(99)은 같은 정책을 호출한다. 정책 none도 이 순회를 먼저 하므로 contact가 있으면 동일 오류다.
- `core/battle/battle_projection.gd:120` contact는 id/side/contact/pos/err_r/conf_bp 등의 공개 접촉 DTO이며 dead를 넣지 않는다. 공개 계약을 넓혀 dead를 추가하는 수정은 이번 범위가 아니다.
- `core/battle/detection.gd:55` foes는 매 조회 62에서 실제 dead 전대를 제외하고, 확인·추정·상실의 공개 접촉을 반환한다. can_target(34)은 confirmed/estimated만 허용한다. 따라서 공개 contact의 존재는 현 소스에서 살아 있는 접촉이라는 충분한 근거지만 lost는 사격 가능한 표적이라는 뜻이 아니다.
- 신규 runner 143/174도 같은 production policy_commands를 raw reference에 호출했다. 양쪽이 같은 정책 오류를 내며 진행하므로 독립 상태 비교만으로 정책 의미/오류를 잡지 못했다. raw BattleSim 자체는 유지하되 정책 oracle은 독립시켜야 한다.
- runner181의 모든 정상 조합에 대한 1tick timeout 강제는 잘못된 가정이다. 가까운 POC attack5/seed7은 실제로 첫 tick에 자연종료할 수 있다. 자연종료를 timeout으로 덮어쓰거나 엔진 종료를 억제하지 않는다.

## 2 최소 해결 계약: opt-in 전용 공개 정책뷰

**기존 policy_commands/play/play_rc 본문은 바꾸지 않는다.** 신규 opt-in helper `_operation_policy_commands(policy, public_projection)`만 추가하고 run_operation은 이것을 호출한다. 이 함수는 파일·owner·raw sim을 인자로 받거나 참조하지 않는다.

1. none이면 공개 squadron을 순회하기 전에 즉시 빈 명령 배열을 반환한다.
2. attack5이면 입력 공개 projection의 detached 정책뷰를 만든다. full squadron(POC/아군)은 원래 공개 필드를 그대로 유지한다. `contact`가 있는 적 DTO는 confirmed/estimated만 유지하고 lost는 제외한다. 적의 위치는 공개 pos 그대로 쓰므로 추정은 마지막 알려진 위치이고 실제 비공개 위치를 조회하지 않는다.
3. 유지한 contact에만 정책뷰 내부 `dead=false`를 추가한다. 이것은 Detection.foes의 매조회 dead 제외 계약에 근거한 기존 정책 입력 모양의 보완이다. 숨겨진 건강/함종/정확척수/현재위치를 읽거나 공개 projection을 변경하지 않는다. contact의 누락된 임의 필드를 일반 기본값으로 채우지 않는다. 정책뷰는 호출 후 버리고 저장·출력·owner 상태에 넣지 않는다.
4. 위 정책뷰를 기존 policy_commands에 전달한다. 5초 간격, squadron 순서, 최근접 거리 strict-less tie, 아군별 attack 다음 전체아군 missile/fighter 순서, 적이 없을 때도 기존 missile/fighter 시도는 유지한다. POC의 dead full squadron 제외는 기존 정책 그대로다. charge30/unknown은 기존 adapter의 선행 거부를 유지한다.

이는 지원 모듈을 끄거나 생략해 성공시키는 방법이 아니다. Detection의 confirmed/estimated targetability와 lost 비표적 계약을 실제 opt-in 소비 정책에 연결한다. POC full 정보에서는 기존 attack5와 같은 명령이 나온다. Detection에서는 기존 policy가 런타임 오류를 내던 영역에 공개 입력만 사용하는 명시 의미를 부여한다. 제품 자동지휘 전체나 기존 적벽 policy의 교체가 아니다. 사격이 가능한 접촉을 선택한 뒤 실제 명령 수용 여부/재화 부족 등은 기존 sim queue/step의 사건 계약에 맡긴다.

대안으로 기존 정책의 `s.dead`를 get으로 바꾸는 수정은 legacy hunk를 넓히고 lost를 공격하는 의미 문제를 남기므로 선택하지 않는다. 공개 projection에 dead를 추가하거나 detection을 제거하는 대안도 선택하지 않는다. raw sim/observe를 정책에 넘기는 방법은 금지한다.

## 3 정책 oracle과 정확 추가 분모

신규 runner에 생산 helper를 호출해 실제 명령을 얻는 **P01~P09 9개 정책 microcase**를 추가한다. 기대값은 수제 public DTO와 하드코딩한 command tuple/정확 순서로 정의한다. 생산 helper/legacy policy로 기대명령을 생성하지 않는다. 각 호출 전후 public DTO의 정확 typed bytes 불변을 검사한다. contact DTO에는 dead/ships/비공개 상태를 넣지 않아 누락필드를 실제로 재현한다. 모두 성공 의미 검사이며 46 named negative에 합산하지 않는다.

| ID | 입력·조건 | 정확 기대명령 |
|---|---|---|
| P01 none_contact | tick0, 아군1+dead 없는 confirmed 적3, none | 빈 배열 |
| P02 poc_dead_filter | tick0, 생존아군1/사망아군2/생존적3/사망적4, attack5 | attack[1]→3, missile[1], fighter[1] |
| P03 confirmed_contact | tick50/hz10, 아군1+confirmed 적3(dead 없음) | attack[1]→3, missile[1], fighter[1] |
| P04 estimated_contact | tick50, 아군1+estimated 적4(공개 pos만) | attack[1]→4, missile[1], fighter[1] |
| P05 lost_nearest_excluded | tick50, 가까운 lost3+먼 estimated4 | attack[1]→4, missile[1], fighter[1] |
| P06 lost_only | tick50, 생존아군1+lost3만 | missile[1], fighter[1]; attack 없음 |
| P07 between_periods | tick49/hz10, 아군1+confirmed3 | 빈 배열 |
| P08 stable_tie | tick50, 아군1에서 등거리인 confirmed 적의 입력순서4,3 | attack[1]→4, missile[1], fighter[1] |
| P09 no_live_allies | tick50, 사망아군1+confirmed3 | 빈 배열 |

8개 기존 정상 matrix의 raw oracle 정책은 별도 테스트 reference로 구현한다. 공개 squadron을 side/명시 dead/접촉상태와 공개 거리로 분류하고 5초 경계의 독립 명령 tuple을 구성한다. production `_operation_policy_commands` 및 legacy policy_commands를 기대값 경로에서 호출하지 않는다. 구조가 같은 상태 기계의 자기 비교를 피하기 위해 P01~09의 수제 정답을 이 reference에도 별도로 대조한다. reference는 public raw projection만 받으며 raw private 위치/건강을 oracle 정책 입력으로 보충하지 않는다. 상태/clock/controls/ordered queue/events 독립 raw BattleSim 비교는 기존 검사대로 유지한다. none에서도 policy helper가 오류 없이 빈 명령을 반환함을 실제 services run으로 확인한다.

## 4 timeout oracle 분리

기존 normal의 “모든 조합에서 max_ticks=1이면 반드시 timeout” 단언을 제거하고, 그 호출이 남으면 실제 raw end 여부와 맞는 종료 DTO인지 비교한다. 첫 tick 자연종료는 정상 관측이며 timeout으로 덮지 않는다.

timeout 보장은 별도 명시 `tests/fixtures/p02/timeout-poc.json` 입력으로 검사한다. 기존 POC rules 바이트 의미는 그대로, ally/foe 각 30척·flag=true·lv1·p0, ally=(500,500)/foe=(2500,500), reinf=[], initial_controls=[direct,direct], policy=none, max_ticks=1을 명시 authoring한다. 이것은 테스트가 종료를 위해 런타임에서 모듈/공격을 지우는 변환이 아니다. 두 함대 간 2000거리는 POC 기본 range300/missile480/fighter380보다 크고 한 tick 이동으로 닿지 않는다. 양측 생존·tick0/C0를 독립 raw에서 확인하고, seed0/7 **T01/T02 2개**를 실제 consumer helper와 raw1step으로 각각 비교한다. 예상 tick1/clock_ms100/over=false/reason=timeout/end_tick=-1/end_ms=-1, commands0을 확인한다. 새 fixture provenance에 수치·출처·사유를 적는다. 최초 tick에 자연종료하면 억지 expected 변경 없이 실패로 재심한다.

기존 정상8은 기존 작은 실입력과 자연/상한 종료 원문 관측을 그대로 유지한다. 이번 T2는 그 matrix를 바꾸거나 성공 사례 수를 부풀리는 용도가 아니다.

## 5 허용 hunk·실행·성공판정

추가 허용 hunk는 autoresolve의 **신규 opt-in 구간에만** `_operation_policy_commands` 추가와 run_operation 호출1곳 변경, 신규 p02 runner의 독립 정책 oracle/P9/timeout T2 및 OUT 새경로, timeout fixture+provenance 보완이다. 기존 legacy policy/play/play_rc/통계, adapter 입력계약, private owner/restore/exact context, data/allowlist/skip/HTML/cache는 바꾸지 않는다. accepted PLAN v2 나머지 계약과 46negative(API32/CLI14), CLI2성공+legacy1쌍=18실제프로세스 분모는 그대로다.

수용 후 실행 담당이 attempt2-source/code/input/engine/cache/SHA를 새 경로에 동결하고 **attempt2/K6**으로 실행한다. attempt1 로그/관측/exit/소스를 덮어쓰지 않는다. 최종 보고는 정상matrix8·정책micro9·timeout2·APInegative32를 별도 집계하고 CLInegative14/성공2/legacy1쌍도 별도다. check수는 실행 관측 전 기입하지 않는다. 기존 실패 attempt1은 끝까지 실패로 남긴다.

attempt2 통과조건은 actual exit0 + SCRIPT ERROR0 + assertion ERROR0 + 각 계획 분모 완결 + 기존 종료진단 분리다. exit0이나 상태비교만으로 정책 성공을 선언하지 않는다. CLI services 성공도 새 helper를 경유함을 실제 source/명령·사건 결과로 확인한다. legacy before/after 비교와 최소 회귀·최종 다른모델5b·보존감사/기록/ZIP/독립closeout은 여전히 미실행/후속이며 이 계획으로 통과 처리하지 않는다. 추가 반례면 반복실행 전 원인을 분리하고 K6 내에서 스펙/독립수용 경계를 지킨다.
