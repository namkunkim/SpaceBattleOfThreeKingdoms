# 인계: 적 AI 원거리 유지·강습 근접·집중 사격 (2026-10-18)

## 이어서 할 프롬프트

```
feature/enemy-ai-standoff 작업을 이어서 해줘.
worktree: C:\WorkSpace\SpaceBattleOfThreeKingdoms\.claude\worktrees\enemy-ai-standoff (main e921d7d에서 분기, 아직 커밋 없음)
인계 문서: docs/battle-core/HANDOFF-ENEMY-AI-STANDOFF.md

1. 전체 헤드리스 테스트 결과를 확인한다($TEMP/eai_suite.txt, 로그 $TEMP/eai_<test>.log).
   boundary rc=1은 기존 실패(2026-10 기준)라 main에서도 실패하는지 확인만 한다. 그 밖의 실패는 원인을 고친다.
2. 레벨별 효과를 잰다: tests/autoresolve.gd --difficulty 입문/표준/상급/극한으로 standoff on/off(data/profiles/ai_m7.json ai.standoff.enabled) 승률·손실 비교.
3. 커밋 3파일 + 이 문서만(--import가 바꾼 *.import 파일은 커밋하지 않는다). feature/enemy-ai-standoff를 푸시한다.
   Q108 충돌은 해소됐다(Q110: 적 AI도 물러날 수 있다). 테스트가 통과하면 main 병합·푸시까지 한다.
```

## 사용자 요구
- 각 함대는 원거리 무기(레이저포·레일건·양자어뢰·미사일·전투기)로 교전할 때 적과 거리를 두고 공격한다.
- 전투기·강습 특기를 쓰는 동안만 적 함대와 근거리에서 교전한다.
- 적 AI 레벨을 높인다(집중 사격 등). 먼저 HTML PoC에서 해 봤고, 이번 작업은 Godot 적용이다.

## 바꾼 것 (worktree, 미커밋)
- `docs/battle-core/BATTLE_DECISIONS.md`: Q110 추가, Q108 대체 표시.
- `core/battle/ai/commander_ai.gd`
  - `_std()`: `ai.standoff.enabled`.
  - `_close(sim, f)`: 돌격 중(`f.charge > 0`)이거나 강습 특기 효과(`skills.mul(f, "assault_bp") > BP`) 중이면 true.
  - `_desired`: 근접 중이고 강습모함이 있으면 강습 거리(100). 원거리 유지 규칙이면 거리 일정이 강습 단계에 와도 교전 거리(170)에 멈추고 `_due = true`.
  - `_think_fleet`: 목표 거리보다 가까우면 근접 중이 아닌 한 쏘면서 물러난다. 적 AI도 해당한다.
  - `_charge`: `_due`이면 방침과 무관하게 돌격할 수 있다. 일정상 강습 단계 = 특기 사용 시점.
  - `_focus_of`: 진영 집중 표적은 확인 접촉 중 전력 구간이 최저인 것이다. 같으면 아군과의 거리 합이 작은 쪽, 그다음 ID가 작은 쪽. `_pick`에서 사고 깊이가 `focus.min_depth`(3, 상급·극한) 이상이면 점수에 `focus.mul`(0.6)을 곱한다.
- `data/profiles/ai_m7.json`: `standoff`, `focus` 항목 추가(제안값).
- `tests/commander_ai.gd`: 새 규칙에 맞게 3곳 수정, 집중 표적 검사 1개 추가. 이 테스트와 hold_distance는 통과했다.

## 결정
- **Q110(사용자 2026-10-18): 적 AI는 물러날 수 있다.** Q108의 "물러나지 않기"를 대체했고, `BATTLE_DECISIONS.md`에 반영했다. Q68 일정 변경(강습모함은 돌격해야 100까지 붙는다)도 Q110에 적었다.

## 남은 일·알려진 한계
- "전투기 특기"는 Godot에 별도 특기가 없다. 전투기는 원거리 범주로 두었고, 근접 조건은 돌격과 강습 특기(만인지적 assault_bp)뿐이다.
- 적극 방침 함대는 130 거리에서 한 번 물러났다가 같은 생각에서 돌격한다. 이동 명령이 돌격 판단보다 먼저라서 생기는 일이다. 어색하면 돌격할 함대는 물러나지 않게 순서를 바꾼다.
- PoC에서 해 본 측면 기동과 손실 시 후퇴는 Godot에 넣지 않았다. 손실 시 후퇴는 이제 Q110으로 허용되므로 다음 후보다(성향 퇴각 규칙 `disposition_retreat_ship_share`와 겹치지 않게).
- HTML PoC 변경(`docs/poc/fleet-motion-ref/index.html`: 적 AI 레벨 0~3, 강습 특기 A키)은 원래 폴더 main 작업 트리에 미커밋으로 있다. 다른 세션의 미커밋 수정과 섞여 있다.
