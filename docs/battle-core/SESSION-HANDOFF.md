# 컨셉·시나리오 세션 인수 메모

새 세션이 이 작업을 이어받을 때 가장 먼저 읽는 문서다. 갱신: 2026-10-03.

## 이 세션의 역할

- 컨셉·시나리오 개선과 리뷰만 한다. Godot 코드는 고치지 않는다.
- 수정 범위는 `docs/`(주로 `docs/battle-core/`), `data/scenarios/`, `tools/scenario/`다.
- 판단은 Claude가 하고, 특이점이 없으면 확인 없이 진행한다. 사용자 결정을 뒤집어야 할 때만 인터뷰(AskUserQuestion)로 묻는다.
- 서브 에이전트를 쓸 때는 Claude가 오케스트레이터가 된다. 에이전트 의견을 채택하거나 조율해 문서에 반영한다.

## 다른 세션과의 조율

- 같은 작업 폴더 `C:\WorkSpace\SpaceBattleOfThreeKingdoms`를 다른 세션도 쓴다.
- "게임 UI 상품화 수준 개선" 세션: UI 목업과 앞으로의 Godot UI 구현 담당.
  - 구현은 `git worktree`와 `feature/ui-fleet-visuals` 브랜치에서 한다.
  - 새 파일은 `hud/ui_kit/`, `view/fleet_render/`에 둔다.
  - 투영(projection) 데이터는 어댑터 하나로만 받는다.
- 이 세션은 `main`에서 문서만 커밋한다. 브랜치 전환은 하지 않는다. 다른 세션의 미추적 파일(`.claude/`, `docs/ui/mockup-battle-v2.html` 등)은 건드리지 않는다.
- M1 구조 분리(구현)는 아직 맡은 세션이 없다.

## 문서 지도 (읽는 순서)

1. `BATTLE_DECISIONS.md`: 사용자 결정 Q1~Q55. 세션 결정은 본편 정본보다 우선한다.
2. `PROPOSAL-realtime-battle-core.md` v0.3: 규칙, M0~M12 단계. 경험 설계와 Q45~Q55가 본문에 녹아 있다.
3. `EXPERIENCE-DESIGN.md`: 경험 설계의 근거, 판정 기록, 밸런스(세트 RX) 수치.
4. `SCENARIO-RED-CLIFFS-208.md`와 `data/scenarios/red_cliffs_208_realtime.json`: 정사 기반 편성, 지휘관, 난이도 4단계.
5. `DATA-CROSSCHECK.md`: 본편 `C:\WorkSpace\Seonghanji`의 data와 데모 코드를 대조한 기록. §6이 코드 검증 정정이다.
6. `IMPLEMENTATION-HANDOFF.md`, `UPSTREAM-ISSUES.md`, `REVIEW-UI-v2.md`: 구현 세션, 본편, UI 세션에 넘기는 문서.
7. `REVIEW-realtime-battle-core.md`, `BATTLE-CORE-HANDOFF.md`: v0.1 시점 기록이라 오래됐다.

## 완료한 일 (2026-10-03 오후)

**멀티 에이전트 검토:** 서브 에이전트 넷(편의성, 재미, 재플레이, 밸런스)의 의견을 판정·조율해 `EXPERIENCE-DESIGN.md`에 통합했다.
- 밸런스는 2차까지 돌려 세트 RX를 채택했다(§8). 시나리오 데이터에 투입 시차, 배치, `realtime_rules`를 반영했다.
- 사용자 결정 Q55(선택 감속의 유휴 5초 해제)를 받았다.

**새로 만든 문서**
- `EXPERIENCE-DESIGN.md`: 5막 구조, 화공 재설계, 연환·역병, 사건 기반 회복, 결정 카드, 조작, 온보딩, 재플레이, 밸런스
- `REVIEW-UI-v2.md`: UI 세션 결과물 리뷰. UI 작업은 "게임 UI 상품화 수준 개선-2" 세션이 넘겨받았다
- `UPSTREAM-ISSUES.md`: 본편에 보낼 불일치 8건, 의도적 차이 16건, 되돌려 줄 것 3건
- `IMPLEMENTATION-HANDOFF.md`: 구현 세션이 읽을 문서. 투영 초안 v0 포함

## 남은 일

1. ~~제안서 v0.3~~ **완료** (2026-10-03).
2. **탐지 재조정 설계(M6 선행):** 진영 공유 탐지를 켜면 승률이 뒤집힌다. 1안은 추정 명중 ×0.75, 2안은 정찰 센서를 척 수와 분리. 시뮬레이션으로 고른다.
3. **화공 남은 규칙의 수치:** 차단 3종, 의심 가감 요인, 주유 결집. 조조 밀집 전대끼리 대형 유지 규칙.
4. **시나리오 이야기 다듬기:** 결정 카드 문구(참모 대사), 사관 서술 템플릿 30~40종 초안, what-if 카드 3장의 세부 규칙.
5. **M4 이후:** 사람의 플레이 테스트 결과를 받아 밸런스를 다시 맞춘다.

새 세션은 `SESSION-HANDOFF.md`를 읽고 "남은 일" 1번부터 진행하면 된다.
