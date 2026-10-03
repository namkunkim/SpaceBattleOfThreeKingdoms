# 구현 세션 인수 문서: 실시간 전투 코어 (2026-10-03)

M1 구조 분리부터 코어 구현을 맡을 세션이 처음 읽는 문서다. 설계는 컨셉·시나리오 세션이 맡고, 이 문서는 그 결과를 구현 관점으로 묶은 것이다.

## 1. 먼저 읽을 것

| 순서 | 문서 | 왜 |
|---|---|---|
| 1 | `BATTLE_DECISIONS.md` | 사용자 결정 Q1~Q55. 구현이 결정과 어긋나면 결정이 이긴다 |
| 2 | `PROPOSAL-realtime-battle-core.md` v0.2 | 규칙 전체, §9 단계(M0~M12), §9.1 M1 이전 단계, §9.2 M1 완료 기준 |
| 3 | `EXPERIENCE-DESIGN.md` | v0.2 이후 채택된 규칙: 화공 재설계, 연환·역병, 사건 기반 회복, 결정 카드, 조작, 재플레이. §8은 밸런스 값 |
| 4 | `SCENARIO-RED-CLIFFS-208.md`와 `data/scenarios/red_cliffs_208_realtime.json` | 첫 시나리오의 편성, 지휘관, 난이도 |
| 5 | `DATA-CROSSCHECK.md` §6 | 본편 데모 코드가 실제로 어떻게 계산하는지. 수치의 정본은 본편 `data/`다 |
| 6 | `docs/ui/UI-FLEET-VISUALS.md` | 이미 `main`에 병합된 표현 계층의 구조와 연결 지점 |
| 7 | `UPSTREAM-ISSUES.md` | 본편과 의도적으로 다르게 정한 것(B1~B16) |

## 2. 저장소 현재 상태 (`main`)

- **POC 전투:** `scripts/FleetBattle3D.gd`(약 1,840줄). 시뮬레이션, 표현, HUD, 입력이 한 파일에 섞여 있다.
- **표현 계층 (UI 세션, 병합 완료):** `hud/ui_kit/`, `view/fleet_render/`, `input/touch/`.
  - 전투 상태는 `view/fleet_render/battle_source.gd` 어댑터 하나로만 읽는다.
  - `FleetBattle3D.gd`에는 연결용 12줄(`battle_event` 신호, `presentation.gd` 생성)이 있다.
- **테스트:** `tests/smoke.gd`, `tests/touch_input.gd`, `tests/ui_flow.gd`, `tests/audit_*.gd`, 캡처 2종. 모두 `tests/lib/check.gd`로 실패 시 종료 코드 1이다.
- **시나리오 도구:** `tools/scenario/make_red_cliffs_208.py`(데이터 생성), `sim_red_cliffs_208.py`(간이 밸런스 시뮬레이션).
- **같은 폴더를 여러 세션이 쓴다.** 구현은 `git worktree`와 새 브랜치에서 하고, 병합과 푸시는 사용자가 요청할 때만 한다.

## 3. M1에서 조심할 것

- **규칙을 바꾸지 않는다.** 현행 POC 규칙 그대로 구조만 나눈다. 완료 기준은 화면 동일성이 아니라 **자동 해결 통계의 동등성**이다(§9.2).
- **결정론의 최대 적은 연출 난수다.** `_draw_fx`의 사격선 연출이 규칙과 같은 전역 난수열을 쓴다. 이것부터 분리한다(§9.1의 3단계).
- **표현 계층이 이미 있다.**
  - M1의 `view/`, `hud/` 새 파일은 `hud/ui_kit/`, `view/fleet_render/`와 이름이 겹치지 않게 한다.
  - 예정 이름: `view/battle_view_3d.gd`, `view/camera_rig.gd`, `view/fx_layer.gd`, `hud/battle_hud.gd`, `hud/fleet_labels.gd`, `hud/radar.gd`.
  - M1이 끝나면 POC HUD와 UI 세션의 HUD 가운데 어느 쪽을 남길지 정해야 한다(아래 §6).
- **`battle_source.gd`가 투영의 첫 사용자다.** 투영을 정하면 이 어댑터만 고쳐 연결한다.

## 4. 투영(BattleProjection) 초안 v0

컨셉 기준의 필드 목록이다. 이름과 형식은 M1 구현에서 정한다. M1 시점에는 POC 규칙의 값으로 채우고, 나머지는 단계마다 채운다.

**공통**

| 필드 | 뜻 | 채워지는 단계 |
|---|---|---|
| `tick`, `clock_s`, `speed_state` | 틱, 게임 시계, 속도 상태(정지 / ×0.2 / ×1 / ×2 / 자동 ×4) | M1 |
| `phase` | 화면용 국면(대치·접적·포화·교전·강습·결착) | M3 |
| `outcome` | 진행 중 / 승패와 사유 / 승리 등급 | M1 (POC 승패) → M4 |
| `army_morale_bp[side]`, `army_morale_crisis[side]` | 군 사기와 붕괴 위기(4500 미만) 여부 | M4 |
| `pending_decisions[]` | 열린 결정 분기: 종류, 대사 키, 선택지, 추천, 남은 시간 | M7 |
| `chain_op` | 화공 상태: 서신, 투항 중, 의심(0~100), 기류 창 시작·끝, 남은 폭발정, 번짐 횟수 | M9 |
| `events[]` | 이번 틱의 사건: 사격, 명중, 이탈, 국면 전환, 퇴각, 특성 발현, 일제사격 | M1 (POC 사건) → 단계마다 |

