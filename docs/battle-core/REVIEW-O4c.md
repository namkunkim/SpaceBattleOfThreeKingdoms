# REVIEW-O4c — O4b 리뷰 조건 처리 (구현 8d01196, main 6806221)

## 범위
FleetBattle3D.org_blocked, command_deck begin_battle/restart, Organization.repair·auto_fill(only), org_screen.open_org·_repair_text·tier_text. 코드는 고치지 않았다.

## 실행한 테스트 (헤드리스, Godot 4.7.2, --import 후)
organization_rules OK, organization_ui PASS, ui_flow PASS, world_link PASS, battle_flow PASS, smoke PASS, selection_groups PASS. 재시도 없이 전부 한 번에 통과.

## 확인한 것
1. F-1: 전투 시작 경로는 전부 `_start`(org_blocked 첫 줄)를 지난다. 오버레이 "처음부터"·"다시 출격"은 `_restart → init_game → _start`, deck은 begin_battle/restart가 한 번 더 검사한다. 천하 지도 "자동 해결"은 auto_resolver(전투 씬 미사용)라 org_blocked와 무관하고 멈추지 않는다. 천하에서 들어온 전투는 브리핑을 거쳐 같은 deck 경로를 쓴다.
2. repair: 입력은 org와 profile/scn뿐이라 결정론적이다. 손권·조조는 old를 복사하지 않고 항상 전부 auto_fill(Q76·Q81 맞음). auto_fill의 only는 기본값 []에서 기존 필터·used 계산과 동일해 기존 호출 결과가 같다(organization_rules 통과). 보존 함대의 장수는 used에 넣어 다시 채운 함대와 중복되지 않으며, 마지막에 전체 validate를 다시 돌려 중복·기함 문제가 남으면 세 세력 전부 자동으로 대체한다.
3. b.org 교체 + init_game: org가 유효해진 뒤 한 번 더 init_game을 부르므로 org_errors가 비고 상태가 "brief"로 돌아간다. 비천하 전투는 시드가 randi라 원래도 재시작마다 달라지고, 천하 전투는 brief.seed 고정이라 재생·지문 흐름은 유지된다.
4. F-4: salvo.gd:137은 s /= 1+penalty라 시간은 1/(1-0.08t)다. 식·반올림(+9/+19/+32/+47)이 코드와 일치한다(사용자 결정 반영, 1단계 +9는 지적 아님).

## 발견 사항
| 심각도 | file:line | 내용 | 권고 |
|---|---|---|---|
| 낮음 | core/battle/organization.gd:286-325, tests/organization_ui.gd:200-217 | 테스트는 "함대 빠짐" 한 경우만 본다. 대체 경로(전부 자동), 기함 함대 깨짐, 보존-재채움 간 장수 중복, 결정론은 테스트가 없다(코드 읽기로만 확인). | organization_rules에 repair 케이스 추가: 기함 깨짐·중복 장수·세력 단위 사유·같은 입력 두 번 결과 동일. |
| 낮음 | hud/ui_kit/org_screen.gd:287-302 | 대체 경로(전부 자동)로 떨어져도 문구는 "다시 채운 함대: 전 함대 · 조조군 N개 자동 편성"이고 "나머지 유지" 문구만 빠진다. 보존이 취소된 사실을 명시하지 않아 사용자가 유지됐다고 오해할 수 있다. | repair 결과에 `fallback` 플래그를 두고 "고칠 수 없어 전부 자동 편성했습니다"를 표시. |
| 낮음 | scripts/FleetBattle3D.gd:241-246 | presentation/hud가 없으면(헤드리스) org_blocked는 true만 돌려주고 화면 없이 조용히 전투를 막는다. 현재 호출자(baseline_poc 등)는 org가 비어 영향 없음. | 필요시 push_warning 한 줄. |
| 낮음 | scripts/FleetBattle3D.gd:248-252 + org_screen.gd:149 | 종료 오버레이 "다시 출격"에서 막히면 `_start`가 end_ov 숨김 전에 반환한다. 편성 화면이 위에 열리지만 end_ov가 init_game에서 숨겨지는지는 화면으로 확인하지 못했다(헤드리스 한계). | 로컬에서 거부 편성 + 결과 화면 → 다시 출격을 한 번 눈으로 확인. |
| 사소 | hud/ui_kit/org_screen.gd:329 | 주석이 "+8/+19/+32/+47%"인데 실제 표시는 +9다. | 주석을 +9로. |

## 판정
수용. F-1·F-3·F-4 모두 기준을 만족하고 7개 테스트가 통과했다. 위 항목은 후속(테스트 보강, 문구)이며 병합을 막지 않는다.
