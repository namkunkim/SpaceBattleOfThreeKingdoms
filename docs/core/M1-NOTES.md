# M1 구조 분리: 구현 메모

2026-10-04, 구현 세션. 브랜치 `feature/battle-core-m1`. 설계 문서(`docs/battle-core/`)는 컨셉 세션이 맡으므로, 구현에서 나온 사실과 편차는 여기에 적는다.

## 1. 구조

```
core/battle/           코어(Node·Input·전역 난수·Time·타이머·delta 없음)
  rules.gd             BattleRules  순수 규칙 함수와 수치 상수, 진형 좌표
  battle_rng.gd        BattleRng    sha256(프로필|틱|사건ID[:하위]) 규칙 난수
  battle_state.gd      BattleState  판 전체 상태(전대, 미사일, 함재기, CP, 시계, 사건 ID 카운터)
  fleet_state.gd       FleetState   전대 상태. 참조는 ID만
  battle_sim.gd        BattleSim    고정 틱, 명령 검증·기록·재생, 사건 발행, 규칙
  battle_projection.gd BattleProjection  공개 투영 v0(사전)
  battle_fingerprint.gd              상태 지문(정수·0.001 격자만)
  tick_clock.gd        TickClock    누산기(속도는 소비 속도만, 프레임당 틱 상한 8)
  poc_setup.gd         PocSetup     POC 편성(M2에서 시나리오 JSON으로 교체)
  ai/poc_enemy_ai.gd   PocEnemyAi   POC 적 AI(명령으로 결정을 낸다)
view/                  battle_view_model(투영 → 화면 모델, 틱 사이 보간) · battle_view_3d · camera_rig · fx_layer(연출 전용 난수)
hud/                   battle_hud · fleet_labels · radar   (POC HUD. 상품화 HUD가 있으면 숨김)
input/                 battle_input · battle_commands      (명령 사전만 만든다)
scripts/FleetBattle3D.gd  전투 노드(호스트): BattleSim·TickClock 소유, 투영 → 화면 모델, 사건 → 로그·토스트·연출, 호환 API
```

- 상품화 표현 계층(`hud/ui_kit/`, `view/fleet_render/`, `input/touch/`)은 호스트의 호환 API(`fleets`, `G`, `selected`, `do_cmd` …)로 그대로 동작한다. 고친 파일은 `view/fleet_render/battle_source.gd`의 `restore_orders` 한 함수뿐이다.
- 코어가 상태의 권위다. 화면 객체의 필드를 직접 쓰면 다음 틱에 덮어써진다. 명령은 `do_cmd`, `order_move`, `order_attack`, `restore_orders`로 낸다. 테스트가 상태를 만들 때는 `tests/lib/poke.gd`(`TestPoke.fleet`)를 쓴다.
- 플레이어 명령은 `BattleSim.issue()`로 즉시 적용되고 틱 번호와 함께 `command_log`에 남는다. AI 명령은 상태에서 다시 나오므로 기록하지 않는다. 재생(`BattleSim.replay`)은 같은 틱 번호에 같은 명령을 넣는다.

## 2. 수치 표현

| 값 | 표현 |
|---|---|
| 척 수, 경험치, 피해량 | 정수 1/1000척 |
| CP | 정수 bp(1점 = 10000), 회복은 나머지를 이월하는 정수 누산 |
| 시간 | 틱(정수)과 하위 걸음 ms(정수). 쿨다운·돌격·말풍선 타이머는 틱, AI 주기·미사일 나이·함재기 수명·게임 시계는 ms |
| 위치·방향 | 실수. 매 틱 끝에 0.001 격자로 반올림(half-up). 지문에는 정수화한 값만 |
| 규칙 난수 | 사건 ID 카운터 + 하위 번호. 연출 난수는 `view/fx_layer.gd`의 전용 생성기 |

## 3. 기준 POC와 달라진 점 (규칙이 아니라 구현)

기준선(`tests/fixtures/m1_baseline.json`)은 M1 이전 POC를 `seed(i)`, dt 0.05로 돌린 것이다. 동등성을 지키려고 다음을 정했다.

