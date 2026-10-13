# REVIEW-P1-FORM-TARGET — 진형 전환 명령 즉시 목표 모양 표시(F-1·F-2, S-2 a)

- 대상: `p1-form-target` 5935db1 (`git diff main...p1-form-target`, 기반 main 828dd2c)
- 리뷰어: 5-b 교차 리뷰(Opus). 코드·main 수정 없음, 커밋 없음
- 방법: 리뷰 worktree를 5935db1·828dd2c로 detach해 `--import` 뒤 헤드리스 순차 실행. POC 경로는 scratch 스크립트(`BattleSim.new(1)` → `projection(0)` → `BattleViewModel.apply`)로 확인
- 규칙 정본: `BATTLE_DECISIONS.md` S-2 a(:781~), 제안서 §4.7(:440~441)

## 판정: **조건부 수용** (H1 한 줄 수정 후 병합)

코어 결정론은 그대로다(AI 대 AI 8판 지문 8/8 일치). 새 필드는 sim 판정에 쓰이지 않고, 안개 접촉에 새 키가 없고, boundary 신규 위반도 0이다. 다만 **POC 프로필(salvo 없음)에서 `form_to_pts`가 빈 배열이라 뷰 모델 `form`이 비고, 효과 위치 계산이 0으로 나눈다**(H1). 시나리오 로드 실패 시 대체 경로라 실제로 탈 수 있다.

## 발견

| # | 심각도 | 위치 | 내용 | 근거 |
|---|---|---|---|---|
| H1 | 높음(회귀) | `battle_projection.gd:145`, `battle_view_model.gd:174`, `fx_layer.gd:45` | POC(salvo null)에서는 `_apply_shape`가 불리지 않아 `f.form_t`가 `[]`다. 투영에 `form_to_pts: []` 키가 **있으므로** `s.get("form_to_pts", s.form)` 기본값이 안 쓰이고 뷰 모델 `form`이 빈다. `FxLayer.ship_pos`의 `i % f.form.size()`가 0으로 나눈다(피격·폭발 효과마다 오류). main에서는 28개였다. POC는 `FleetBattle3D.gd:182·196`(profile_def 없음 / 시나리오 읽기 실패 대체)에서 열린다 | scratch 실행: `salvo=<null> form=28 form_to_pts=[]`, `vm form size=0`. 수정안(한 줄): 투영에서 `"form_to_pts": f.form_t if not f.form_t.is_empty() else f.form` (또는 `_spawn`에서 `f.form_t = f.form`). POC 시험 1개(투영 `form_to_pts.size() == form.size()`) 추가 |
| M1 | 중간(문서·화면 확인) | 제안서 §4.7 :441 "함선이 전환 시간 동안 새 슬롯으로 움직이는 것을 보인다" | 렌더러는 `_reform`으로 새 슬롯을 즉시 배정하고 함선은 `TAU` 0.3초 지수 추종(`fleet_renderer.gd:46·376`)이라 **약 1초 안에 목표 모양에 도착**하고, 남은 약 4초는 목표 모양으로 선 채 코어는 이전 진형이다. 전환 시간과 이동이 묶여 있지 않다 | 사용자 결정 S-2 a "명령 즉시 3D 전환"과는 맞다. 문구를 "명령 즉시 새 슬롯으로 이동해 목표 모양을 보인다(이동은 약 1초, 효과는 완료 때)"로 고치거나, 전환 진행에 맞춰 천천히 움직일지 사용자 결정(아래 D1) |
| L1 | 낮음 | `battle_view_model.gd:174` → `fx_layer.gd:45` | 전환 중 피격·폭발 효과 위치는 목표 배치(`form_t`), 코어 피격 위치(`battle_sim.gd:262 _rand_ship`)는 현재 배치(`f.form`)다. 함선이 1초 안에 목표 슬롯에 가므로 화면상 어긋남은 첫 1초뿐이다. 연출 전용이라 결과 영향 없음 | 의도(F-2)대로다. 기록만 |
| L2 | 낮음(문구) | `BATTLE_DECISIONS.md` S-2 a 비고 | "키가 안개 접촉에 없어 결과가 같다"는 안개가 켜진 경우만 맞다. 안개가 없으면(`detect == null`, POC 등) 적 전대도 `squadron()` 전체를 받아 `formation_to`가 실린다. 다만 그때는 이미 `formation_id`·`form_to`가 공개돼 새 정보가 아니다 | `battle_projection.gd:14~15`. 문구에 "(안개 없는 POC는 이미 전체 공개)" 덧붙이면 충분 |
| L3 | 낮음 | `salvo.gd:155·210` | `form_t = form`은 같은 배열 참조다. 지금은 `form`을 언제나 새 배열로 바꾸고(`formation_offsets`) 제자리 수정이 없어 문제없다. 나중에 `form`을 제자리 수정하면 표시용이 같이 바뀐다 | 기록만 |

