# REVIEW-P9-FOLLOWUP — 그룹 진형 제외 표시 · 초기 배치(Q70)

- 대상: `p9-followup` 654c5d7 (`git diff main...p9-followup`, 기반 main 74bde13)
- 리뷰어: 5-b 교차 리뷰(Opus). 코드·main 수정 없음, 커밋 없음
- 방법: 별도 worktree를 654c5d7로 분리 체크아웃 → `--import` → 헤드리스 개별 순차 실행. 뒤에 `assets/*.import`·새 `.uid`를 되돌림
- 규칙 정본: `BATTLE_DECISIONS.md` Q70(:668·:684), 제안서 §6.1(:728~737), `CHECKLIST-OPEN.md` :235~237·:252~253, `SESSION-HANDOFF.md` :186·:199·:279~

## 판정: **조건부 수용(H1·H2 수정 뒤 병합)**

코어 `place`는 작고 결정론적이다. `issue()` 즉시 적용 → `command_log`(tick 0) → `replay`가 같은 틱 첫머리에 `queue`해 같은 결과를 낸다. 틱 0 밖은 `place_late`로 거부한다. 기본값(직접 배치 꺼짐)에서는 `place`가 한 번도 나오지 않고, 새 필드 `spawn`은 지문에 들어가지 않는다. 그래서 AI 대 AI 지문은 바뀌지 않는다(`core_rules`·`battle_flow`·`commander_ai` 통과). 호스트의 명령 입구도 `issue()` 하나뿐이다(`sim.issue` 호출처 1곳). 그래서 배치 중 차단이 새는 경로가 없다.
다만 **기존 정적 검사 2개가 새로 실패한다(H1·H2)**. 완료 기준("테스트 통과")에 걸린다. 둘 다 몇 줄이면 고친다.

## 발견