1. **틱 안 하위 걸음.** 10Hz 틱 한 번을 0.05초 이하 걸음으로 나눠 돈다(증원 → AI → 함대 이동·사격 → 간격 → 미사일 → 함재기 → 승패, 기준과 같은 순서). 0.1초 한 걸음으로 돌리면 추격·사격 순서의 이산화로 통계가 어긋난다(30초 돌격 정책에서 격침 +15%, KS D 0.83). 틱, 명령, 기록, 난수, 사건은 10Hz 그대로다. 하위 걸음은 결정론이다.
2. **기준 POC의 부동소수 오차.** 기준은 타이머를 실수 0.05씩 빼서 의도와 다르게 돌았다.
   - AI 주기: 의도 0.5초, 실제 0.55초(11프레임).
   - 함재기 수명: 의도 9.0초, 실제 9.05초(181프레임).
   - 쿨다운(18·26초), 돌격(10초)은 의도대로였다.
   기준선이 이 값으로 잡혔으므로 코어도 실효 값 0.55초·9.05초를 쓴다(`BattleRules.AI_PERIOD_MS`, `SWARM_LIFE_MS`). 규칙으로서 0.5초가 맞다면 M3에서 정리하고 기준선을 다시 잡는다.
3. 증원 시각은 시계가 95.000초를 넘는 첫 하위 걸음(95.05초)이다.
4. 미사일 명중은 기준과 같은 점 판정(이동 뒤 위치가 표적 22px 안)이다. 하위 걸음 이동(≤20px)이 판정 지름(44px)보다 작아 놓치지 않는다. 선분 판정(§3.3)과 비교했을 때 1000시드 통계가 소수점까지 같았다. 걸음이 더 커지면(M3 이후 빠른 고속정 등) 선분 판정으로 바꾼다.
5. 쿨다운·돌격 같은 "초" 값은 틱 폭에 따라 틱 수로 바뀐다(`BattleRules.ticks`). 20Hz에서도 같은 코드가 돈다(`--hz 20`).

## 3.1 M1에서 고치지 않고 목록으로만 남긴 것 (제안서 §9.1)

- 방향 경계(`<60°`와 `≤60°`): M3.
- 후퇴 중 표적이 없을 때의 처리: M4.
- AI의 전지적 시야(`PocEnemyAi`는 전체 상태를 본다): M6·M7.
- 진형 슬롯 좌표가 미사일 발사 위치를 정하는 것, 함재기 첫 점 위치가 피해 조건인 것: M3.
- 이 파일 §3의 AI 주기 0.55초, 함재기 수명 9.05초.

## 4. 시험과 실행기

헤드리스(`godot --headless --path . -s <파일>`), 실패하면 종료 코드 1이다. **새 worktree에서는 먼저 `godot --headless --path . --import`를 한 번 돌려야 한다**(전역 클래스 캐시가 없으면 `BattleSim` 같은 이름을 못 찾는다. 새 `class_name` 파일을 추가한 뒤에도 같다).

| 파일 | 내용 |
|---|---|
| `tests/core_rules.gd` | 방향, 화력식, CP, 명령 검증, 증원 시각, 결정론(100·600·종료 지문), 속도 무관, 누산기, 재생, 승패 경로 |
| `tests/boundary.gd` | 코어 금지 API 0건, `view/`·`hud/`·`input/`의 코어 클래스 참조 0건 |
| `tests/battle_flow.gd` | 수동 점검표: 선택, 그룹, 명령 8개, 토스트, 로그, 속도, 종료 화면, 재시작, 재생 |
| `tests/autoresolve.gd` | 정책 3종 × N시드 통계 JSON, `--baseline`으로 동등성 판정 |
| `tools/m1/baseline_poc.gd` | **M1 이전 POC 커밋에서만** 돈다. 기준선 생성기 |

```
godot --headless --path . -s tests/autoresolve.gd -- --runs 200 --hz 10 --baseline res://tests/fixtures/m1_baseline.json
```

동등성 판정은 정책마다 (1) 승률 |Δ| ≤ 5%p, (2) 종료 경로 비율 |Δ| ≤ 5%p, (3) 길이·양측 손실·증원 시각을 2표본 KS(D < 0.136)로 비교한다. 기준선에서 변동계수가 1% 미만인 값(거의 상수)은 KS 대신 평균의 상대 차이 1% 이내로 보고, 결과 JSON에 어느 방법으로 판정했는지 적는다(컨셉 세션 제안).

## 5. 상품화 HUD와 POC HUD

두 HUD가 함께 있다. 상품화 표현 계층이 있으면 POC HUD의 `CanvasLayer`가 통째로 숨겨지고 POC 함대 3D 노드도 숨겨진다. POC HUD(`hud/battle_hud.gd` 등)는 표현 계층이 없는 환경(헤드리스 테스트, 폴백)의 최소 화면이자 수동 점검표의 기반이다. 일원화(POC HUD 삭제)는 M10 화면 개편에서 정한다.

