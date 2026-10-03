# 컨셉·시나리오 세션 인수 메모

새 세션이 이 작업을 이어받을 때 가장 먼저 읽는 문서다. 갱신: 2026-10-03 (1차 세션 종료 시점).
맨 아래 "새 세션 첫 프롬프트"를 그대로 붙여 넣으면 된다.

## 이 세션의 역할

- 컨셉·시나리오 개선과 리뷰만 한다. Godot 코드(`scripts/`, `hud/`, `view/`, `input/`, `tests/`)는 고치지 않는다.
- 수정 범위는 `docs/battle-core/`, `data/scenarios/`, `tools/scenario/`다.
- 판단은 Claude가 하고, 특이점이 없으면 확인 없이 진행한다. 사용자 결정(`BATTLE_DECISIONS.md`)을 뒤집어야 할 때만 인터뷰(AskUserQuestion)로 묻는다.
- 서브 에이전트를 쓸 때는 Claude가 오케스트레이터가 된다. 에이전트 의견을 채택·조정·후속·보류로 판정하고, 충돌은 조율해 문서에 반영한다.
- 결정은 `BATTLE_DECISIONS.md`에 Q번호로 남기고, 커밋은 `main`에 직접 하고 푸시한다(사용자가 그렇게 진행해 왔다).

## 다른 세션과의 조율

- 같은 작업 폴더 `C:\WorkSpace\SpaceBattleOfThreeKingdoms`를 다른 세션도 쓴다. 시작할 때 `ListAgents`로 확인한다.
- **UI 세션:** "게임 UI 상품화 수준 개선-2"가 UI·함대 표현을 맡는다.
  - 인수 메모는 `docs/ui/NEXT-SESSION-PROMPT.md`, 구조는 `docs/ui/UI-FLEET-VISUALS.md`다.
  - 구현은 worktree와 기능 브랜치에서 하고 `main`에 병합한다. 최근 병합은 `09f5969`(결정 카드, Q52·Q53·Q55, 리뷰 반영)다.
  - UI 의견은 그 세션에 `SendMessage`로 보낸다.
- 이 세션은 `main`에서 문서만 커밋한다. 브랜치를 전환하지 않는다. 다른 세션의 미추적 파일은 건드리지 않는다.
- **M1 구조 분리(코어 구현)는 아직 맡은 세션이 없다.** 구현 세션은 `IMPLEMENTATION-HANDOFF.md`부터 읽는다.

## 문서 지도 (읽는 순서)

1. `BATTLE_DECISIONS.md`: 사용자 결정 Q1~Q55와 Q54 보충. 세션 결정은 본편 정본보다 우선한다.
2. `PROPOSAL-realtime-battle-core.md` v0.3: 전체 규칙과 M0~M12 단계. 경험 설계, Q45~Q55, 탐지 재조정, 화공 남은 수치가 본문에 들어 있다.
3. `EXPERIENCE-DESIGN.md`: 편의성·재미·재플레이 설계의 근거와 판정 기록, 밸런스(세트 RX, 탐지 재조정).
4. `SCENARIO-RED-CLIFFS-208.md`와 `data/scenarios/red_cliffs_208_realtime.json`: 정사 기반 편성, 지휘관, 난이도 4단계, 실시간 규칙(`realtime_rules`).
   - 데이터는 `tools/scenario/make_red_cliffs_208.py`로 생성한다. JSON을 직접 고치지 말고 생성기를 고친다.
5. `NARRATIVE-RED-CLIFFS.md`: 결정 카드 대사, 안내 지휘, 컷인, 사관 서술 57종, what-if 카드, 후일담.
6. `DATA-CROSSCHECK.md`: 본편 `C:\WorkSpace\Seonghanji`의 data와 데모 코드 대조. §6이 코드 검증 정정이다.
7. 넘기는 문서
   - `IMPLEMENTATION-HANDOFF.md`: 구현 세션용
   - `UPSTREAM-ISSUES.md`: 본편용(불일치 8건, 의도적 차이 17건, 되돌려 줄 것 4건)
   - `REVIEW-UI-v2.md`: UI 세션용
8. 오래된 기록: `REVIEW-realtime-battle-core.md`, `BATTLE-CORE-HANDOFF.md`(v0.1 시점).