| # | 심각도 | 위치 | 내용 | 수정 제안 |
|---|---|---|---|---|
| H1 | 높음 | `core/battle/battle_sim.gd:40` | `const PLACE_RADIUS := 160.0`가 코어 규칙 수치 리터럴이다. **`tests/data_rules.gd`가 실패한다**(`core에 규칙 수치 리터럴: battle_sim.gd:40 160.0`). "수치 한 곳"이라는 의도는 맞지만 둘 곳이 data다 | 프로필 규칙으로 옮긴다. 예: `realtime_rules`/`PocSetup.profile().rules`에 `place_radius`, 코어는 `R.place_radius`로 읽는다(data_rules 2절 "읽는 키가 프로필에 있다"도 같이 맞춘다). 생성기가 있으면 생성기에도 넣는다 |
| H2 | 높음 | `hud/ui_kit/tactical_overlay.gd:75` | HUD가 `battle.sim.st.by_id(f.id).spawn`(코어 상태)과 `BattleSim.PLACE_RADIUS`(코어 클래스)를 직접 읽는다. **`tests/boundary.gd`에 새 위반 1건**이 생긴다(기존 3건 `battle_source.gd:177`, `org_screen.gd:131·132`에 더해 4건). 투영 경계 위반이다 | 아군 투영(side 0)에 `spawn`(자기 전대만)과 허용 반경을 넣거나, `BattleSource.place_zone(id) -> {center, r}`처럼 투영·소스를 거쳐 읽는다. 호스트 `place_auto`(`FleetBattle3D.gd:436`)가 `sim.st`를 읽는 것은 호스트라 허용 범위다(기존 관례) |
| M1 | 중간 | `scripts/FleetBattle3D.gd:414~422` | 배치 중 허용 명령이 `move→place`, `formation`뿐이다. 제안서 §6.1(:732·:734)은 배치 단계에서 **전투 방침과 방향**도 정한다. `posture`·`delegate`·`face`는 "확정 뒤에" 토스트로 막힌다. 틱 0이고 시간이 멈춘 상태라 막을 이유가 없다 | 허용 목록에 `face`·`posture`·`delegate`(필요하면 `def`)를 더한다. `face`는 정지 중 회전이 안 보이므로 `place`처럼 즉시 `heading`을 정하는 것이 맞는지는 아래 사용자 결정 2 |
| M2 | 중간 | `battle_sim.gd:678~697` `place` | ① 배치 뒤 `heading`을 다시 계산하지 않는다. 초기 방향은 `salvo.finish_setup`(`salvo.gd:81~84`)이 **시작 위치**에서 가장 가까운 적을 보게 정한 값이다. 크게 옮기면 엉뚱한 쪽을 보고 시작해 첫 몇 초를 회전에 쓴다 ② 그룹 배치는 함대마다 따로 반경을 자른다. 이미 옮긴 함대가 섞여 있거나 경계에 닿으면 대형이 찌그러진다(시작 위치 그대로일 때만 간격이 유지된다) ③ `args`(via, strafe, facing_deg)는 버린다 | ① `place` 끝에 `finish_setup`의 초기 방향 규칙을 다시 적용한다(결정론 유지, 규칙 재사용). ② 그룹 이동량을 "모든 함대가 반경 안에 드는 최대 비율"로 줄여 대형을 지킨다(선택). 지금도 의도된 단순화라면 주석으로 남긴다 |
| M3 | 중간 | `tests/placement_ui.gd:36~37` | "배치 중 공격 지시는 막힘"이 동어반복이다. 틱 0에는 탐지 평가가 아직 없어서 `alive(1)`이 비고(`detection.gd` 접촉은 첫 평가 뒤에 생김), **자기 함대 `f`를 공격 표적으로** 보낸다. 이것은 코어가 원래 거부하므로 `target_id == -1`이 placing 차단과 무관하게 참이다 | 차단 여부는 토스트나 `command_log`에 `attack`이 없는지로 본다. 또는 `stop`·`posture` 같이 코어가 받는 명령으로 시험한다 |
| L1 | 낮음 | `command_deck.gd:997~999` | 제외 토스트가 카드 상태와 무관하게 뜬다. `state == "current"`(전환 취소)나 `"to"`일 때 누르면 실제 동작은 취소/재지정인데 "N개 함대 제외"가 뜬다 | `b.opt.state == "ok"`일 때만 토스트 |
| L2 | 낮음 | `command_deck.gd:831` | 주석 "전환 중이면 목표 진형 표시"와 달리 `src.form_name`은 현재 진형만 준다. 요약 문자열의 너비 제한(`0.0`)도 없어 진형이 여러 종이면 왼쪽으로 길어질 수 있다 | 주석을 고치거나 `form_to`를 `→이름`으로 붙인다. 화면 확인 항목 |
| L3 | 낮음 | `FleetBattle3D.gd:433~437` `place_auto` | 함대마다 `place` 1건씩 기록한다(아군 N건). 시작 위치가 양자화 격자 밖이면(`enlarge_field`로 늘린 좌표) `quant_v(spawn) ≠ spawn`이다. 그래서 "자동 배치로 되돌림"이 직접 배치를 아예 안 한 것과 비트 단위로 같지 않다. 재생 결정론에는 문제없다 | 의도대로라면 두어도 된다. 같은 결과가 필요하면 `_spawn`에서 `f.pos`를 `quant_v`한다(그러면 기준선 지문이 바뀌므로 비추천) |
| L4 | 낮음 | `FleetBattle3D.gd:259` | `placing`은 `_start`에서만 다시 정한다. `to_title`·`back_to_world`로 나가도 참으로 남는다. 지금은 다음 시작 경로가 모두 `_start`를 지나서 해는 없다 | `init_game`에서 `placing = false`(한 줄) |
| L5 | 낮음 | 설계 수치 | `PLACE_RADIUS` 160은 전장 px 고정값이다. 플레이 전장 1700×1150(`FIELD_SIZE`)에서 가로 9%·세로 14%다. `move_mul` 150이면 약 1초 이동 거리여서 배치의 전술 가치가 작다. `enlarge_field` 배율도 따르지 않는다 | H1에서 data로 옮길 때 사용자 결정 1과 함께 정한다 |
| L6 | 낮음 | 저장소 관례 | 새 시험 `tests/placement.gd.uid`·`placement_ui.gd.uid`가 커밋되지 않았다(다른 시험 57개는 `.uid`가 추적된다). `--import` 때마다 미추적 파일이 생긴다 | 두 `.uid`를 같이 커밋한다 |
| L7 | 낮음 | 배치 중 정보 | 틱 0에는 탐지 평가가 아직 돌지 않아 **적이 하나도 보이지 않는 채로** 배치한다. §6.1의 "탐지된 적만"보다 적게 보인다. 공개 경계 위반은 아니다(덜 보임) | 사용자 결정 3 |

### 확인했고 문제없는 것