## 6. 남은 일 (M1 안)

- 화면 수동 점검(`tests/battle_flow.gd`로 API는 확인했다. 실기 화면 확인은 사용자).
- `battle_source.gd`를 투영 기반으로 옮기기(UI 세션과 협의). 지금은 화면 모델을 읽는다.
- 선택 감속을 `Engine.time_scale`에서 `TickClock.set_speed`로 옮기기(UI 세션과 협의, 기본값 끔).

## 7. 통계 동등성 결과 (10Hz, 하위 걸음 포함)

기준선은 M1 이전 POC 200시드(`tests/fixtures/m1_baseline.json`)와 같은 조건 1000시드(진단용, 저장소에 넣지 않음)다.

| 정책 | 승률 Δ | 종료 경로 Δ | 길이 D | 아군 손실 D | 적 손실 D | 증원 시각 | 비고 |
|---|---|---|---|---|---|---|---|
| 무명령 (1000) | 0 | 0 | 0.054 | 평균 차 0.0% | 0.054 | 평균 차 0.0% | 통과 |
| 5초 공격 (1000) | 0 | 0 | 0.123 | 0.084 | 평균 차 0.01% | 0.087 | D < 0.136 통과, 유의 임계값(0.061)은 초과 |
| 30초 돌격 (1000) | 0 | 0 | 0.036 | 0.051 | 0.042 | 평균 차 0.0% | 통과 |
| 5초 공격 (200) | 0 | 0 | 0.125 | 0.105 | 평균 차 0.01% | 0.100 | 통과 |
| 30초 돌격 (200) | 0 | 0 | **0.160** | 0.100 | 0.100 | 평균 차 0.0% | 200시드 우연(1000시드는 0.036) |

- 승률은 정책마다 0% 또는 100%로 포화돼 판별력이 없다. 종료 경로 분포가 바뀌지 않았고(무명령·돌격은 전부 기함 격침, 공격은 전부 전멸) 시간 초과도 없다.
- **5초 공격 정책에서 길이가 평균 1.4% 짧고(104.6초 대 106.0초) 아군 손실이 1.8% 적다.** 20Hz로 돌려도 같다(D 0.113). 그래서 틱 폭 때문이 아니라 아군 미사일·함재기 쪽의 미세한 구조 차이다. 미사일 판정(점 대 선분), 틱 폭, AI 주기·함재기 수명, 분리·순서 항목은 원인이 아님을 확인했다. 아직 찾지 못했다. 효과가 작고(§9.2 효과 크기 기준 안) 승패에 영향이 없어 M1에서는 목록으로 남긴다.
- 200 대 200 KS는 D < 0.136이 5% 유의수준 임계값과 같아서 완전히 같은 구현도 지표 12개 중 하나를 우연히 넘길 수 있다. 판정은 1000시드로 하는 것을 권한다(`--runs 1000`, 한 정책 4~6분).

## 8. 후속 (컨셉 세션 리뷰 REVIEW-M1 반영)

- 5초 공격 정책의 길이 −1.4%는 보류. M3 시작 때 같은 증상이 남아 있으면 이분 탐색을 한 번 한다. 0.55초·9.05초는 POC 전용이라 기준선을 다시 잡지 않고 M3 새 규칙으로 대체될 때 사라진다.
- 선택 감속을 `Engine.time_scale`에서 `TickClock.set_speed`로 옮길 때, Q55의 유휴 5초 해제 타이머가 감속의 영향을 받지 않는 **실시간 기준**인지 확인한다(UI 세션 `battle_pacing.gd`는 지금 `UiDraw.real_dt`로 `Engine.time_scale`을 나눠 실시간을 얻는다. 코어 시계 속도로 옮기면 `Engine.time_scale`이 1이 되므로 이 보정이 그대로 맞는지 같이 본다).
- 정보 경계와 투영의 빈 자리(`counts`, `control`, `chain_op`, `pending_decisions`)는 M6·M7. POC HUD 이중 구조는 M10.
- 다음 M2: 시나리오 JSON의 `difficulty_policy`, `deploy_delay_s`, `realtime_rules`(status "proposed" 포함)를 데이터로 읽게 한다. `core/battle/poc_setup.gd`와 `BattleRules`의 상수가 대상이다.