**시뮬레이션 도구**
- `tools/scenario/sim_red_cliffs_208.py`: 초기 간이 모델
- `tools/scenario/balance_rx/`: 세트 RX
- `tools/scenario/detect_fog/`: 탐지 재조정
- 모두 **AI 대 AI 근사 모델**이다. 기록용이며 README의 재현 주의를 읽는다.

## 1차 세션에서 한 일 (2026-10-03)

- **결정:** 사용자 인터뷰로 Q28~Q55를 받았다(돌격 복구, 즉시 결산, bp, 고속정, 방향 효과, 진형 %, 손상 카운터, 좌표, 수치 표현, 틱, 피해 √, 주기 사격, 군 사기, 보급, 열, 난이도, 모바일 시간, 파도, 유휴 해제).
- **대조와 정리:** 본편 data·코드 대조, M0 정리(레거시 삭제, 테스트, 런처), 제안서 v0.2 → v0.3.
- **시나리오:** 적벽 시나리오(정사 편성, 지휘관, 난이도 4단계), 내러티브 v1.
- **멀티 에이전트 검토:** 편의성·재미·재플레이·밸런스 → `EXPERIENCE-DESIGN.md`. 밸런스는 세트 RX 채택, 탐지 재조정은 추정 신뢰도 7500.
- **리뷰와 넘김:** UI 리뷰, 본편 차이 목록, 구현 인수 문서.

## 남은 일 (컨셉 세션이 할 수 있는 것)

| 우선 | 일 | 메모 |
|---|---|---|
| 1 | **구현 세션이 생기면 리뷰** | 구현 결과가 v0.3 규칙, 결정, 투영 초안과 맞는지 본다. 특히 M1 완료 기준(통계 동등성), 결정론, 정보 경계 |
| 2 | **UI-2 세션 결과 리뷰** | 결정 카드, 의심 게이지, 기류 창 표시가 `NARRATIVE-RED-CLIFFS.md`·`EXPERIENCE-DESIGN.md`와 맞는지 본다 |
| 3 | **두 번째 시나리오 기획** (선택) | 적벽 다음 후보: 관도(200), 이릉(222), 합비(215) 등. 같은 틀로 정사 근거, 편성, 난이도, 5막 구조를 만든다. 시작 전에 사용자에게 어느 전투인지 묻는다 |
| 4 | **본편 감수 결과 반영** | `UPSTREAM-ISSUES.md`에 대한 본편 쪽 답(통솔 값, 역사 감수 등)이 오면 시나리오와 내러티브를 고친다 |
| 5 | **M4 이후 밸런스** | 실제 코어와 사람의 플레이 테스트 결과로 세트 RX, 탐지, 화공 수치를 다시 맞춘다 |

**아직 열린 설계 문제** (구현이 있어야 확정)
- 표준의 조조가 확인 등급을 거의 받지 못한다(탐지 재조정의 한계, M6).
- 화공 차단 3종, 의심 가감 요인, 주유 결집은 제안값이다(M9).
- 표준 화공 시도 승률은 기준선에 따라 22~32%로 흔들린다(M4).

## 새 세션 첫 프롬프트

```
성한지(C:\WorkSpace\SpaceBattleOfThreeKingdoms) 실시간 전투의 컨셉·시나리오 설계와 리뷰를 이어서 한다.
먼저 docs/battle-core/SESSION-HANDOFF.md를 읽고, 문서 지도 순서대로 BATTLE_DECISIONS.md와 PROPOSAL-realtime-battle-core.md(v0.3)를 확인해라.
이 세션은 Godot 코드를 고치지 않고 docs/battle-core/, data/scenarios/, tools/scenario/만 수정한다.
같은 폴더를 다른 세션도 쓰니 ListAgents로 확인하고, 브랜치는 바꾸지 말고 main에서 문서만 커밋·푸시해라.
판단은 네가 하고 특이점이 없으면 확인 없이 진행하되, 사용자 결정을 바꿔야 할 때만 인터뷰로 물어라.
시작하면 현재 상태를 짧게 요약하고, 인수 메모의 "남은 일" 가운데 지금 할 수 있는 것을 제안해라.
```