- **결정론·재생**: `issue`는 `c.tick = st.tick(0)`로 기록하고 즉시 `apply`한다. `replay`는 틱 0의 기록을 `queue` → `step()` 첫머리에서 같은 순서로 적용한다. 그 사이 틱이 진행되지 않으므로 상태가 같다. `placement.gd` 3절(120틱 후 지문 일치)이 이를 실제로 본다. `place`가 기록에 없으면 실패하는 시험이라 빈 검사가 아니다. 플레이 프로필(`enlarge_field`·`tune_for_play`)도 replay가 같은 프로필을 쓰므로 같다.
- **틱 0 밖 거부**: `st.tick != 0` → `_reject(L, "place_late")`. 시험 4절이 사유 코드까지 본다. 증원(`_spawn_reinf`)은 틱 0 뒤에만 생기므로 배치 대상이 아니다.
- **기본값 지문 불변**: `place_mode` 기본 false. `spawn`은 `BattleFingerprint`에 없다. `place`는 `DIRECT_KINDS`에 없어 `control`을 바꾸지 않는다(배치는 지휘가 아니라는 해석과 맞다). 위임 함대는 확정 뒤 AI가 그대로 움직인다.
- **home 갱신과 AI**: `home`을 읽는 것은 기함 귀환(`commander_ai.gd:139`, `poc_enemy_ai.gd:43·61`)뿐이다. 아군 기함 위임 시 배치 위치로 돌아가는 것이 의도와 맞다. 적 쪽은 `place`를 내지 않는다.
- **반경·경계 수학**: 반경을 먼저 자르고 전장 경계를 다음에 자른 뒤 `quant_v`한다. 경계 때문에 반경 안쪽으로만 줄어들므로 반경 밖으로 나가지 않는다. 호스트 `order_move`의 `_fit_to_field`가 그룹 중심을 먼저 당겨 경계 뭉침을 줄인다.
- **틱 정지와 다른 경로**: `_process`는 `placing`이면 `clock.advance`를 부르지 않는다(누적 없음, 확정 뒤 첫 프레임에 몰아치기 없음). 일시정지(`G.state = "pause"`)를 거쳐도 `placing`은 유지되고, `resume` 뒤에도 배치가 계속된다. `begin_battle`(편성 화면에서 옴)·`restart`·`_restart`가 모두 `_start`를 지나 `placing = place_mode`로 다시 정한다. `restore_orders`(되돌리기)는 `restore` 종류라 배치 중에는 토스트로 막힌다. `place`는 `has_move`·표적을 새로 만들지 않아 되돌리기 알림을 띄우지 않는다. 건너뛰기(pacing)는 속도만 바꾸므로 틱 정지를 우회하지 못한다. `update_sim`은 헤드리스 시험 전용이다.
- **적 정보 공개 경계**: 선택은 아군만 된다(`battle_input.gd:52`, `touch_controller.gd:40·101`, `in_rect(alive(0))`). 허용 원은 선택 함대 것만 그려 적의 시작 위치가 드러나지 않는다(H2는 경계 위반이지 정보 누설은 아니다).
- **그룹 진형 표시**: 코어 무변경. `who`는 `form_info.block`(이미 투영된 아군 정보)에서 만든다. `reason != ""` ⇔ `n_block > 0` ⇔ `who` 비지 않음이라 빈 "제외:" 줄은 생기지 않는다. `placement.gd` 1절은 UI `who` 수를 코어 `master_ok` 술어와 맞대 본다(동어반복 아님).
- **터치**: 배치는 기존 끌기 명령(`touch_controller` "order" → `order_move`)을 그대로 쓴다. 다만 다중 선택에서는 **선택 중심**이 손가락 위치로 가고, 끈 함대가 손가락 아래로 오지 않는다(이동 명령과 같은 규칙). 막대 버튼은 56px 높이라 엄지 기준에 맞다.

## 테스트 결과 (654c5d7, 개별 순차 실행, 다른 세션 Godot와 같은 PC)

| 결과 | 테스트 |
|---|---|
| 통과(8) | placement, placement_ui, core_rules, formation_ui, battle_flow, commander_ai, ui_wording, ui_flow |
| **새 실패(이 브랜치)** | `data_rules`(H1), `boundary`(H2: 4건 중 `tactical_overlay.gd:75`가 새 위반, 나머지 3건은 기존 실패) |
| 제외 | autoresolve·salvo_compare(기준선 측정은 기본값 지문 불변이라 불필요), capture_*·audit_*·bench_* |

## 사용자 결정이 필요한 것

1. **허용 반경 수치와 단위**(L5·Q70 "수치는 구현 때"): 160px 고정 / 전장 크기 비율 / 세력 진입 구역(사각형). H1 수정 때 data 키로 같이 정한다.
2. **배치 단계에서 방향 지정**(§6.1 "초기 위치와 방향", M1): 틱 0 전용 즉시 회전(`place`에 `facing_deg` 받기)으로 할지, 확정 뒤 일반 `face`로 둘지.
3. **배치 중 적 표시**(L7): 틱 0에 탐지 평가를 한 번 돌려 "탐지된 적만" 보여 줄지(코어 변경, 기본값 지문 영향 확인 필요), 지금처럼 적을 보지 않고 배치할지.
4. Q70 :684의 "정지 중 이동 vs 순간 배치"는 구현이 **순간 배치(틱 0 전용 `place`)**를 골랐다. 문서에 결정으로 남길지 확인한다(`BATTLE_DECISIONS.md` Q70 행 갱신).

## 사용자 로컬 확인 체크리스트

1. 브리핑에서 "직접 배치" 켜고 출격 → 상단 배치 막대가 뜨고 시간이 멈추는지, 개시 컷인·"조조군 선봉 진입" 로그가 배치 화면을 가리지 않는지.
2. PC 우클릭·태블릿 끌기로 함대를 금빛 원 밖까지 끌면 원 끝에 멈추는지. 그룹(2~3개)을 끌 때 대형이 유지되는지(M2 ②).
3. 배치 중 일시정지 → 재개 → 배치가 이어지는지. "자동 배치" → 모두 원 중심으로 돌아가는지. "배치 확정" 뒤 시간이 흐르는지.
4. 크게 옮긴 함대가 시작 직후 엉뚱한 방향을 보고 도는지(M2 ①).
5. 다중 선택 패널 머리의 진형 요약이 칩·꺾쇠와 겹치지 않는지(L2). 일부 제외 진형 카드의 툴팁 "제외: 이름(사유)"와 누른 뒤 토스트 문구.
