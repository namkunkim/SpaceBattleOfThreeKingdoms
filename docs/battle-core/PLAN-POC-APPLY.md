# 함대 기동 PoC 본 게임 적용 계획 (2026-10-18)

PoC 정본: `origin/feature/fleet-motion-poc-align`의 `docs/poc/fleet-motion-ref/index.html`, 동작은 `VIDEO-LOGH7-FLEET-MOTION.md` §7·§9.

## 인터뷰 결정 (사용자, 2026-10-18)
- 코어 이동·탐지 규칙 변경을 **승인**한다. 충돌하는 기존 Q(Q60 그룹 이동 일부, Q73 일부, M6 탐지 일부)는 **PoC가 우선**이며 구현할 때 새 Q번호로 `BATTLE_DECISIONS.md`에 대체 기록한다.
- 가져올 범위: 제자리 반전+접적 이동, 묶음·묶음 진형, 가시 범위·정찰 레이더, 적 AI·이동 늘림 제거. 확대·축소, 마우스·터치는 이미 있어 PoC 방식과의 차이만 맞춘다.
- 수치: **코어 수치 유지**(`combat_m3.json` 선회 9°/초, 평행 60% 등). 가시 250/레이더 450은 전장 스케일로 환산한 값을 데이터에 둔다.
- 유지(변경 금지): 화면 구성·메뉴, 함선 이미지, 아군·적 함대·함선 수 편성. PoC 편성(100척 12함대)은 가져오지 않는다.

## 구현 단위 (PR 하나씩, 순서대로)
| # | 항목 | 코어/표현 | 핵심 위치 | 검증 |
|---|---|---|---|---|
| A | 이동 늘림(STRETCH) 제거 | 표현 | `fleet_renderer.gd` `_follow` | `fleet_follow` 갱신 |
| B | 접적 평행 이동(±45° 100%, 옆뒤 60%), 도착 후 진형을 조준 적 쪽으로 정렬, 90° 초과 제자리 반전(1초, 진형 점대칭) | 코어 | `battle_sim.gd` `_substep`·`_turn`, `fleet_state.gd`, `combat_m3.json` movement | 신규 `tests/flip_rules.gd`, `core_rules`, 1000시드 재측정 |
| C | 가시 범위(바깥 함선 볼록 껍질+250), 정찰함 레이더 450, 보이는 적에게만 사격 | 코어 | `detection.gd` 접촉 판정에 가시 영역 추가(기존 M6 점수식과의 관계는 B 이후 결정) | `detection_rules`, `fog_ui` |
| D | 적 AI: 자기 가시 범위 안까지 접근, 물러나지 않음 | 코어 | `core/battle/ai/` | `commander_ai` |
| E | 묶음(중첩)·묶음 진형·전장 초과 시 여러 줄 접기 | 코어+입력 | `selection_set.gd`, `battle_commands.gd`, `formation_tab.gd`(기존 메뉴 안에서) | 신규 `tests/bundle_rules.gd`, `selection_groups` |
| F | 마우스·터치·줌 차이 보정(PoC §7.3 대조) | 입력 | `mouse_controller.gd`, `touch_controller.gd`, `camera_rig.gd` | `mouse_input` |
| G | 문서(§9 현황, SESSION-HANDOFF), PC 화면 확인, 다른 모델 리뷰 | — | — | 캡처 |

의존: A 독립. B→C→D 순. E는 B 뒤. 각 항목은 새 Q 기록, 헤드리스 테스트, 1000시드 재측정(코어 변경분) 후 병합.
첫 질문 거리: C에서 기존 M6 점수식 탐지(확인/추정/상실)와 PoC 가시 영역을 **병용**할지 **대체**할지.
