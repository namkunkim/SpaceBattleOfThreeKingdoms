# P02 여섯 번째 조각 계획 v2

독립 계획 재심 대기. [기존 계획](PLAN.md)의 제품 동작, 증거 동결, 단계 및 K6을 유지하며 아래의 구현 범위, 실패 계약 및 검증 분모가 해당 부분을 대체한다. [독립 재심](REVIEW-PLAN-RECHECK-INDEPENDENT.md)에서 발견한 실제 호출부 반례를 검증에 포함한다. P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

## 호출 계약과 허용 범위

- `FleetBattle3D.init_game(proposed_org: Variant = null) -> Dictionary`. null은 기존 편성, 사전은 새 편성 후보이며 빈 사전도 유효하다. 후보 준비에 입력 편성을 전달하고 성공 때만 `battle.org`를 기존 caller와 동일한 성공 의미로 게시한다. 호스트의 기존 `profile_def/difficulty`를 caller가 바꾸는 계약은 범위 밖이다. 사후 테스트에서 지정한 bench patch가 인자로 받은 후보 프로필을 제자리에서 손상시키는 경우에 한해 `{ok:false,error:"invalid_candidate_profile",path:"profile"}` 또는 해당 roster 경로를 반환한다. roster 타입 오류는 `profile.ally`로 고정한다. 실패 진단은 기존 HUD 상태에 새 로그/토스트를 쓰지 않고 반환하거나 엔진 출력에 남긴다. 준비 실패는 `BattleSim.new` 및 roster 변환 전에 반환한다. 성공 반환은 `{ok:true}`다. 기존 편성 경고와 legacy fallback은 성공 후보의 기존 부수 결과로 유지한다.
- `scripts/FleetBattle3D.gd`는 준비/게시 함수와 `init_game`, `_ready`, `_restart`의 호출 guard만 허용한다. 초기 준비 실패는 교체 대상이 없는 경우다. 메인 프레임 진행을 비활성화하고 presentation setup을 생략하며 scene 진단을 남긴다. `_restart`는 실패 시 `_start` 전에 반환한다.
- `hud/ui_kit/command_deck.gd`는 `begin_battle/restart/to_title`의 init 호출과 바로 뒤 guard만 허용한다. 새 편성은 선대입 대신 init 인자로 전달한다. 실패 시 `org_blocked/_clear_log/_start/show_screen/_cutin_fleet` 전 반환. 기존 브리핑에서 편성이 같은 경우의 초기화 생략 및 routed to_title의 WorldLink 반환은 유지한다. `begin_battle`은 실패 결과를 자동 편성 호출부가 확인할 수 있게 반환한다. 기존 정상 초기화 이후 편성 오류로 다른 화면을 여는 경우는 기존 동작이며 후보 준비 거절과 구분한다.
- `hud/ui_kit/org_screen.gd`는 `_load/start_auto/open_org`의 로컬 준비와 guard만 허용한다. 시나리오, 프로필, skill index를 로컬로 준비하고 새 편성 제안이 필요한 복구에서는 `b.init_game(r.org.duplicate(true))` 성공 뒤에만 편성 화면 필드, 안내, 화면을 갱신한다. 기존 오류 목록으로 만드는 복구 안내는 성공 후 오류가 바뀌기 전에 로컬에 보관한다. 자동 편성 출격도 로컬 데이터로 계산하여 `deck.begin_battle`이 후보 준비를 거절하면 기존 화면 상태를 유지한다. 성공 시 기존 자동 편성과 정상/오류 복구 표시를 보존한다. 필드 대입 경계에 필요한 내부 helper는 이 세 함수 인접 위치만 허용한다.
- `tools/scenario`와 test의 기존 직접 호출은 동일한 정상 경로를 계속 사용한다. 임의 외부 호출자가 직접 호스트에 쓰는 상태, 의도적으로 호스트를 쓰는 profile_patch, unrouted 전역 RNG 소비, 엔진/GPU 예외, publish 후 자원 오류는 이 실패 계약의 범위 밖이다. 제품 operation 소비 경로 추가는 후속 과제다.

## 정본 행과 판정