**전대 (보는 진영 기준)**

| 필드 | 아군 | 적 (탐지된 것만) |
|---|---|---|
| `id`, `side`, `faction`, `name`, `commander_id` | 있음 | 있음 |
| `pos`, `heading` | 정확 | 확인 접촉: 정확 / 추정 접촉: 마지막 위치와 오차 반경, 신뢰도 |
| `contact_state` | — | 확인 / 추정 / 상실 |
| `counts[ship_type][damage_stage]` | 정확 | 관측 구간만(예: "경미한 손상") |
| `morale_bp`, `morale_band` | 정확 | 구간만(안정 / 동요 / 퇴각) |
| `formation`, `formation_switch_left_s` | 있음 | 진형 이름만 |
| `stance`, `control` (직접·위임) | 있음 | — |
| `ammo`, `energy`, `heat` | 있음 | — |
| `weapon_cd[category]` | 있음 | — |
| `target_id`, `move_to`, `waypoints` | 있음 | — |
| `flagship`, `alert` (가장 급한 경고 하나) | 있음 | 기함 여부만 |

- 미탐지 적은 어디에도 넣지 않는다.
- AI도 같은 투영을 입력으로 받는다(치팅 금지).

**지금 `battle_source.gd`가 쓰는 필드와의 대응**
- `ships`, `max_ships`는 `counts`의 합으로 만든다.
- `defense`, `charge_t`, `missile_cd`, `fighter_cd`, `lv`는 POC 전용이라 단계마다 사라진다. 방어진형 삭제, 레벨 삭제, CP 폐지가 이유다.
- `speech`는 사건으로 옮긴다.

## 5. 단계별 구현 메모 (설계 결과 반영)

| 단계 | 설계에서 바뀐 점 (v0.2 이후) | 출처 |
|---|---|---|
| M2 | 시나리오 데이터는 `data/scenarios/red_cliffs_208_realtime.json`. 난이도 적용 규칙은 `difficulty_policy`에 있다. 조조 전대에 투입 시각을 추가한다(선봉 0, 주력 180초, 후군 360초) | 시나리오, 경험 §8 |
| M3 | 피해 √(플랫폼 수)(Q45), 60초 주기 일제사격(Q46), 열 냉각 30 + 척 수×2(Q49). 전투 길이는 사기 수치가 아니라 **투입 시차와 거리대 대기**로 맞춘다 | 결정, 경험 §8 |
| M4 | 군 사기는 연합 하나, 퇴각 전대는 현재 사기(Q47). 위기 구간 4500, 사건 기반 회복(+300), 유비 결집 1회. 시드가 기류 창, 역병, 파도 순서를 정한다 | 경험 §4·§9 |
| M5 | 연환 보너스(밀집 시 사기 감소 ×0.8)와 역병(분산 북방군 10초마다 −40bp) | 경험 §3 |
| M6 | **진영 공유 탐지(Q46)를 켜면 간이 시뮬레이션에서 승률이 뒤집혔다.** 탐지 점수를 따로 맞춰야 한다 | 경험 §8 |
| M7 | 결정 카드(입문 정지, 표준 ×0.2, 상급 ×1, 응답 없으면 추천안), 조조 성향 3종 | 경험 §5·§9 |
| M8 | 보급 규칙 확장(Q48) | 결정 |
| M9 | 화공 재설계(위장 항복, 의심 게이지, 거리별 위력, 번짐 2회, 폭발정 소모, 기류 창), what-if 카드 1차 3장 | 경험 §2·§9 |
| M10 | 메달판, 도전 과제 10개, "다음에 해볼 것", "당신의 결정", 사관 서술, 정보 4층, 전대 띠 | 경험 §6·§9 |
| M11 | 선택 감속과 유휴 5초 해제(Q55), 자동 ×4와 건너뛰기(Q52), 백그라운드 저장(Q53), 되돌리기, 길게 눌러 확정 | 결정, 경험 §6 |

## 6. 구현 세션이 사용자와 정해야 할 것

- **HUD 이중 구조:** POC HUD(`FleetBattle3D.gd` 안)와 UI 세션 HUD(`hud/ui_kit/`)가 함께 있다. M1의 8단계(투영만 읽는 화면)에서 POC HUD를 걷어 내고 UI 세션 HUD로 일원화할지 정한다. 권고는 일원화다.
- **표시 척 수 배율:** UI 세션은 전대당 50~75척을 표시한다. 규칙의 척 수와 고정 배율로 이을지 정한다(`REVIEW-UI-v2.md` C-1).
- **밸런스 2차 결과:** `EXPERIENCE-DESIGN.md` §8이 갱신되면 M3·M4 목표값으로 쓴다.