### 확인했고 문제없는 것
- **결정론·지문**: `battle_fingerprint.gd:36`에 `shape_to`·`form_t` 없음(`form_to`·`form_left`만). AI 대 AI `autoresolve --profile red_cliffs --runs 4 --policies none,attack --rows 1`, 시드 0~3, main 828dd2c ↔ 5935db1: **지문 8/8 같음, 승패·종료 사유·길이 8/8 같음**(none: 승 1/4, attack: 승 1/4). `formation_rules` §8(진형 명령 섞은 결정론)도 통과.
- **sim 로직 미사용**: `shape_to`·`form_t`는 `salvo.gd`(대입)와 `battle_projection.gd`(읽기)에만 있다. 사거리·명중(`hit_bp`), 피격 위치(`_rand_ship` = `f.form`), 충돌, 표적, AI(`commander_ai.gd:232`, `poc_enemy_ai.gd:66`은 `form_to`만)는 읽지 않는다. `f.shape`도 코어 판정에 안 쓰인다.
- **경로별 값**: 시작(`init_fleet`→`_apply_shape`), 지형 강제(`_enforce_terrain`), 완료(`_transition_step`→`_apply_shape`), 즉시 변경(`force_formation`: 신기묘산·화공 간파·긴급 분산·`skills.gd:361`), 취소(`fid == formation_id`), 전환 중 다른 진형 재명령(`fid != form_to` → `_show_target` 다시) 모두 `shape_to`/`form_t`가 맞게 갱신된다. 같은 목표 재명령은 아무것도 안 바꾼다(기존과 같음). 사망은 진형 상태를 건드리지 않고 렌더러가 `dead`로 처리한다. 재생(`BattleSim.replay`)은 같은 명령 경로를 다시 밟아 같은 값을 만든다.
- **`_reform` 반복 없음**: 렌더러는 `sq.formation != v.formation`일 때만 `_reform`(`fleet_renderer.gd:638`). 명령 때 1회, 완료 때는 `formation_to == formation`이라 0회, 취소 때 1회(원래 모양으로 복귀)다. 매 틱 재트리거 없음.
- **공개 경계**: 안개 시 적은 `contact()`(:104~125)만 받고 새 키 없음. 뷰 모델 접촉 경로(`_apply_contact`)는 고정 격자를 쓴다. `boundary`: 기존 3건(`battle_source.gd:177`, `org_screen.gd:137·138`, 줄 번호만 이동)뿐, 신규 0.
- **시험**: `formation_rules` 새 검사는 투영 키를 `BattleRules.formation_offsets`로 독립 계산해 비교하고 `form_to_pts != form`도 확인해 동어반복이 아니다. 취소·완료 복귀도 본다. `formation_display`는 `ally.shape == tshape`(독립 계산)과 뷰 모델 전달을 본다. 빠진 것: POC 경로(H1), 전환 중 다른 진형 재명령, 신기묘산 중도 완료 때 `shape_to` 동기화.
- **문서**: 제안서 §4.7 추가 줄의 `formation`·`formation_id` 완료 틱 변경, 취소·즉시 변경 시 현재와 같음은 코드와 일치(M1 문구만 예외). :480 정정(`_apply_contact`가 확인 때만 이름·초상을 쓰고 지우지 않음, 처음은 "미확인 함대")도 `battle_view_model.gd:251~` 코드와 맞다.

## 실행 결과 (5935db1, 순차·단독)

| 시험 | 결과 |
|---|---|
| formation_rules | FORMATION_RULES_PASS |
| formation_display | OK formation_display |
| formation_ui | FORMATION_UI_PASS |
| core_rules | CORE_RULES_PASS |
| battle_flow | BATTLE_FLOW_PASS |
| data_rules | DATA_RULES_PASS |
| info_panel | OK info_panel |
| ui_flow | UI_FLOW_PASS |
| fx_follow_formation(추가) | FX_FOLLOW_FORMATION_PASS |
| boundary | 실패 3건 = 기존과 같음, 신규 0 |
| autoresolve red_cliffs 4시드×2정책 | main과 지문·승패 8/8 같음 |

## 병합 조건
1. H1 수정(투영 `form_to_pts` 빈 배열 대체) + POC 시험 1개.
2. M1 문구 정정(또는 D1 결정에 따라 구현).

## 사용자 결정 필요
- **D1**: 3D 함선이 명령 즉시 약 1초 만에 목표 모양에 도착하고 나머지 4초는 목표 모양으로 대기(현재). 이대로 둘지, 전환 시간(5초, 팔진 2.5초)에 맞춰 천천히 이동하게 할지. 후자는 렌더러가 `form_left_s`로 추종 속도를 늦추는 표시 전용 변경이라 코어 영향 없음.