전 5 / 후 6 프로세스. 기존 공통 probe, BattleFlow, WorldLink clean 및 returning, 사후 atomic probe에 `tests/organization_ui.gd`를 양쪽 추가한다. 공통 8행 및 사전 native 오라클 유지. 조직 회귀의 실제 프로세스·단언 수를 별도로 기록한다. 각 런타임에 클래스 실제 경로와 fixture/프로필/캐시/엔진 해시를 확인한다. nonempty 사건 fixture가 실제 생성됐음을 확인하고 side 0 큐에서 보이는 사건을 최소 한 건, 안개 필터로 가린 사건을 최소 한 건 계수한다. 직접 비교용 native 인스턴스에는 같은 seed·정본 입력과 명령을 공급한다.

사후 atomic probe는 10행이다.

1. `reject_clear_profile` — 기존 제품 호스트 직접 init 호출의 명시 오류와 전체 기존 상태 유지.
2. `reject_wrong_roster_type` — 다른 초기 상태에서 직접 호출. 잘못된 roster 경로와 기존 상태 유지.
3. `deck_begin_changed_org_reject` — 새 편성 입력을 실제 deck 경로로 보내 기존 host.org, UI, 로그, 시작 전 상태 유지.
4. `deck_begin_nonbrief_reject` — 기존 편성이 같거나 null인 nonbrief 분기에서 화면과 전투 유지.
5. `deck_restart_reject` — 재시작 요청 뒤 log/start/화면 전환이 발생하지 않음.
6. `deck_unrouted_title_reject` — title 전환과 log 소거가 발생하지 않음.
7. `org_repair_reject` — 실제 복구 필요 편성에서 새 편성, 기존 org_errors, 편성 화면 캐시/선택/안내/화면 유지.
8. `org_auto_reject` — 실제 자동 편성 버튼 호출 경로. 원래 편성과 화면 상태 유지.
9. `host_ready_restart_guards` — 초기 실패에서 scene에 sim과 presentation이 생성되지 않고 프레임 진행이 꺼졌음을 확인. 별도의 활성 전투에서 `_restart` 실패 시 `_start` 효과 없음도 같은 행의 독립 단언으로 확인.
10. `recover_publish_once` — 정상 후보로 복구 후, 원래 trace 파일의 마지막에 `session_closed` 한 건이 붙고 새 파일이 정확히 하나 열리며 그 파일의 첫 줄에 seq 1 `session_start` 한 건을 관측한다. 기존 파일의 이전 바이트는 동일하다. 파일 두 개의 내용은 시스템 시각·monotonic 시각·임시 경로만 정규화하며 사전 오라클과 실제 새 native 초기화의 roster/seed/hz/초기 controls에 대조한다. 기존 FleetView identity가 모두 사라지고 새 뷰와 정상 UI·카메라·시계가 나타나는지, 이전 큐의 구별 가능한 사건이 새 sim에 들어가지 않았는지 확인한다. 게시 횟수의 외부 계수는 trace close/start를 기준으로 한다.

각 활성 실패에서 기존 trace의 FileAccess identity, path, seq, 전체 바이트 및 trace 파일 집합, 화면과 관련 노드의 값, 전투와 VM/시계 identity를 동기 호출 직전·직후 비교한다. 적어도 두 직접 실패와 실제 deck 경로 하나에서는 기존 sim에 실제 대기 사건을 먼저 만들고 실패 뒤 별도 native 기준과 큐 내용/순서를 대조한다. 명시 실패의 같은 frame 관측으로 평상시 시간 진행에 따른 부수 변화를 분리한다. 도구에서 관측 불가능한 수치나 로그를 가정하지 않는다. 최초 실행 전 각 행의 입력, 예상 결과, 스냅샷 필드, launcher와 전후 파일 해시를 고정한다.

기존 PLAN과 freeze를 보존한다. 세 제품 파일에 명시한 함수 외 hunk를 허용하지 않는다. 실행 입력·소유 hunk의 바이트가 다른 세션과 겹치면 보류한다. 독립 계획 수용 전 제품 코드를 편집하지 않는다.
